// Shared Google Places (New) helpers. Payment facts are passed through
// exactly as Google states them; a missing field stays null, never guessed.

type PaymentOptions = {
  acceptsCreditCards?: boolean;
  acceptsDebitCards?: boolean;
  acceptsCashOnly?: boolean;
  acceptsNfc?: boolean;
};

export function paymentOf(options: PaymentOptions | undefined) {
  if (!options) return { cashOnly: null, cards: null, nfc: null };
  const credit = options.acceptsCreditCards;
  const debit = options.acceptsDebitCards;
  return {
    cashOnly: options.acceptsCashOnly ?? null,
    // True if either card kind is accepted; false only when Google says
    // both are not; null otherwise (one unknown kind is not a "no").
    cards: credit === true || debit === true
      ? true
      : credit === false && debit === false
      ? false
      : null,
    nfc: options.acceptsNfc ?? null,
  };
}

export function validLatLng(lat: unknown, lng: unknown): boolean {
  return typeof lat === "number" && typeof lng === "number" &&
    Number.isFinite(lat) && Number.isFinite(lng) &&
    Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
}

/// A BCP-47 language code such as "en", "th" or "en-US" for place names.
export function validLanguage(code: unknown): code is string {
  return typeof code === "string" && /^[a-z]{2,3}(-[A-Za-z]{2,4})?$/.test(code);
}
