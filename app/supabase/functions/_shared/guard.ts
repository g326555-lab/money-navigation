// Caller checks shared by every public Edge Function.
// The anon key ships inside the app, so it proves nothing about who is calling.
// Every call must carry a signed-in user's token (guests sign in anonymously),
// and each user has a daily cap per function.

import { fetchWithTimeout, json, requireSecret } from "./http.ts";

/** Daily calls per user and function. Sized for a traveller's real day. */
export const DAILY_LIMITS: Record<string, number> = {
  "gemini": 60,
  "read-text": 40,
  "stt-thai": 120,
  "tts-thai": 120,
  "places-lookup": 80,
  "places-market": 60,
  "price-reference": 30,
  "exchange-rates": 200,
};

/** Base64 length limits checked before any paid or rate-limited call. */
export const MAX_IMAGE_BASE64 = 5_600_000; // about 4 MB of JPEG
export const MAX_AUDIO_BASE64 = 700_000; // about 15 s of 16 kHz mono LINEAR16

export type Guarded = { userId: string } | { reject: Response };

/** Verifies the caller's token with Supabase Auth, then counts the call. */
export async function guard(req: Request, fn: string): Promise<Guarded> {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token) return { reject: json({ error: "sign-in required" }, 401) };

  const url = requireSecret("SUPABASE_URL");
  const anon = requireSecret("SUPABASE_ANON_KEY");
  const userRes = await fetchWithTimeout(`${url}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${token}`, apikey: anon },
  }, 4000);
  if (!userRes.ok) return { reject: json({ error: "sign-in required" }, 401) };
  const user = await userRes.json();
  const userId = typeof user?.id === "string" ? user.id : "";
  if (!userId) return { reject: json({ error: "sign-in required" }, 401) };

  const limit = DAILY_LIMITS[fn] ?? 50;
  const service = requireSecret("SUPABASE_SERVICE_ROLE_KEY");
  const capRes = await fetchWithTimeout(`${url}/rest/v1/rpc/bump_function_usage`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: service,
      Authorization: `Bearer ${service}`,
    },
    body: JSON.stringify({ p_user: userId, p_function: fn, p_limit: limit }),
  }, 4000);
  if (!capRes.ok) return { reject: json({ error: "usage check failed" }, 503) };
  const allowed = await capRes.json();
  if (allowed !== true) {
    return { reject: json({ error: "daily limit reached, try again tomorrow" }, 429) };
  }
  return { userId };
}

export function tooLarge(value: unknown, max: number): boolean {
  return typeof value === "string" && value.length > max;
}
