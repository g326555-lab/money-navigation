// A sourced Bangkok price range for an item that is not in the app's data
// file ("vanilla latte"). Tavily finds pages, this function fetches them
// itself, Gemini (free key) proposes a range with verbatim quotes, and a
// range is accepted only when every quote it rests on appears word for word
// in the page we fetched and the numbers are sane. Found ranges are cached in
// `facts` (one search per item); otherwise the answer is "no sourced range".
import { corsHeaders, fetchWithTimeout, json, requireSecret } from "../_shared/http.ts";

const CACHE_DAYS = 30;
const SEARCH_TIMEOUT_MS = 6000;
const PAGE_TIMEOUT_MS = 4000;
const GEMINI_TIMEOUT_MS = 8000;
const MAX_PAGES = 4;
const EXCERPT_CHARS = 2500;
const MODELS = ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-3.5-flash"];
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 Chrome/124 Safari/537.36";

type Source = { url: string; quote: string; date: string; dateKind: "fetched" | "published" };

/// PostgREST on the project's own database, with the service role (facts
/// are written only by functions).
function rest(path: string, init: RequestInit = {}) {
  const key = requireSecret("SUPABASE_SERVICE_ROLE_KEY");
  return fetchWithTimeout(`${requireSecret("SUPABASE_URL")}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json", ...(init.headers ?? {}) },
  }, PAGE_TIMEOUT_MS);
}

const squash = (s: string) => s.replace(/\s+/g, " ").trim();

function pageText(html: string): string {
  return squash(
    html.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&#36;/g, "$"),
  );
}

/// The parts of a page around price mentions, so the model reads little.
function excerpt(text: string): string {
  const parts: string[] = [];
  for (const m of text.matchAll(/(baht|THB|฿|บาท)/gi)) {
    const i = m.index ?? 0;
    parts.push(text.slice(Math.max(0, i - 220), i + 80));
    if (parts.join(" … ").length > EXCERPT_CHARS) break;
  }
  return parts.join(" … ").slice(0, EXCERPT_CHARS);
}

async function cached(slug: string) {
  const since = new Date(Date.now() - CACHE_DAYS * 86400000).toISOString();
  const res = await rest(
    `facts?select=key,value,note&key=in.(price.${slug}.low,price.${slug}.high)&checked_at=gte.${encodeURIComponent(since)}`,
  );
  const data = res.ok ? (await res.json()) as { key: string; value: number; note: string | null }[] : [];
  const low = data?.find((r) => r.key.endsWith(".low"));
  const high = data?.find((r) => r.key.endsWith(".high"));
  if (!low || !high) return null;
  try {
    const sources = JSON.parse(low.note ?? "[]") as Source[];
    return { low: Number(low.value), high: Number(high.value), sources };
  } catch {
    return null;
  }
}

async function askGemini(item: string, pages: { url: string; text: string }[]) {
  const key = requireSecret("GEMINI_API_KEY");
  const prompt =
    `Find the typical price in Bangkok of ONE "${item}" from these web page excerpts. ` +
    'Return JSON only: {"low": number|null, "high": number|null, "quotes": [{"url": string, "quote": string}]}. ' +
    "Each quote must be copied character for character from the excerpt of that url (10-200 characters) " +
    "and must contain the price number. low and high must be numbers that appear in the quotes. " +
    "Use only prices for this item in Thai baht. If the excerpts do not state it, return low null.\n\n" +
    pages.map((p) => `URL: ${p.url}\nEXCERPT: ${excerpt(p.text)}`).join("\n\n");
  const body = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: { responseMimeType: "application/json", temperature: 0, thinkingConfig: { thinkingLevel: "minimal" } },
  };
  // Raced like the gemini function: the free key's latency swings widely.
  const controllers = MODELS.map(() => new AbortController());
  try {
    return await Promise.any(MODELS.map(async (m, i) => {
      const res = await fetchWithTimeout(
        `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json", "x-goog-api-key": key },
          body: JSON.stringify(body),
          signal: controllers[i].signal,
        },
        GEMINI_TIMEOUT_MS,
      );
      if (!res.ok) throw new Error(`${res.status}`);
      const data = await res.json();
      const text = data?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("") ?? "";
      const parsed = JSON.parse(text);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("shape");
      return parsed as { low?: unknown; high?: unknown; quotes?: unknown };
    }));
  } finally {
    controllers.forEach((c) => c.abort());
  }
}

/// Prices in a quote: only numbers written next to a currency word, so
/// sizes ("16 oz", "500 ml"), years and counts never count.
function pricesIn(quote: string): number[] {
  const re = /(?:฿|THB)\s*(\d[\d,]*(?:\.\d+)?)|(\d[\d,]*(?:\.\d+)?)\s*(?:-|–|to)?\s*(?:\d[\d,]*(?:\.\d+)?\s*)?(?:baht|THB|บาท|฿)/gi;
  const out: number[] = [];
  for (const m of quote.matchAll(re)) {
    // "25-35 Baht": both ends of a range next to the currency word count.
    const whole = m[0];
    for (const n of whole.replace(/,/g, "").match(/\d+(?:\.\d+)?/g) ?? []) out.push(Number(n));
  }
  return out;
}

