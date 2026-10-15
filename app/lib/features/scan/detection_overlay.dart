import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../rules/amount_parser.dart';
import '../../rules/ocr_layout.dart';

/// Draws a box around every line OCR actually read as an amount, on top of
/// a photo shown with [BoxFit.contain].
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.lines,
    required this.imageSize,
    required this.progress,
  });

  final List<OcrLine> lines;
  final Size imageSize;

  /// 0 to 1; boxes grow in as recognition results arrive.
  final double progress;

  static final _valueLine = RegExp('($amountPattern) ?(THB|USD|JPY|%)');

  @override
  Widget build(BuildContext context) {
    final values = lines.where((l) => _valueLine.hasMatch(l.text)).toList();
    return CustomPaint(
      size: Size.infinite,
      painter: _DetectionPainter(values, imageSize, progress),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter(this.lines, this.imageSize, this.progress);

  final List<OcrLine> lines;
  final Size imageSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || progress <= 0) return;
    final scale = [
      size.width / imageSize.width,
      size.height / imageSize.height,
    ].reduce((a, b) => a < b ? a : b);
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;
    final pad = AppSpacing.xs * progress;

    final stroke = Paint()
      ..color = AppColors.primary.withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.detectionStroke;
    final fill = Paint()
      ..color = AppColors.detectionFill.withValues(
        alpha: AppColors.detectionFill.a * progress,
      );

    for (final l in lines) {
      final rect = Rect.fromLTRB(
        l.left * scale + dx - pad,
        l.top * scale + dy - pad,
        l.right * scale + dx + pad,
        l.bottom * scale + dy + pad,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AppRadius.sm),
      );
      canvas
        ..drawRRect(rrect, fill)
        ..drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(_DetectionPainter old) =>
      old.lines != lines ||
      old.imageSize != imageSize ||
      old.progress != progress;
}
