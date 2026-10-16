// Cloud AI step. The app asks for one of a few fixed tasks (never a free
// prompt, so this is not an open proxy). Gemini runs on Vertex AI paid by
// the project's credit; if Vertex is not configured or fails, the Gemini
// Developer API key is tried. Every answer reports which path served it.
import { corsHeaders, fetchWithTimeout, json } from "../_shared/http.ts";
import { vertexAccessToken } from "../_shared/google_auth.ts";

// Measured 15 Oct on the free Developer key: gemini-3.8-flash and
// 3.7-flash answer 503 "high demand", so they are not tried. 3.5-flash-lite
// and 3.5-flash answer in 1.0-1.6 s with thinking set to minimal; with
// default thinking, 3.5-flash spent 74 of 80 output tokens thinking and
// returned an empty sentence.
const MODELS = ["gemini-3.5-flash-lite", "gemini-3.5-flash", "gemini-3.1-flash-lite"];

// Short, fixed tasks: no long reasoning wanted, and thinking tokens count
// against the output limit.
const FAST = { thinkingConfig: { thinkingLevel: "minimal" } };
// The free Developer key often answers 503 or hangs, and every caller treats
// Gemini as optional. Each task gives up in time for its caller: the app
// waits 3 s for an explanation and 5 s for an item name.
const DEADLINES: Record<Task, number> = { explain: 2200, resolve_item: 9000, read_bill: 8000 };

type Task = "read_bill" | "resolve_item" | "explain";

function buildRequest(task: Task, input: Record<string, unknown>) {
  switch (task) {
    case "read_bill":
      return {
        contents: [{
          role: "user",
          parts: [
            {
              text:
                "Read this Thai restaurant bill. Return JSON only with numbers as printed: " +
                '{"items":[{"name":string,"qty":number,"amount":number}],"subtotal":number|null,' +
                '"discount":number|null,"serviceCharge":number|null,"serviceChargePercent":number|null,' +
                '"vat":number|null,"vatPercent":number|null,"vatIncluded":boolean|null,"total":number|null}. ' +
                "Use null for anything not printed. Do not calculate missing values.",
            },
            { inlineData: { mimeType: "image/jpeg", data: String(input.imageBase64 ?? "") } },
          ],
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0, ...FAST },
      };
    case "resolve_item":
      return {
        contents: [{
          role: "user",
          parts: [{
            text:
              "A Thai seller's sentence was transcribed by speech recognition and may be misheard. " +
              `Transcripts (best first): ${JSON.stringify(input.alternatives ?? [])}. ` +
              `Known items: ${JSON.stringify(input.items ?? [])}. ` +
              'Return JSON only: {"key": string|null, "confidence": number, ' +
              '"newItem": {"nameTh": string, "nameEn": string, "unit": "each"|"perKg"|"perPlate"|"perHour"|"perRide", ' +
              '"category": "food"|"drink"|"transport"|"service"|"goods"|"other"}|null}. ' +
              "key must be one of the known item keys or null if none fits. Never invent a key. " +
              "If no known item fits but the seller clearly names a product or service, set newItem: " +
              "nameTh copied exactly from a transcript (the product words only, without numbers, " +
              "price words or units such as บาท, กิโลละ, แก้วละ), nameEn its plain English name. " +
              "Otherwise newItem is null.",
          }],
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0, ...FAST },
      };
    case "explain":
      return {
        contents: [{
          role: "user",
          parts: [{
            text:
              "Explain this verdict to a traveler in one short, plain English sentence " +
              "(max 22 words, no exclamation marks, no emoji). Use only the facts given. " +
              "All amounts are Thai baht (THB); never use another currency sign. " +
              `Facts: ${JSON.stringify(input.facts ?? {})}`,
          }],
        }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 200, ...FAST },
      };
  }
}

async function callVertex(model: string, body: unknown, ms: number, signal?: AbortSignal) {
  const project = Deno.env.get("GCP_PROJECT_ID");
  const sa = Deno.env.get("GOOGLE_SA_JSON");
  if (!project || !sa) throw new Error("vertex not configured");
  const token = await vertexAccessToken(sa);
  return fetchWithTimeout(
    `https://aiplatform.googleapis.com/v1/projects/${project}/locations/global/publishers/google/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(body),
      signal,
    },
    ms,
  );
}

async function callDeveloperApi(model: string, body: unknown, ms: number, signal?: AbortSignal) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("developer api not configured");
  return fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify(body),
      signal,
    },
    ms,
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const started = Date.now();
  try {
    const { task, input } = await req.json();
    if (!["read_bill", "resolve_item", "explain"].includes(task)) {
      return json({ error: "unknown task" }, 400);
    }
    const body = buildRequest(task as Task, input ?? {});
    const deadline = DEADLINES[task as Task];
    const errors: string[] = [];
    // The free key's latency swings from 1 s to over 10 s per model, so the
    // models are asked at the same time and the first complete answer wins.
    let controllers: AbortController[] = [];
    const one = async (path: string, call: typeof callDeveloperApi, model: string) => {
      const left = deadline - (Date.now() - started);
      if (left < 300) throw new Error("deadline");
      const controller = new AbortController();
      controllers.push(controller);
      const res = await call(model, body, left, controller.signal);
      // The abort at the deadline or on another model's win also ends this
      // body read.
      const data = await res.json() as Record<string, any>;
      if (!res.ok) throw new Error(`${res.status}`);
      const candidate = data?.candidates?.[0];
      const text = candidate?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("").trim() ?? "";
      // A cut-off or empty answer is a failure, not a result.
      if (!text || candidate?.finishReason !== "STOP") {
        throw new Error(candidate?.finishReason ?? "no candidate");
      }
      return { text, model, path };
    };
    // Losing and late requests are aborted, so they stop using the free
    // key's quota and their body reads end.
    const stopAll = () => controllers.forEach((c) => c.abort());
    const deadlineTimer = setTimeout(stopAll, deadline);
    for (const [path, call] of [["vertex", callVertex], ["developer", callDeveloperApi]] as const) {
      controllers = [];
      try {
        const won = await Promise.any(MODELS.map((m) =>
          one(path, call, m).catch((e) => {
            errors.push(`${path}/${m}: ${e instanceof Error ? e.message : String(e)}`);
            throw e;
          })
        ));
        stopAll();
        clearTimeout(deadlineTimer);
        return json({ ...won, ms: Date.now() - started });
      } catch {
        // every model on this path failed; try the next path
      }
    }
    clearTimeout(deadlineTimer);
    return json({ error: "all models failed", details: errors }, 502);
  } catch (e) {
    console.error(e);
    return json({ error: "internal error" }, 500);
  }
});
