import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../rules/ocr_layout.dart';

/// Where the "fit the screen inside" frame sits on a camera view of [view]
/// size. ATM and terminal screens are landscape, so the frame is too.
Rect scanGuideRect(Size view) {
  final width = view.width - AppSpacing.xxl * 2;
  final height = width * AppSizes.scanGuideAspect;
  return Rect.fromCenter(
    center: Offset(view.width / 2, view.height * AppSizes.scanGuideCenterY),
    width: width,
    height: height,
  );
}

/// The part of the camera view the user framed, to keep only the text read
/// inside it.
class ScanRegion {
  const ScanRegion({required this.view, required this.guide});

  /// Size of the camera view on screen (the preview fills it with cover).
  final Size view;
  final Rect guide;

  /// Keeps the lines whose center falls inside the frame, for a photo of
  /// [image] size that was shown with [BoxFit.cover] in [view].
  List<OcrLine> keepInside(List<OcrLine> lines, Size image) => [
    for (final l in lines)
      if (contains(l, image)) l,
  ];

  /// Whether [line]'s center falls inside the frame.
  bool contains(OcrLine line, Size image) {
    final scale = [
      view.width / image.width,
      view.height / image.height,
    ].reduce((a, b) => a > b ? a : b);
    final dx = (view.width - image.width * scale) / 2;
    final dy = (view.height - image.height * scale) / 2;
    // A small margin, so a line touching the frame edge still counts.
    final frame = guide.inflate(AppSpacing.md);
    return frame.contains(
      Offset(
        (line.left + line.right) / 2 * scale + dx,
        (line.top + line.bottom) / 2 * scale + dy,
      ),
    );
  }
}

/// Dims everything outside the frame and draws its corner brackets.
class ScanGuide extends StatelessWidget {
  const ScanGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: constraints.biggest,
          painter: _GuidePainter(scanGuideRect(constraints.biggest)),
        ),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter(this.guide);

  final Rect guide;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      guide,
      const Radius.circular(AppRadius.xl),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(hole),
      Paint()..color = AppColors.cameraOutsideGuide,
    );

    const arm = AppSizes.scanGuideCorner;
    const r = AppRadius.xl;
    final paint = Paint()
      ..color = AppColors.onSurfaceDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.scanGuideStroke
      ..strokeCap = StrokeCap.round;
    final l = guide.left, t = guide.top, rt = guide.right, b = guide.bottom;
    void corner(Offset a, Offset arc0, Offset arc1, Offset c, Offset z) {
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(arc0.dx, arc0.dy)
          ..quadraticBezierTo(c.dx, c.dy, arc1.dx, arc1.dy)
          ..lineTo(z.dx, z.dy),
        paint,
      );
    }

    corner(
      Offset(l, t + arm),
      Offset(l, t + r),
      Offset(l + r, t),
      Offset(l, t),
      Offset(l + arm, t),
    );
    corner(
      Offset(rt - arm, t),
      Offset(rt - r, t),
      Offset(rt, t + r),
      Offset(rt, t),
      Offset(rt, t + arm),
    );
    corner(
      Offset(rt, b - arm),
      Offset(rt, b - r),
      Offset(rt - r, b),
      Offset(rt, b),
      Offset(rt - arm, b),
    );
    corner(
      Offset(l + arm, b),
      Offset(l + r, b),
      Offset(l, b - r),
      Offset(l, b),
      Offset(l, b - arm),
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.guide != guide;
}
