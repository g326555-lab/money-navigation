import '../../core/spacing.dart';

/// Sizes only Home and the Assistant tab use. Built from the shared tokens
/// where one fits; candidates for lib/core once the screens settle.
abstract final class HomeMetrics {
  /// Route line: dot diameter, white ring, stroke and the row it sits in.
  static const double routeDot = 16;
  static const double routeDotRing = 3;
  static const double routeStroke = 4;
  static const double routeDotRow = AppSizes.minTouchTarget / 2;

  /// A new stop redraws only the last stretch of the line.
  static const double routeRedrawFrom = 0.7;

  /// Share of one step over which a newly reached route dot settles to full
  /// size.
  static const double routeDotSettleSpan = 0.35;

  /// Stops Home draws: three on a narrow screen, four from this width.
  static const double routeWideFrom = 400;
  static const int routeStopsNarrow = 3;
  static const int routeStopsWide = 4;

  /// Briefing: the column holding event times.
  static const double timeColumn = 52;

  /// Today's events listed on Home before "Open assistant".
  static const int homeEvents = 3;

  /// Sheet grabber, DESIGN.md "Bottom sheet": 36 x 4.
  static const double grabberWidth = 36;
  static const double grabberHeight = 4;

  /// Warnings Home shows; the Assistant lists all.
  static const int homeWarnings = 1;
}
