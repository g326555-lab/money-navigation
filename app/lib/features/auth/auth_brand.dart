import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../shared/pressable.dart';

/// Values that Apple and Google fix for their sign-in buttons. They are the
/// one place the app shows another company's mark, and both companies
/// require their own colours and artwork, so these do not come from
/// DESIGN.md tokens.
///
/// Google: https://developers.google.com/identity/branding-guidelines
/// (light theme: fill #FFFFFF, 1 px stroke #747775, text #1F1F1F, the
/// standard four-colour G, medium weight).
/// Apple: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
/// (black button, Apple's own logo, no smaller than other sign-in buttons;
/// drawn by the sign_in_with_apple package).
abstract final class ProviderBrand {
  static const googleFill = Color(0xFFFFFFFF);
  static const googleStroke = Color(0xFF747775);
  static const googleText = Color(0xFF1F1F1F);
  static const googleStrokeWidth = 1.0;
  static const googleTextWeight = 500;

  /// Google's disabled light button: fill #FFFFFF at 38 %, stroke #1F1F1F
  /// at 12 %, text and logo at 38 %. Apple publishes no disabled style, so
  /// its button fades by the same 38 %.
  static const googleDisabledFill = Color(0x61FFFFFF);
  static const googleDisabledStroke = Color(0x1F1F1F1F);
  static const googleDisabledContent = 0.38;

  /// The G is drawn at the size Google's 40 high button uses, scaled to our
  /// button height.
  static const googleLogoRatio = 20 / 40;
  static const googleLogoGap = 12.0;

  // The four colours of the G, from Google's published g-logo.svg.
  static const gRed = Color(0xFFEA4335);
  static const gBlue = Color(0xFF4285F4);
  static const gYellow = Color(0xFFFBBC05);
  static const gGreen = Color(0xFF34A853);
}

/// "Continue with Apple", black, at the height and corner of our buttons so
/// it is never smaller than the other choices. Disabled (another way in is
/// working) fades it like the Google button; [busy] keeps it as it is.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || busy;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : ProviderBrand.googleDisabledContent,
        // The package draws a plain rounded rectangle; clip it to the app's
        // superellipse so every button shares one corner shape.
        child: ClipRSuperellipse(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          child: IgnorePointer(
            ignoring: onPressed == null,
            child: SignInWithAppleButton(
              text: label,
              height: AppSizes.buttonHeight,
              style: SignInWithAppleButtonStyle.black,
              borderRadius: BorderRadius.zero,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continue with Google" in Google's light theme.
///
/// Disabled (another way in is working) uses Google's disabled colours;
/// [busy] (this way in is working) keeps the enabled look and ignores taps.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || busy;
    final style = AppTypography.of(context).bodyLg.copyWith(
      color: enabled
          ? ProviderBrand.googleText
          : ProviderBrand.googleText.withValues(
              alpha: ProviderBrand.googleDisabledContent,
            ),
      fontWeight: FontWeight(ProviderBrand.googleTextWeight),
      fontVariations: [
        FontVariation.weight(ProviderBrand.googleTextWeight.toDouble()),
      ],
    );
    const logo = AppSizes.buttonHeight * ProviderBrand.googleLogoRatio;
    // Whole device pixels, so every straight edge covers the same number
    // of pixels (2.6 px would land on 2 at one edge and 3 at the other).
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final strokeWidth =
        math.max(1, (ProviderBrand.googleStrokeWidth * dpr).round()) / dpr;
    return Pressable(
      onPressed: busy ? null : onPressed,
      semanticLabel: label,
      haptic: HapticFeedback.lightImpact,
      child: CustomPaint(
        painter: _OutlinedSuperellipse(
          radius: AppRadius.md,
          fill: enabled
              ? ProviderBrand.googleFill
              : ProviderBrand.googleDisabledFill,
          stroke: enabled
              ? ProviderBrand.googleStroke
              : ProviderBrand.googleDisabledStroke,
          strokeWidth: strokeWidth,
        ),
        child: SizedBox(
          height: AppSizes.buttonHeight,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.buttonPaddingH,
            ),
            // The button's own label is the semantics; skip the text copy.
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: enabled ? 1 : ProviderBrand.googleDisabledContent,
                    child: const SizedBox.square(
                      dimension: logo,
                      child: CustomPaint(painter: GoogleLogoPainter()),
                    ),
                  ),
                  const SizedBox(width: ProviderBrand.googleLogoGap),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1, style: style),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled superellipse with a hairline outline drawn as a ring: the area
/// between the outer shape and a concentric inner one (inset by the stroke,
/// radius reduced by the same amount). A stroked path is widened along its
/// normals, so on the tight corner curve it covers more pixels than on the
/// straight edges and the corners read heavier; the ring keeps one width
/// all the way round.
class _OutlinedSuperellipse extends CustomPainter {
  const _OutlinedSuperellipse({
    required this.radius,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final double radius;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RSuperellipse.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final inner = RSuperellipse.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth),
      Radius.circular(radius - strokeWidth),
    );
    // Both fills go through Path so they share one tessellation of the
    // inner edge; drawRSuperellipse tessellates differently and leaves a
    // one-pixel seam of page colour along the long edges.
    canvas.drawPath(Path()..addRSuperellipse(inner), Paint()..color = fill);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRSuperellipse(outer)
      ..addRSuperellipse(inner);
    canvas.drawPath(ring, Paint()..color = stroke);
  }

  @override
  bool shouldRepaint(_OutlinedSuperellipse old) =>
      old.radius != radius ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth;
}

/// Google's standard G, painted from the paths of its published
/// g-logo.svg (48 x 48 view box), so no image asset is needed.
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  static const _viewBox = 48.0;
  static const _parts = <(Color, String)>[
    (
      ProviderBrand.gRed,
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
          '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ),
    (
      ProviderBrand.gBlue,
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
          '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
    (
      ProviderBrand.gYellow,
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 '
          '16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
    (
      ProviderBrand.gGreen,
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
          '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
    ),
  ];

  static final _paths = [for (final (_, d) in _parts) parseSvgPath(d)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox, size.height / _viewBox);
    final paint = Paint()..isAntiAlias = true;
    for (var i = 0; i < _parts.length; i++) {
      canvas.drawPath(_paths[i], paint..color = _parts[i].$1);
    }
  }

  @override
  bool shouldRepaint(GoogleLogoPainter oldDelegate) => false;
}

/// A small SVG path reader for the commands the G uses (M, L, H, V, C, S, Z
/// in both absolute and relative form).
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var command = '';
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  double? lastC2x, lastC2y;
  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (isCommand(tokens[i])) command = tokens[i++];
    final rel = command == command.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Further pairs after a move are line-tos.
        command = rel ? 'l' : 'L';
        lastC2x = null;
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
        lastC2x = null;
      case 'H':
        x = ox + next();
        path.lineTo(x, y);
        lastC2x = null;
      case 'V':
        y = oy + next();
        path.lineTo(x, y);
        lastC2x = null;
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastC2x = x2;
        lastC2y = y2;
      case 'S':
        final x1 = lastC2x == null ? x : 2 * x - lastC2x;
        final y1 = lastC2y == null || lastC2x == null ? y : 2 * y - lastC2y;
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastC2x = x2;
        lastC2y = y2;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastC2x = null;
      default:
        throw FormatException('Unsupported path command $command');
    }
  }
  return path;
}
