import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/colors.dart';
import '../core/motion.dart';

/// The success screen's background: green light that drifts slowly, like
/// sun through leaves, so the field feels alive behind the result. Static
/// with reduce motion.
class AuraField extends StatefulWidget {
  const AuraField({super.key});

  @override
  State<AuraField> createState() => _AuraFieldState();
}

class _AuraFieldState extends State<AuraField>
    with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(
    vsync: this,
    duration: AppMotion.auraDrift,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        // easeInOutSine, then three lights moving out of phase.
        final p = (1 - math.cos(_drift.value * math.pi)) / 2;
        final d = AppMotion.auraTravel * 2;
        Alignment at(double dx, double dy) =>
            AppMotion.auraCenter + Alignment(dx * d, dy * d);
        return DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.primary),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _light(at(p - 0.5, 0), AppColors.successCenter, 1),
              _light(at(0.5 - p, 1.2), AppColors.auraLight, 0.8),
              _light(at(-1.4 + p, 2.4), AppColors.auraDeep, 1.1),
            ],
          ),
        );
      },
    );
  }

  Widget _light(Alignment center, Color color, double reach) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: center,
        radius: AppMotion.auraRadius * reach,
        colors: [color, color.withValues(alpha: 0)],
      ),
    ),
  );
}
