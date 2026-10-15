import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../rules/trip_map.dart';
import 'trip_map_screen.dart' show pinKindColor;

/// Pin images drawn once per screen density: a white-ringed dot in the
/// record's colour (hollow for samples), larger when selected. Until they
/// are ready, markers use Google's default.
class PinIcons {
  final Map<String, BitmapDescriptor> _icons = {};
  double? _ratio;

  Future<void> prepare(double ratio) async {
    if (_ratio == ratio) return;
    _ratio = ratio;
    for (final kind in PinKind.values) {
      for (final sample in [false, true]) {
        for (final selected in [false, true]) {
          _icons[_key(kind, sample, selected)] = await _draw(
            pinKindColor(kind),
            sample: sample,
            size: selected ? AppSizes.mapPinSelected : AppSizes.mapPin,
            ratio: ratio,
          );
        }
      }
    }
  }

  BitmapDescriptor of(
    PinKind kind, {
    required bool sample,
    required bool selected,
  }) => _icons[_key(kind, sample, selected)] ?? BitmapDescriptor.defaultMarker;

  static String _key(PinKind k, bool sample, bool selected) =>
      '${k.name}-$sample-$selected';

  static Future<BitmapDescriptor> _draw(
    Color color, {
    required bool sample,
    required double size,
    required double ratio,
  }) async {
    final px = size * ratio;
    final shadow = AppSizes.mapPinShadow * ratio;
    final canvasSize = px + shadow * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final centre = Offset(canvasSize / 2, canvasSize / 2);
    final radius = px / 2;
    canvas.drawCircle(
      centre.translate(0, shadow / 2),
      radius,
      Paint()
        ..color = AppColors.shadow.withValues(
          alpha: AppColors.mapPinShadowAlpha,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow / 2),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = sample ? color : AppColors.surface,
    );
    canvas.drawCircle(
      centre,
      radius - AppSizes.mapPinRing * ratio,
      Paint()..color = sample ? AppColors.surface : color,
    );
    final image = await recorder.endRecording().toImage(
      canvasSize.ceil(),
      canvasSize.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }
}
