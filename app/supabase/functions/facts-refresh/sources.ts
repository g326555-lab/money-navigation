// The facts re-checked every day, each with the official or cited page it
// comes from. `ask` tells Gemini what to copy; accept.ts decides.
import type { FactRule } from "./accept.ts";

export type FactSource = {
  key: string;
  url: string;
  kind: "pdf" | "html";
  unit: string;
  rule: FactRule;
  ask: string;
};

const KASIKORN_FEES =
  "https://www.kasikornbank.com/en/rate/fee/feePDF/servicingfees-en-20052026.pdf";

const atmBand = { minRatio: 0.5, maxRatio: 2, min: 50, max: 1000 };

export const SOURCES: FactSource[] = [
  {
    key: "th.atm_fee.kasikorn.visa",
    url: KASIKORN_FEES,
    kind: "pdf",
    unit: "THB",
    rule: { key: "th.atm_fee.kasikorn.visa", ...atmBand },
    ask:
      "the fee in baht per cash withdrawal at K-ATM with an international Visa card",
  },
  {
    key: "th.atm_fee.kasikorn.mastercard",
    url: KASIKORN_FEES,
    kind: "pdf",
    unit: "THB",
    rule: { key: "th.atm_fee.kasikorn.mastercard", ...atmBand },
    ask:
      "the fee in baht per cash withdrawal at K-ATM with an international Mastercard card",
  },
  {
    // Cited in app/assets/data/market_prices.json for mango; updated daily.
    key: "market.mango.checkraka.lowest",
    url: "https://checkraka.app/product/mango/",
    kind: "html",
    unit: "THB/kg",
    rule: {
      key: "market.mango.checkraka.lowest",
      minRatio: 0.3,
      maxRatio: 3,
      min: 10,
      max: 500,
    },
    ask: "today's lowest mango price in baht per kilogram",
  },
];
