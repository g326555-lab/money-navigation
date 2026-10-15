// Re-checks the app's outside figures once a day (pg_cron). For each source:
// fetch the page, let Gemini copy the figure and the exact sentence, and keep
// the figure only when accept.ts finds that sentence verbatim in the page.
// Otherwise the old value stays and only checked_at and a note change.
// Callable only with the service role key.
import {
  corsHeaders,
  fetchWithTimeout,
  json,
  requireSecret,
} from "../_shared/http.ts";
import { accept } from "./accept.ts";
import { htmlToText, pdfToText } from "./extract.ts";
import { type FactSource, SOURCES } from "./sources.ts";

const MODELS = [
  "gemini-3.5-flash-lite",
  "gemini-3.5-flash",
  "gemini-3.1-flash-lite",
];
const FETCH_MS = 15000;
const GEMINI_MS = 20000;
/** Gemini reads at most this much of a page. */
const PAGE_LIMIT = 60000;
const BROWSER_UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36";

type Row = {
  key: string;
  value: number | null;
  unit: string;
  source_url: string;
  quoted_text: string | null;
  checked_at: string;
  fetched_at: string | null;
  status: "updated" | "unchanged" | "kept";
  note: string | null;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  // Only the scheduled job, with its own secret, may run a refresh.
  const token = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (!sameSecret(token, requireSecret("FACTS_CRON_SECRET"))) {
    return json({ error: "cron secret required" }, 401);
  }
  const serviceKey = requireSecret("SUPABASE_SERVICE_ROLE_KEY");

  const db = requireSecret("SUPABASE_URL");
  const previous = await readPrevious(db, serviceKey);
  const pages = new Map<string, Promise<string>>();
  const results: { key: string; status: string; note: string | null }[] = [];
  const rows: Row[] = [];
  const now = new Date().toISOString();

  for (const source of SOURCES) {
    const old = previous.get(source.key) ?? null;
    let note: string | null = null;
    let row: Row | null = null;
    try {
      if (!pages.has(source.url)) pages.set(source.url, fetchText(source));
      const text = await pages.get(source.url)!;
      const candidate = await askGemini(source, text);
      const verdict = accept(candidate, text, old?.value ?? null, source.rule);
      if (verdict.ok) {
        row = {
          key: source.key,
          value: verdict.value,
          unit: source.unit,
          source_url: source.url,
          quoted_text: verdict.quote,
          checked_at: now,
          fetched_at: now,
          status: old?.value === verdict.value ? "unchanged" : "updated",
          note: null,
        };
      } else {
        note = verdict.reason;
      }
    } catch (e) {
      note = `fetch_failed: ${String(e).slice(0, 120)}`;
    }
    if (!row) {
      if (old === null) {
        // Nothing verified yet and nothing to keep: no row is better than a guess.
        results.push({ key: source.key, status: "skipped", note });
        continue;
      }
      row = {
        key: source.key,
        value: old.value,
        unit: source.unit,
        source_url: old.source_url ?? source.url,
        quoted_text: old.quoted_text ?? null,
        checked_at: now,
        fetched_at: old.fetched_at ?? null,
        status: "kept",
        note,
      };
    }
    rows.push(row);
    results.push({ key: source.key, status: row.status, note: row.note });
  }

  if (rows.length) await upsert(db, serviceKey, rows);
  const count = (s: string) => results.filter((r) => r.status === s).length;
  return json({
    checked: results.length,
    updated: count("updated"),
    unchanged: count("unchanged"),
    kept: count("kept"),
    results,
  });
});

/** Constant-time comparison, so timing does not reveal the secret. */
function sameSecret(given: string, secret: string): boolean {
  const enc = new TextEncoder();
  const a = enc.encode(given);
  const b = enc.encode(secret);
  let diff = a.length ^ b.length;
  for (let i = 0; i < b.length; i++) diff |= (a[i] ?? 0) ^ b[i];
  return given.length > 0 && diff === 0;
}

async function fetchText(source: FactSource): Promise<string> {
  const res = await fetchWithTimeout(source.url, {
    headers: {
      "User-Agent": BROWSER_UA,
      "Accept": "text/html,application/pdf,*/*",
    },
  }, FETCH_MS);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  if (source.kind === "pdf") {
    return await pdfToText(new Uint8Array(await res.arrayBuffer()));
  }
  return htmlToText(await res.text());
}

async function askGemini(
  source: FactSource,
  text: string,
): Promise<{ value: number | null; quote: string | null }> {
  const key = requireSecret("GEMINI_API_KEY");
  const body = {
    contents: [{
      role: "user",
      parts: [{
        text: `From the page text below, find ${source.ask}. ` +
          'Return JSON only: {"value": number|null, "quote": string|null}. ' +
          "quote must be copied character for character from the page text: the shortest " +
          "run of words (at least 3 words) that contains the number. value is that number " +
          "as written. If the page does not state it, return nulls. Never estimate.\n\n" +
          `PAGE TEXT:\n${text.slice(0, PAGE_LIMIT)}`,
      }],
    }],
    generationConfig: {
      responseMimeType: "application/json",
      temperature: 0,
      thinkingConfig: { thinkingLevel: "minimal" },
    },
  };
  let lastError = "no model answered";
  for (const model of MODELS) {
    try {
      const res = await fetchWithTimeout(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify(body),
        },
        GEMINI_MS,
      );
      const out = await res.json();
      if (!res.ok) {
        lastError = `${model} ${res.status}`;
        continue;
      }
      const raw = out?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof raw !== "string" || !raw.trim()) {
        lastError = `${model} empty`;
        continue;
      }
      const parsed = JSON.parse(raw);
      return {
        value: typeof parsed.value === "number" ? parsed.value : null,
        quote: typeof parsed.quote === "string" ? parsed.quote : null,
      };
    } catch (e) {
      lastError = `${model} ${String(e).slice(0, 60)}`;
    }
  }
  throw new Error(lastError);
}

type Previous = {
  value: number;
  source_url: string | null;
  quoted_text: string | null;
  fetched_at: string | null;
};

async function readPrevious(
  db: string,
  key: string,
): Promise<Map<string, Previous>> {
  const keys = SOURCES.map((s) => `"${s.key}"`).join(",");
  const res = await fetch(
    `${db}/rest/v1/facts?select=key,value,source_url,quoted_text,fetched_at&key=in.(${
      encodeURIComponent(keys)
    })`,
    { headers: { apikey: key, Authorization: `Bearer ${key}` } },
  );
  const map = new Map<string, Previous>();
  if (!res.ok) return map;
  for (const r of await res.json()) {
    const value = Number(r.value);
    if (Number.isFinite(value) && value > 0) map.set(r.key, { ...r, value });
  }
  return map;
}

async function upsert(db: string, key: string, rows: Row[]): Promise<void> {
  const res = await fetch(`${db}/rest/v1/facts?on_conflict=key`, {
    method: "POST",
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify(rows),
  });
  if (!res.ok) {
    throw new Error(`facts upsert ${res.status}: ${await res.text()}`);
  }
}
