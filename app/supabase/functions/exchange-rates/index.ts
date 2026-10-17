// Serves the latest cached ThaiRate payload. The user's precise location never
// leaves the phone; nearby ranking is calculated locally from the cached feed.
import { corsHeaders, json, requireSecret } from "../_shared/http.ts";
import { guard } from "../_shared/guard.ts";

const CACHE_MAX_AGE_MS = 30 * 60 * 1000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const caller = await guard(req, "exchange-rates");
  if ("reject" in caller) return caller.reject;
  try {
    const databaseUrl = requireSecret("SUPABASE_URL");
    // Read with the public anon key: the row is world-readable through RLS,
    // so this function never needs the service role.
    const anonKey = requireSecret("SUPABASE_ANON_KEY");
    const response = await fetch(
      `${databaseUrl}/rest/v1/exchange_rate_cache?cache_key=eq.latest&select=payload,source_generated_at,refreshed_at&limit=1`,
      {
        headers: {
          "apikey": anonKey,
          "Authorization": `Bearer ${anonKey}`,
        },
      },
    );
    if (!response.ok) return json({ error: "exchange rates unavailable" }, 502);
    const rows = await response.json();
    const row = Array.isArray(rows) ? rows[0] : null;
    if (!row || !row.payload) return json({ error: "exchange rates not loaded yet" }, 503);
    const refreshedAt = typeof row.refreshed_at === "string" ? row.refreshed_at : null;
    const age = refreshedAt ? Date.now() - Date.parse(refreshedAt) : Infinity;
    return json({
      data: row.payload,
      refreshedAt,
      sourceGeneratedAt: row.source_generated_at,
      stale: !Number.isFinite(age) || age < 0 || age > CACHE_MAX_AGE_MS,
      attribution: "ThaiRate",
      attributionUrl: "https://thairate.com/",
      license: "CC BY 4.0",
    });
  } catch (error) {
    console.error(error);
    return json({ error: "exchange rates unavailable" }, 500);
  }
});
