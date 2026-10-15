// Natural Thai speech for the counter-offer sentence (Cloud Text-to-Speech).
// Only text is sent; the app plays the returned MP3 and falls back to the
// on-device voice if this fails or is slow.
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";

const TTS_URL = "https://texttospeech.googleapis.com/v1/text:synthesize";
const TIMEOUT_MS = 3000;
const MAX_CHARS = 200;
const DEFAULT_VOICE = "th-TH-Chirp3-HD-Achernar";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { text, voice } = await req.json();
    if (typeof text !== "string" || !text.trim() || text.length > MAX_CHARS) {
      return json({ error: `text is required, at most ${MAX_CHARS} characters` }, 400);
    }
    const res = await fetchWithTimeout(
      `${TTS_URL}?key=${requireSecret("GOOGLE_MAPS_API_KEY")}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode: "th-TH", name: typeof voice === "string" ? voice : DEFAULT_VOICE },
          audioConfig: { audioEncoding: "MP3", speakingRate: 0.9 },
        }),
      },
      TIMEOUT_MS,
    );
    const body = await res.json();
    if (!res.ok) return json({ error: body?.error?.message ?? "tts error" }, 502);
    return json({ audioBase64: body.audioContent, voice: voice ?? DEFAULT_VOICE });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    return json({ error: timedOut ? "timeout" : String(e) }, timedOut ? 504 : 500);
  }
});
