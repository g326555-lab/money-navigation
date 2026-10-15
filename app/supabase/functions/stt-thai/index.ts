// Cloud speech for the seller's sentence: Google Cloud Speech-to-Text v1
// (default model, th-TH) with our item words as phrase hints. Measured on
// 15 Kanya-voice sentences (15 Oct): 15/15 item and price right in quiet,
// 13/15 with pink noise at -10 dB, about 1.1 s; Chirp 3 (v2) was slower
// and only accepts service-account auth, which the org policy blocks.
// The audio is not stored.
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";

const SPEECH_URL = "https://speech.googleapis.com/v1/speech:recognize";
const TIMEOUT_MS = 9000;
// About 15 s of 16 kHz 16-bit mono audio, base64.
const MAX_BASE64 = 700_000;
const ENCODINGS = ["LINEAR16", "OGG_OPUS", "WEBM_OPUS", "AMR_WB", "FLAC"];
const MAX_PHRASES = 100;
const BOOST = 15;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const started = Date.now();
  try {
    const { audioBase64, encoding, sampleRateHertz, phrases } = await req.json();
    if (typeof audioBase64 !== "string" || !audioBase64 || audioBase64.length > MAX_BASE64) {
      return json({ error: "audioBase64 is required (at most about 15 s)" }, 400);
    }
    const enc = typeof encoding === "string" ? encoding : "LINEAR16";
    if (!ENCODINGS.includes(enc)) return json({ error: `encoding must be one of ${ENCODINGS.join(", ")}` }, 400);
    const rate = typeof sampleRateHertz === "number" && Number.isInteger(sampleRateHertz) &&
        sampleRateHertz >= 8000 && sampleRateHertz <= 48000
      ? sampleRateHertz
      : 16000;
    const hints = Array.isArray(phrases)
      ? phrases.filter((p: unknown) => typeof p === "string" && p.length > 0 && p.length <= 40).slice(0, MAX_PHRASES)
      : [];
    const res = await fetchWithTimeout(`${SPEECH_URL}?key=${requireSecret("GOOGLE_SPEECH_API_KEY")}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        config: {
          encoding: enc,
          sampleRateHertz: rate,
          languageCode: "th-TH",
          maxAlternatives: 3,
          ...(hints.length ? { speechContexts: [{ phrases: hints, boost: BOOST }] } : {}),
        },
        audio: { content: audioBase64 },
      }),
    }, TIMEOUT_MS);
    const body = await res.json();
    if (!res.ok) return json({ error: body?.error?.message ?? "speech error" }, 502);
    const alternatives = (body.results ?? []).flatMap((r: Record<string, any>) =>
      (r.alternatives ?? []).map((a: Record<string, any>) => ({
        text: String(a.transcript ?? "").trim(),
        confidence: typeof a.confidence === "number" ? a.confidence : null,
      }))
    ).filter((a: { text: string }) => a.text);
    return json({ alternatives, source: "Google Cloud Speech-to-Text", ms: Date.now() - started });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    return json({ error: timedOut ? "timeout" : String(e) }, timedOut ? 504 : 500);
  }
});
