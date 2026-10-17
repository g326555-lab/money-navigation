// Cloud OCR for scripts the phone cannot read (Thai bills, menus, price
// tags): Cloud Vision DOCUMENT_TEXT_DETECTION. Returns each line with its
// four corners, so the app can straighten and rebuild rows exactly like
// on-device OCR. The photo is not stored.
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";
import { guard } from "../_shared/guard.ts";

const VISION_URL = "https://vision.googleapis.com/v1/images:annotate";
// Vision usually answers in 0.5-2 s, but 3 of 80 real receipt photos took
// over 6 s (15 Oct). The app waits 10 s and retries a server error once.
const TIMEOUT_MS = 9000;
const MAX_BASE64 = 6_000_000;

type Vertex = { x?: number; y?: number };
type Word = { symbols: { text: string; property?: { detectedBreak?: { type?: string } } }[]; boundingBox: { vertices: Vertex[] } };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const caller = await guard(req, "read-text");
  if ("reject" in caller) return caller.reject;
  const started = Date.now();
  try {
    const { imageBase64 } = await req.json();
    if (typeof imageBase64 !== "string" || !imageBase64 || imageBase64.length > MAX_BASE64) {
      return json({ error: "imageBase64 is required (jpeg, under about 4 MB)" }, 400);
    }
    const res = await fetchWithTimeout(VISION_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": requireSecret("GOOGLE_MAPS_API_KEY") },
      body: JSON.stringify({
        requests: [{ image: { content: imageBase64 }, features: [{ type: "DOCUMENT_TEXT_DETECTION" }] }],
      }),
    }, TIMEOUT_MS);
    const body = await res.json();
    if (!res.ok || body.responses?.[0]?.error) {
      return json({ error: body.error?.message ?? body.responses?.[0]?.error?.message ?? "vision error" }, 502);
    }
    // Lines: words joined until Vision marks a line break.
    const lines: { text: string; corners: [number, number][] }[] = [];
    for (const page of body.responses[0].fullTextAnnotation?.pages ?? []) {
      for (const block of page.blocks ?? []) {
        for (const para of block.paragraphs ?? []) {
          let text = "";
          let words: Word[] = [];
          const flush = () => {
            if (!words.length) return;
            const first = words[0].boundingBox.vertices;
            const last = words[words.length - 1].boundingBox.vertices;
            const v = (p: Vertex): [number, number] => [p.x ?? 0, p.y ?? 0];
            lines.push({ text: text.trim(), corners: [v(first[0]), v(last[1]), v(last[2]), v(first[3])] });
            text = "";
            words = [];
          };
          for (const word of para.words as Word[]) {
            words.push(word);
            for (const s of word.symbols) {
              text += s.text;
              const brk = s.property?.detectedBreak?.type;
              if (brk === "SPACE" || brk === "SURE_SPACE") text += " ";
              if (brk === "EOL_SURE_SPACE" || brk === "LINE_BREAK") flush();
            }
          }
          flush();
        }
      }
    }
    return json({ lines, source: "Google Cloud Vision", ms: Date.now() - started });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    // Details stay in the function log; they can carry request URLs.
    if (!timedOut) console.error(e);
    return json({ error: timedOut ? "timeout" : "internal error" }, timedOut ? 504 : 500);
  }
});
