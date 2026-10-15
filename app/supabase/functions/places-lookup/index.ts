// One place from free text (a calendar event's location such as
// "Chatuchak Weekend Market"), with how it accepts payment, from Google
// Places Text Search (New). Payment facts are Google's own; absent stays null.
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";
import { paymentOf } from "../_shared/places.ts";

const SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";
const FIELD_MASK = [
  "places.displayName",
  "places.types",
  "places.location",
  "places.googleMapsUri",
  "places.paymentOptions",
].join(",");
const TIMEOUT_MS = 4000;
const BIAS_RADIUS_M = 20000;
const MAX_QUERY = 200;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { query, lat, lng } = await req.json();
    if (typeof query !== "string" || !query.trim() || query.length > MAX_QUERY) {
      return json({ error: `query is required, at most ${MAX_QUERY} characters` }, 400);
    }
    const near = typeof lat === "number" && typeof lng === "number";
    const res = await fetchWithTimeout(SEARCH_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": requireSecret("GOOGLE_MAPS_API_KEY"),
        "X-Goog-FieldMask": FIELD_MASK,
      },
      body: JSON.stringify({
        textQuery: query.trim(),
        maxResultCount: 1,
        ...(near
          ? { locationBias: { circle: { center: { latitude: lat, longitude: lng }, radius: BIAS_RADIUS_M } } }
          : {}),
      }),
    }, TIMEOUT_MS);
    const body = await res.json();
    if (!res.ok) return json({ error: body?.error?.message ?? "places error" }, 502);
    const p = body.places?.[0];
    const place = p
      ? {
        name: p.displayName?.text ?? "",
        types: p.types ?? [],
        payment: paymentOf(p.paymentOptions),
        lat: p.location?.latitude ?? null,
        lng: p.location?.longitude ?? null,
        mapsUri: p.googleMapsUri ?? null,
      }
      : null;
    return json({ place, source: "Google Maps", fetchedAt: new Date().toISOString() });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    return json({ error: timedOut ? "timeout" : String(e) }, timedOut ? 504 : 500);
  }
});
