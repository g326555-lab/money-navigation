// Nearby markets and shops from Google Places API (New), so a usual price
// can show which real places back it up (rating, number of ratings, price
// level). The field mask is strict: reviews would bill the call at the
// Atmosphere SKU, so they are not requested.
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";
import { paymentOf, validLanguage, validLatLng } from "../_shared/places.ts";

const PLACES_URL = "https://places.googleapis.com/v1/places:searchNearby";
const FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.primaryType",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.googleMapsUri",
  "places.location",
].join(",");
// Payment options bill at a higher Places SKU, so they are asked for only
// when the caller sets withPayment.
const PAYMENT_FIELDS = ["places.paymentOptions", "places.types"].join(",");
const TIMEOUT_MS = 4000;
const RADIUS_M = 1500;
const MAX_RESULTS = 10;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { lat, lng, types, withPayment, languageCode } = await req.json();
    const payment = withPayment === true;
    if (!validLatLng(lat, lng)) {
      return json({ error: "lat and lng are required numbers in range" }, 400);
    }
    if (types !== undefined && !(Array.isArray(types) && types.length <= 10 &&
        types.every((t: unknown) => typeof t === "string" && /^[a-z_]{2,40}$/.test(t)))) {
      return json({ error: "types must be up to 10 Google place type names" }, 400);
    }
    const res = await fetchWithTimeout(PLACES_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": requireSecret("GOOGLE_MAPS_API_KEY"),
        "X-Goog-FieldMask": payment ? `${FIELD_MASK},${PAYMENT_FIELDS}` : FIELD_MASK,
      },
      body: JSON.stringify({
        includedTypes: Array.isArray(types) && types.length
          ? types
          : ["market", "grocery_store", "supermarket"],
        maxResultCount: MAX_RESULTS,
        rankPreference: "POPULARITY",
        ...(validLanguage(languageCode) ? { languageCode } : {}),
        locationRestriction: {
          circle: { center: { latitude: lat, longitude: lng }, radius: RADIUS_M },
        },
      }),
    }, TIMEOUT_MS);
    const body = await res.json();
    if (!res.ok) return json({ error: body?.error?.message ?? "places error" }, 502);
    // Only places people have actually rated count as price evidence.
    // Payment lookups (ATMs are rarely rated) keep every place.
    const places = (body.places ?? [])
      .filter((p: Record<string, any>) => payment || (p.userRatingCount ?? 0) > 0)
      .map((p: Record<string, any>) => ({
      id: p.id,
      name: p.displayName?.text ?? "",
      type: p.primaryType ?? null,
      rating: p.rating ?? null,
      ratingCount: p.userRatingCount ?? 0,
      priceLevel: p.priceLevel ?? null,
      mapsUri: p.googleMapsUri ?? null,
      lat: p.location?.latitude ?? null,
      lng: p.location?.longitude ?? null,
      ...(payment ? { payment: paymentOf(p.paymentOptions), types: p.types ?? [] } : {}),
      }));
    return json({ places, source: "Google Maps", fetchedAt: new Date().toISOString() });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    return json({ error: timedOut ? "timeout" : String(e) }, timedOut ? 504 : 500);
  }
});