/// Only quotes found verbatim in the page we fetched, naming the item,
/// count; low and high must each be a currency-tagged number in such a
/// quote, and the range must be plausible. Each bound keeps its own source.
function verify(
  item: string,
  answer: { low?: unknown; high?: unknown; quotes?: unknown },
  pages: { url: string; text: string }[],
): { low: number; high: number; sources: Source[]; lowSource: Source; highSource: Source } | null {
  const low = Number(answer.low), high = Number(answer.high);
  if (!Number.isFinite(low) || !Number.isFinite(high)) return null;
  if (low <= 0 || high < low || high > 100000 || high > low * 10) return null;
  const words = item.toLowerCase().split(/[\s\-']+/).filter((w) => w.length >= 4);
  const today = new Date().toISOString().slice(0, 10);
  const sources: Source[] = [];
  for (const q of Array.isArray(answer.quotes) ? answer.quotes : []) {
    const url = typeof q?.url === "string" ? q.url : "";
    const quote = typeof q?.quote === "string" ? squash(q.quote) : "";
    const page = pages.find((p) => p.url === url);
    if (!page || quote.length < 10 || quote.length > 300 || !page.text.includes(quote)) continue;
    // The quote must be about this item, not another dish on the page.
    if (words.length && !words.some((w) => quote.toLowerCase().includes(w))) continue;
    if (!pricesIn(quote).length || sources.some((s) => s.url === url && s.quote === quote)) continue;
    sources.push({ url, quote, date: today, dateKind: "fetched" });
  }
  const lowSource = sources.find((s) => pricesIn(s.quote).includes(low));
  const highSource = sources.find((s) => pricesIn(s.quote).includes(high));
  if (!lowSource || !highSource) return null;
  const used = [lowSource, ...(highSource === lowSource ? [] : [highSource])];
  return { low, high, sources: used, lowSource, highSource };
}

/// Items searched recently without a sourced result, so a retry does not
/// spend another search (per function instance; facts holds only finds).
const misses = new Map<string, number>();
const MISS_TTL_MS = 24 * 3600 * 1000;

/// Our own page read: https only, no redirects to elsewhere, HTML only,
/// at most 1 MB.
async function readPage(url: string): Promise<{ url: string; text: string } | null> {
  try {
    const r = await fetchWithTimeout(url, { headers: { "User-Agent": UA }, redirect: "manual" }, PAGE_TIMEOUT_MS);
    if (!r.ok || !(r.headers.get("content-type") ?? "").includes("text/html") || !r.body) return null;
    const reader = r.body.getReader();
    const chunks: Uint8Array[] = [];
    let size = 0;
    while (size < 1_000_000) {
      const { done, value } = await reader.read();
      if (done || !value) break;
      chunks.push(value);
      size += value.length;
    }
    reader.cancel().catch(() => {});
    const bytes = new Uint8Array(size);
    let at = 0;
    for (const c of chunks) {
      bytes.set(c.subarray(0, Math.min(c.length, size - at)), at);
      at += c.length;
      if (at >= size) break;
    }
    return { url, text: pageText(new TextDecoder().decode(bytes)) };
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const started = Date.now();
  try {
    const { nameEn } = await req.json();
    if (typeof nameEn !== "string" || !/^[A-Za-z][A-Za-z \-']{1,39}$/.test(nameEn.trim())) {
      return json({ error: "nameEn is required: plain English words, up to 40 characters" }, 400);
    }
    const item = nameEn.trim();
    const slug = item.toLowerCase().replace(/[^a-z]+/g, "_");
    const hit = await cached(slug);
    if (hit) return json({ item, ...hit, cached: true, source: "Tavily search + Gemini", ms: Date.now() - started });
    if (Date.now() - (misses.get(slug) ?? 0) < MISS_TTL_MS) {
      return json({ item, low: null, reason: "no sourced range (checked recently)", ms: Date.now() - started });
    }

    const search = await fetchWithTimeout("https://api.tavily.com/search", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${requireSecret("TAVILY_API_KEY")}` },
      body: JSON.stringify({ query: `${item} price in Bangkok baht`, search_depth: "basic", max_results: 6 }),
    }, SEARCH_TIMEOUT_MS);
    if (!search.ok) return json({ error: "search failed" }, 502);
    const results = ((await search.json()).results ?? []) as { url?: string }[];
    const urls = results.map((r) => r.url).filter((u): u is string => typeof u === "string" && u.startsWith("https://"))
      .slice(0, MAX_PAGES);
    // We read the pages ourselves: the quote must be on the page we fetched.
    const pages = (await Promise.all(urls.map(readPage)))
      .filter((p): p is { url: string; text: string } => p !== null && /baht|THB|฿|บาท/i.test(p.text));
    if (!pages.length) {
      misses.set(slug, Date.now());
      return json({ item, low: null, reason: "no page states a price", ms: Date.now() - started });
    }

    let found = null;
    try {
      found = verify(item, await askGemini(item, pages), pages);
    } catch {
      return json({ item, low: null, reason: "reader unavailable", ms: Date.now() - started });
    }
    if (!found) {
      misses.set(slug, Date.now());
      return json({ item, low: null, reason: "no verifiable quote", pagesRead: pages.length, ms: Date.now() - started });
    }

    const now = new Date().toISOString();
    const note = JSON.stringify(found.sources);
    const saved = await rest("facts?on_conflict=key", {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates" },
      body: JSON.stringify([
      { key: `price.${slug}.low`, value: found.low, unit: "THB", source_url: found.lowSource.url,
        quoted_text: found.lowSource.quote, checked_at: now, fetched_at: now, status: "new", note },
      { key: `price.${slug}.high`, value: found.high, unit: "THB", source_url: found.highSource.url,
        quoted_text: found.highSource.quote, checked_at: now, fetched_at: now, status: "new", note },
      ]),
    });
    if (!saved.ok) console.error("facts write failed", saved.status, await saved.text());
    return json({ item, low: found.low, high: found.high, sources: found.sources, cached: false, source: "Tavily search + Gemini", ms: Date.now() - started });
  } catch (e) {
    console.error(e);
    return json({ error: "internal error" }, 500);
  }
});
