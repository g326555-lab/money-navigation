import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../core/elevation.dart';
import '../core/motion.dart';
import '../core/spacing.dart';

/// The brand hero object (DESIGN.md "Coin"): a 3D Thai-style bimetal coin,
/// silver outer ring and gold center with the baht sign. One per screen at
/// most. The image already carries its own soft contact shadow.
class Coin extends StatelessWidget {
  const Coin({super.key, this.size = AppSizes.heroCoin});

  static const asset = 'assets/images/coin.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

/// The coin as a physical object: it floats a few pixels over a soft
/// contact shadow, and tilts toward a finger that touches it, springing back
/// on release. Still, with no float, when reduce motion is on.
class LivingCoin extends StatefulWidget {
  const LivingCoin({super.key, this.size = AppSizes.heroCoin});

  final double size;

  @override
  State<LivingCoin> createState() => _LivingCoinState();
}

class _LivingCoinState extends State<LivingCoin> with TickerProviderStateMixin {
  late final _float = AnimationController(
    vsync: this,
    duration: AppMotion.coinFloat,
  );
  late final _tiltX = AnimationController.unbounded(vsync: this);
  late final _tiltY = AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _tiltX.dispose();
    _tiltY.dispose();
    super.dispose();
  }

  void _tiltTo(Offset local) {
    final half = widget.size / 2;
    final dx = ((local.dx - half) / half).clamp(-1.0, 1.0);
    final dy = ((local.dy - half) / half).clamp(-1.0, 1.0);
    _tiltX.value = -dy * AppSizes.coinTiltMax;
    _tiltY.value = dx * AppSizes.coinTiltMax;
  }

  void _release() {
    for (final c in [_tiltX, _tiltY]) {
      c.animateWith(
        SpringSimulation(AppMotion.coinTiltSpring, c.value, 0, c.velocity),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final shadowWidth = size * AppSizes.coinShadowWidth;
    return GestureDetector(
      onPanDown: (d) => _tiltTo(d.localPosition),
      onPanUpdate: (d) => _tiltTo(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _tiltX, _tiltY]),
        builder: (context, _) {
          // 0 at rest, 1 at the top of the float.
          final lift = (1 - math.cos(_float.value * 2 * math.pi)) / 2;
          return SizedBox(
            width: size,
            height: size + AppSizes.coinFloat + AppSizes.coinShadowHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  bottom: 0,
                  child: Transform.scale(
                    // The higher the coin, the smaller and fainter its shadow.
                    scale: 1 - lift * AppSizes.coinShadowShrink,
                    child: Opacity(
                      opacity: 1 - lift * AppSizes.coinShadowFade,
                      child: Container(
                        width: shadowWidth,
                        height: AppSizes.coinShadowHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(
                              shadowWidth / 2,
                              AppSizes.coinShadowHeight / 2,
                            ),
                          ),
                          boxShadow: AppElevation.coinContact,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.coinFloat * (1 - lift),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, AppSizes.coinPerspective)
                      ..rotateX(_tiltX.value)
                      ..rotateY(_tiltY.value),
                    child: Coin(size: size),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A small, once-only celebration: a handful of coins pop up from behind
/// the hero coin and fall back under gravity. Plays when [play] turns true;
/// never with reduce motion.
class CoinBurst extends StatefulWidget {
  const CoinBurst({super.key, required this.play, required this.child});

  final bool play;
  final Widget child;

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(vsync: this, duration: AppMotion.coinPop);

  @override
  void didUpdateWidget(CoinBurst old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play && !MediaQuery.disableAnimationsOf(context)) {
      _t.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            if (!_t.isAnimating) return const SizedBox.shrink();
            final t = _t.value;
            const n = AppMotion.coinPopCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [for (var i = 0; i < n; i++) _coin(i, n, t)],
            );
          },
        ),
        widget.child,
      ],
    );
  }

  /// Coin [i] of [n] at time [t] (0..1): launched up and out on a fan, then
  /// pulled down; fades over the last third.
  Widget _coin(int i, int n, double t) {
    final spread = (i / (n - 1)) * 2 - 1; // -1 .. 1 across the fan
    final angle = spread * AppMotion.coinPopFan;
    // Three speeds in turn, so the fan does not land as one line.
    final speed =
        AppSizes.coinPopSpeed * (1 - AppMotion.coinPopSpeedStep * (i % 3));
    final vx = math.sin(angle) * speed;
    final vy = -math.cos(angle) * speed;
    final x = vx * t;
    final y = vy * t + 0.5 * AppSizes.coinPopGravity * t * t;
    const fadeFrom = AppMotion.coinPopFadeFrom;
    final opacity = t < fadeFrom ? 1.0 : (1 - (t - fadeFrom) / (1 - fadeFrom));
    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: spread * t * math.pi,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const Coin(size: AppSizes.popCoin),
        ),
      ),
    );
  }
}
