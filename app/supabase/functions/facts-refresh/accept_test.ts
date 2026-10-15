import { assert, assertEquals } from "jsr:@std/assert";
import {
  accept,
  type Candidate,
  type FactRule,
  normalizeText,
  numbersIn,
} from "./accept.ts";

const KASIKORN_PAGE =
  "Fees for foreign cards. Cash withdrawal via K-ATM with cards issued abroad: Visa 250 Baht/transaction, Mastercard 250 Baht/transaction.";
const VISA_QUOTE = "Visa 250 Baht/transaction";

const atmRule: FactRule = {
  key: "th.atm_fee.kasikorn.visa",
  minRatio: 0.5,
  maxRatio: 2,
  min: 50,
  max: 1000,
};
const ratioOnly: FactRule = {
  key: "th.atm_fee.kasikorn.visa",
  minRatio: 0.5,
  maxRatio: 2,
};

function cand(value: number | null, quote: string | null): Candidate {
  return { value, quote };
}

// normalizeText

Deno.test("normalizeText collapses spaces, newlines, tabs and NBSP, trims and lower-cases", () => {
  assertEquals(
    normalizeText("  Visa 250\n\tBaht/Transaction  "),
    "visa 250 baht/transaction",
  );
});

Deno.test("normalizeText applies NFKC (full-width digits and letters)", () => {
  assertEquals(normalizeText("Ｖｉｓａ　２５０"), "visa 250");
});

// numbersIn

Deno.test("numbersIn reads a plain integer", () => {
  assertEquals(numbersIn("Visa 250 Baht/transaction"), [250]);
});

Deno.test("numbersIn reads thousands separators and decimals", () => {
  assertEquals(numbersIn("1,250.50"), [1250.5]);
});

Deno.test("numbersIn reads a percent figure without the sign", () => {
  assertEquals(numbersIn("a fee of 2.5% applies"), [2.5]);
});

Deno.test("numbersIn converts Thai digits", () => {
  assertEquals(numbersIn("๒๕๐ บาท"), [250]);
});

Deno.test("numbersIn returns every number in order", () => {
  assertEquals(numbersIn("Visa 250 Baht, Mastercard 220 Baht"), [250, 220]);
});

Deno.test("numbersIn returns an empty list when there is no number", () => {
  assertEquals(numbersIn("no fee stated"), []);
});

// accept: the happy path

