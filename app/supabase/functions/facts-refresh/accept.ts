// The rule that keeps AI from inventing a figure: an extracted number is
// accepted only when the sentence it came from appears word for word in the
// fetched page, the number is in that sentence, and it sits in a sane band
// around the value we already had.

export type Candidate = { value: number | null; quote: string | null };

export type FactRule = {
  key: string;
  minRatio: number;
  maxRatio: number;
  min?: number;
  max?: number;
};

export type Verdict =
  | { ok: true; value: number; quote: string }
  | {
    ok: false;
    reason:
      | "no_value"
      | "no_quote"
      | "quote_not_in_page"
      | "number_not_in_quote"
      | "out_of_range";
  };

/** Shortest quote worth checking; shorter ones match almost anywhere. */
const MIN_QUOTE = 8;

const THAI_DIGITS = "๐๑๒๓๔๕๖๗๘๙";

/** NFKC, every run of whitespace (NBSP, newlines) to one space, lower case. */
export function normalizeText(s: string): string {
  return s.normalize("NFKC").replace(/[\s   ]+/gu, " ").trim()
    .toLowerCase();
}

/** Every number written in [s], in order: "1,250.50" is 1250.5. */
export function numbersIn(s: string): number[] {
  const western = s.replace(
    /[๐-๙]/g,
    (d) => String(THAI_DIGITS.indexOf(d)),
  );
  const found: number[] = [];
  for (
    const m of western.matchAll(/\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?/g)
  ) {
    const n = Number(m[0].replaceAll(",", ""));
    if (Number.isFinite(n)) found.push(n);
  }
  return found;
}

export function accept(
  candidate: Candidate,
  pageText: string,
  previous: number | null,
  rule: FactRule,
): Verdict {
  const { value, quote } = candidate;
  if (value === null || !Number.isFinite(value)) {
    return { ok: false, reason: "no_value" };
  }
  const q = quote === null ? "" : normalizeText(quote);
  if (q.length < MIN_QUOTE) return { ok: false, reason: "no_quote" };
  if (!normalizeText(pageText).includes(q)) {
    return { ok: false, reason: "quote_not_in_page" };
  }
  if (!numbersIn(quote!).some((n) => Math.abs(n - value) < 1e-9)) {
    return { ok: false, reason: "number_not_in_quote" };
  }
  if (rule.min !== undefined && value < rule.min) {
    return { ok: false, reason: "out_of_range" };
  }
  if (rule.max !== undefined && value > rule.max) {
    return { ok: false, reason: "out_of_range" };
  }
  if (
    previous !== null &&
    (value < previous * rule.minRatio || value > previous * rule.maxRatio)
  ) {
    return { ok: false, reason: "out_of_range" };
  }
  return { ok: true, value, quote: quote! };
}
