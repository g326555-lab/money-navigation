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
    // both are not; null when it says nothing about cards.
    cards: credit === true || debit === true
      ? true
      : credit === false && (debit === false || debit === undefined) ||
          debit === false && credit === undefined
      ? false
      : null,
    nfc: options.acceptsNfc ?? null,
  };
}