Deno.test("accept: verbatim quote with the value, same as before -> ok", () => {
  const v = accept(cand(250, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule);
  assertEquals(v, { ok: true, value: 250, quote: VISA_QUOTE });
});

Deno.test("accept: whitespace, newlines and NBSP differ between page and quote -> ok", () => {
  const page =
    "Cash withdrawal via K-ATM\n with cards issued abroad:\n\nVisa  250   Baht/transaction";
  const v = accept(cand(250, VISA_QUOTE), page, 250, atmRule);
  assert(v.ok);
});

Deno.test("accept: quote with different case and spacing than the page -> ok", () => {
  const v = accept(
    cand(250, "  visa 250\nbaht/TRANSACTION "),
    KASIKORN_PAGE,
    250,
    atmRule,
  );
  assert(v.ok);
});

Deno.test("accept: no previous value, inside min/max -> ok", () => {
  const rule: FactRule = { ...ratioOnly, min: 50, max: 1000 };
  const v = accept(cand(250, VISA_QUOTE), KASIKORN_PAGE, null, rule);
  assert(v.ok);
});

Deno.test("accept: Thai-digit quote found in a Thai page -> ok", () => {
  const page = "ค่าธรรมเนียมถอนเงินบัตรต่างประเทศ ๒๕๐ บาท ต่อรายการ";
  const quote = "บัตรต่างประเทศ ๒๕๐ บาท ต่อรายการ";
  const v = accept(cand(250, quote), page, 250, atmRule);
  assert(v.ok);
});

Deno.test("accept: a raise within the ratio band -> ok", () => {
  const page = "Cash withdrawal via K-ATM: Visa 300 Baht/transaction";
  const v = accept(cand(300, "Visa 300 Baht/transaction"), page, 250, atmRule);
  assertEquals(v, { ok: true, value: 300, quote: "Visa 300 Baht/transaction" });
});

// accept: no value

Deno.test("accept: null value -> no_value", () => {
  assertEquals(accept(cand(null, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_value",
  });
});

Deno.test("accept: NaN value -> no_value", () => {
  assertEquals(accept(cand(NaN, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_value",
  });
});

Deno.test("accept: Infinity value -> no_value", () => {
  assertEquals(
    accept(cand(Infinity, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule),
    { ok: false, reason: "no_value" },
  );
});

Deno.test("accept: null value with null quote reports no_value first", () => {
  assertEquals(accept(cand(null, null), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_value",
  });
});

// accept: no quote

Deno.test("accept: null quote -> no_quote", () => {
  assertEquals(accept(cand(250, null), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_quote",
  });
});

Deno.test("accept: 5-character quote -> no_quote", () => {
  assertEquals(accept(cand(250, "Visa "), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_quote",
  });
});

Deno.test("accept: quote short only after normalising (padded with spaces) -> no_quote", () => {
  assertEquals(
    accept(cand(250, "   250 B   \n\n "), KASIKORN_PAGE, 250, atmRule),
    { ok: false, reason: "no_quote" },
  );
});

Deno.test("accept: empty quote -> no_quote", () => {
  assertEquals(accept(cand(250, ""), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "no_quote",
  });
});

// accept: quote must be verbatim in the page

Deno.test("accept: one word changed in the quote -> quote_not_in_page", () => {
  assertEquals(
    accept(cand(250, "Visa 250 Baht/withdrawal"), KASIKORN_PAGE, 250, atmRule),
    { ok: false, reason: "quote_not_in_page" },
  );
});

Deno.test("accept: invented sentence with a plausible fee -> quote_not_in_page", () => {
  assertEquals(
    accept(
      cand(220, "Foreign card withdrawal fee 220 Baht"),
      KASIKORN_PAGE,
      250,
      atmRule,
    ),
    { ok: false, reason: "quote_not_in_page" },
  );
});

Deno.test("accept: empty page text -> quote_not_in_page", () => {
  assertEquals(accept(cand(250, VISA_QUOTE), "", 250, atmRule), {
    ok: false,
    reason: "quote_not_in_page",
  });
});

Deno.test("accept: number changed inside an otherwise verbatim quote -> quote_not_in_page", () => {
  assertEquals(
    accept(cand(220, "Visa 220 Baht/transaction"), KASIKORN_PAGE, 250, atmRule),
    { ok: false, reason: "quote_not_in_page" },
  );
});

// accept: the value must be written in the quote

Deno.test("accept: value 350 not in the quote -> number_not_in_quote", () => {
  assertEquals(accept(cand(350, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "number_not_in_quote",
  });
});

Deno.test("accept: verbatim quote without any number -> number_not_in_quote", () => {
  assertEquals(
    accept(
      cand(250, "Cash withdrawal via K-ATM"),
      KASIKORN_PAGE,
      250,
      atmRule,
    ),
    { ok: false, reason: "number_not_in_quote" },
  );
});

Deno.test("accept: value rounded from the quote (250.5 vs 250) -> number_not_in_quote", () => {
  assertEquals(
    accept(cand(250.5, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule),
    { ok: false, reason: "number_not_in_quote" },
  );
});

Deno.test("accept: value that is only a digit fragment of the quote (25) -> number_not_in_quote", () => {
  assertEquals(accept(cand(25, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule), {
    ok: false,
    reason: "number_not_in_quote",
  });
});

// accept: range checks

Deno.test("accept: 2500 against previous 250 -> out_of_range", () => {
  const page = "Cash withdrawal via K-ATM: Visa 2,500 Baht/transaction";
  assertEquals(
    accept(cand(2500, "Visa 2,500 Baht/transaction"), page, 250, ratioOnly),
    { ok: false, reason: "out_of_range" },
  );
});

Deno.test("accept: drop below previous*minRatio -> out_of_range", () => {
  const page = "Cash withdrawal via K-ATM: Visa 100 Baht/transaction";
  assertEquals(
    accept(cand(100, "Visa 100 Baht/transaction"), page, 250, ratioOnly),
    { ok: false, reason: "out_of_range" },
  );
});

Deno.test("accept: exactly previous*maxRatio is inside the band -> ok", () => {
  const page = "Cash withdrawal via K-ATM: Visa 500 Baht/transaction";
  const v = accept(
    cand(500, "Visa 500 Baht/transaction"),
    page,
    250,
    ratioOnly,
  );
  assert(v.ok);
});

Deno.test("accept: no previous value, above max -> out_of_range", () => {
  const page = "Cash withdrawal via K-ATM: Visa 1,250 Baht/transaction";
  assertEquals(
    accept(cand(1250, "Visa 1,250 Baht/transaction"), page, null, atmRule),
    { ok: false, reason: "out_of_range" },
  );
});

Deno.test("accept: no previous value, below min -> out_of_range", () => {
  const page = "Cash withdrawal via K-ATM: Visa 20 Baht/transaction";
  assertEquals(
    accept(cand(20, "Visa 20 Baht/transaction"), page, null, atmRule),
    { ok: false, reason: "out_of_range" },
  );
});

Deno.test("accept: within the ratio band but outside min/max -> out_of_range", () => {
  const page = "Cash withdrawal via K-ATM: Visa 1,200 Baht/transaction";
  assertEquals(
    accept(cand(1200, "Visa 1,200 Baht/transaction"), page, 800, atmRule),
    { ok: false, reason: "out_of_range" },
  );
});

Deno.test("accept: a failed verdict carries no value or quote", () => {
  const v = accept(cand(350, VISA_QUOTE), KASIKORN_PAGE, 250, atmRule);
  assertEquals(v.ok, false);
  assertEquals(Object.keys(v).sort(), ["ok", "reason"]);
});
