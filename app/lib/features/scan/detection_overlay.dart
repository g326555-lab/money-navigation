import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/motion.dart';
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

  /// 0 to 1, linear. Each box snaps onto its line in turn, top to bottom:
  /// it settles from slightly larger, its outline draws itself around the
  /// text, then the tint fills in.
  final double progress;

  /// Draw-in length for [count] value boxes: each box takes
  /// [AppMotion.emphasized] and starts [AppMotion.boxStagger] of that after
  /// the one above it; the stagger tightens so the whole set stays under
  /// twice the single-box time.
  /// Capped at [AppMotion.boxesMax] so the boxes finish before the verdict
  /// rises over the photo.
  static Duration durationFor(int count) {
    final full = AppMotion.emphasized * _timing(count).total;
    return full < AppMotion.boxesMax ? full : AppMotion.boxesMax;
  }

  /// Values match lines that [DetectionOverlay] will box.
  static int valueCount(List<OcrLine> lines) =>
      lines.where((l) => _valueLine.hasMatch(l.text)).length;

  /// Box timeline in units of one box's draw-in.
  static ({double stagger, double total}) _timing(int count) {
    if (count <= 1) return (stagger: 0, total: 1);
    final stagger = AppMotion.boxStagger < 1 / (count - 1)
        ? AppMotion.boxStagger
        : 1 / (count - 1);
    return (stagger: stagger, total: 1 + stagger * (count - 1));
  }

  static final _valueLine = RegExp('($amountPattern) ?(THB|USD|JPY|%)');

  @override
  Widget build(BuildContext context) {
    final values = lines.where((l) => _valueLine.hasMatch(l.text)).toList()
      ..sort((a, b) => a.top.compareTo(b.top));
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

  /// Extra margin a box starts with before it settles onto the text.
  static const _approach = AppSpacing.md;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || progress <= 0 || lines.isEmpty) return;
    final scale = [
      size.width / imageSize.width,
      size.height / imageSize.height,
    ].reduce((a, b) => a < b ? a : b);
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    final timing = DetectionOverlay._timing(lines.length);
    for (var i = 0; i < lines.length; i++) {
      final t = ((progress * timing.total - timing.stagger * i)).clamp(
        0.0,
        1.0,
      );
      if (t == 0) continue;
      final snap = AppMotion.settle.transform(t);
      final draw = AppMotion.enter.transform(t);

      final l = lines[i];
      final pad = AppSpacing.xs + _approach * (1 - snap);
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

      final fill = Paint()
        ..color = AppColors.detectionFill.withValues(
          alpha: AppColors.detectionFill.a * draw,
        );
      canvas.drawRRect(rrect, fill);

      final stroke = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.detectionStroke
        ..strokeCap = StrokeCap.round;
      final outline = Path()..addRRect(rrect);
      if (draw >= 1) {
        canvas.drawPath(outline, stroke);
      } else {
        for (final metric in outline.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * draw), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DetectionPainter old) =>
      old.lines != lines ||
      old.imageSize != imageSize ||
      old.progress != progress;
}
