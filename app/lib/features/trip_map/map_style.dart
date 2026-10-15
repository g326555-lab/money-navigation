import 'dart:convert';
import 'dart:ui';

import '../../core/colors.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A quiet grey Google Maps style built from DESIGN.md colours: land on the
/// page grey, roads white, water a shade darker, labels muted, businesses
/// and transit icons hidden, so the trip's own pins carry the colour.
/// Applied locally (no cloud map ID).
final String tripMapStyle = jsonEncode([
  _rule('geometry', color: AppColors.background),
  _rule('labels.icon', visibility: 'off'),
  _rule('labels.text.fill', color: AppColors.onSurfaceTertiary),
  _rule('labels.text.stroke', color: AppColors.surface),
  _rule('geometry', feature: 'poi', color: AppColors.surfaceSunken),
  _rule('all', feature: 'poi.business', visibility: 'off'),
  _rule('geometry', feature: 'poi.park', color: AppColors.surfaceDim),
  _rule('geometry', feature: 'road', color: AppColors.surface),
  _rule('geometry.stroke', feature: 'road', color: AppColors.divider),
  _rule('geometry', feature: 'road.highway', color: AppColors.surface),
  _rule('all', feature: 'transit', visibility: 'off'),
  _rule('geometry', feature: 'water', color: AppColors.surfaceDim),
  _rule(
    'labels.text.fill',
    feature: 'water',
    color: AppColors.onSurfaceTertiary,
  ),
]);

Map<String, Object> _rule(
  String element, {
  String? feature,
  Color? color,
  String? visibility,
}) => {
  'featureType': ?feature,
  'elementType': element,
  'stylers': [
    if (color != null) {'color': _hex(color)},
    if (visibility != null) {'visibility': visibility},
  ],
};
