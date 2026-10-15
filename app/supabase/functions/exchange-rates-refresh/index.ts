// Refreshes the public, attributed Thai cash-exchange feed every 15 minutes.
// Callable only by the existing scheduled job using FACTS_CRON_SECRET.
import {
  corsHeaders,
  fetchWithTimeout,
  json,
  requireSecret,
} from "../_shared/http.ts";

const SOURCE_URL = "https://api.thairate.com/v1/rates.json";
const TIMEOUT_MS = 12000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!sameSecret(token, requireSecret("FACTS_CRON_SECRET"))) {
      return json({ error: "cron secret required" }, 401);
    }

    const response = await fetchWithTimeout(SOURCE_URL, {
      headers: { "Accept": "application/json", "User-Agent": "MoneyNavigation/1.0" },
    }, TIMEOUT_MS);
    if (!response.ok) return json({ error: `ThaiRate HTTP ${response.status}` }, 502);
    const payload = await response.json();
    if (!validPayload(payload)) return json({ error: "ThaiRate response shape changed" }, 502);

    const databaseUrl = requireSecret("SUPABASE_URL");
    const serviceKey = requireSecret("SUPABASE_SERVICE_ROLE_KEY");
    const refreshedAt = new Date().toISOString();
    const upsert = await fetch(
      `${databaseUrl}/rest/v1/exchange_rate_cache?on_conflict=cache_key`,
      {
        method: "POST",
        headers: {
          "apikey": serviceKey,
          "Authorization": `Bearer ${serviceKey}`,
          "Content-Type": "application/json",
          "Prefer": "resolution=merge-duplicates,return=minimal",
        },
        body: JSON.stringify({
          cache_key: "latest",
          payload,
          source_generated_at: payload.generatedAt,
          refreshed_at: refreshedAt,
        }),
      },
    );
    if (!upsert.ok) {
      console.error("exchange cache upsert failed", upsert.status);
      return json({ error: "cache write failed" }, 502);
    }
    return json({
      refreshedAt,
      sourceGeneratedAt: payload.generatedAt,
      stores: storeCount(payload.stores),
      source: "ThaiRate",
    });
  } catch (error) {
    const timeout = error instanceof DOMException && error.name === "AbortError";
    if (!timeout) console.error(error);
    return json({ error: timeout ? "ThaiRate timeout" : "refresh failed" }, timeout ? 504 : 502);
  }
});

// ThaiRate publishes `stores` as an array of objects with an `id` (checked
// against the live feed on 16 Oct 2026). The app also accepts an object keyed
// by store id, so both shapes pass here and the client parser agrees.
type Stores = Array<Record<string, unknown>> | Record<string, unknown>;

function storeCount(stores: Stores): number {
  return Array.isArray(stores) ? stores.length : Object.keys(stores).length;
}

function validPayload(value: unknown): value is {
  generatedAt: string;
  stores: Stores;
  rates: Record<string, unknown>;
  sources: Record<string, unknown>;
} {
  if (!value || typeof value !== "object") return false;
  const payload = value as Record<string, unknown>;
  const stores = payload.stores;
  const storesValid = Array.isArray(stores)
    ? stores.length > 0 &&
      stores.every((store) =>
        !!store && typeof store === "object" &&
        typeof (store as Record<string, unknown>).id === "string"
      )
    : !!stores && typeof stores === "object" && Object.keys(stores).length > 0;
  return typeof payload.generatedAt === "string" &&
    Number.isFinite(Date.parse(payload.generatedAt)) &&
    storesValid &&
    !Array.isArray(payload.rates) &&
    !!payload.rates && typeof payload.rates === "object" &&
    Object.keys(payload.rates).length > 0 &&
    !!payload.sources && typeof payload.sources === "object";
}

function sameSecret(given: string, secret: string): boolean {
  const enc = new TextEncoder();
  const a = enc.encode(given);
  const b = enc.encode(secret);
  let diff = a.length ^ b.length;
  for (let i = 0; i < b.length; i++) diff |= (a[i] ?? 0) ^ b[i];
  return given.length > 0 && diff === 0;
}
