import 'dart:convert';
import 'dart:ui';

import '../../core/colors.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A quiet grey Google Maps style built from DESIGN.md colours: land on the
/// page grey, roads white, water a shade darker, labels muted, businesses
/// and transit icons hidden, so the trip's own pins carry the colour.
/// Applied locally (no cloud map ID).
///
/// Label language follows the phone (the Maps SDKs have no language
/// option), so the style keeps only the labels that orient: neighbourhoods
/// and roads. City, place, park and province names are hidden; Google's logo and
/// legal text are not part of the style and always stay.
final String tripMapStyle = jsonEncode([
  _rule('geometry', color: AppColors.background),
  _rule('labels.icon', visibility: 'off'),
  _rule('labels.text.fill', color: AppColors.onSurfaceTertiary),
  _rule('labels.text.stroke', color: AppColors.surface),
  _rule('geometry', feature: 'poi', color: AppColors.surfaceSunken),
  _rule('all', feature: 'poi.business', visibility: 'off'),
  _rule('labels', feature: 'poi', visibility: 'off'),
  _rule('labels', feature: 'administrative.locality', visibility: 'off'),
  _rule('labels', feature: 'administrative.province', visibility: 'off'),
  _rule('labels', feature: 'administrative.land_parcel', visibility: 'off'),
  _rule('labels', feature: 'road.local', visibility: 'off'),
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
