// Cloud AI step. The app asks for one of a few fixed tasks (never a free
// prompt, so this is not an open proxy). Gemini runs on Vertex AI paid by
// the project's credit; if Vertex is not configured or fails, the Gemini
// Developer API key is tried. Every answer reports which path served it.
import { corsHeaders, fetchWithTimeout, json } from "../_shared/http.ts";
import { vertexAccessToken } from "../_shared/google_auth.ts";

const MODELS = ["gemini-3.8-flash", "gemini-3.7-flash", "gemini-3.5-flash"];
// The free Developer key often answers 503 or hangs, and every caller treats
// Gemini as optional. The app waits 3 s, so the function gives up at 2.2 s
// to leave room for the network and still deliver an answer that arrives.
const DEADLINE_MS = 2200;

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
        generationConfig: { responseMimeType: "application/json", temperature: 0 },
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
              'Return JSON only: {"key": string|null, "confidence": number}. ' +
              "key must be one of the known item keys or null if none fits. Never invent a key.",
          }],
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0 },
      };
    case "explain":
      return {
        contents: [{
          role: "user",
          parts: [{
            text:
              "Explain this verdict to a traveler in one short, plain English sentence " +
              "(max 22 words, no exclamation marks, no emoji). Use only the facts given. " +
              `Facts: ${JSON.stringify(input.facts ?? {})}`,
          }],
        }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 80 },
      };
  }
}

async function callVertex(model: string, body: unknown, ms: number) {
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
    },
    ms,
  );
}

async function callDeveloperApi(model: string, body: unknown, ms: number) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("developer api not configured");
  return fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify(body),
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
    const errors: string[] = [];
    for (const [path, call] of [["vertex", callVertex], ["developer", callDeveloperApi]] as const) {
      for (const model of MODELS) {
        const left = DEADLINE_MS - (Date.now() - started);
        if (left < 300) break;
        try {
          const res = await call(model, body, left);
          // The fetch timer stops once headers arrive; bound the body too.
          const data = await Promise.race([
            res.json(),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error("deadline")), Math.max(0, DEADLINE_MS - (Date.now() - started)))
            ),
          ]) as Record<string, any>;
          if (!res.ok) {
            errors.push(`${path}/${model}: ${res.status}`);
            continue;
          }
          const text = data?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("") ?? "";
          return json({ text, model, path, ms: Date.now() - started });
        } catch (e) {
          errors.push(`${path}/${model}: ${e instanceof Error ? e.message : String(e)}`);
          if (String(e).includes("not configured")) break;
        }
      }
    }
    return json({ error: "all models failed", details: errors }, 502);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
