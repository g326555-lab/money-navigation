import '../../rules/atm_conversion.dart';

/// The example on the welcome screen: the printed ATM prop from the demo
/// (prints/, CLAUDE.md "Demo data"), run through the same rule the scanner
/// uses. The screen labels it as an example; it is never a traveler's own
/// result and never saved.
const welcomeExampleAtm = AtmScreenReading(
  withdrawalThb: 4000,
  accessFeeThb: 220,
  thbPerUsd: 30.86,
  markupPercent: 5.50,
  chargedThb: 4220,
  chargedUsd: 144.71,
);

/// Baht the example keeps by declining the conversion (about 246).
double welcomeExampleKeptThb() => evaluateAtm(welcomeExampleAtm).extraCostThb;
