import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/spacing.dart';

/// A raised object arriving on a hero moment: it rises a little, grows to
/// full size and settles on a spring with a slight overshoot, after
/// [delay]. Only for the one landing per screen; with reduce motion it is
/// simply there.
class LandIn extends StatefulWidget {
  const LandIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<LandIn> createState() => _LandInState();
}

class _LandInState extends State<LandIn> with SingleTickerProviderStateMixin {
  late final _land = AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _land.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _land.animateWith(SpringSimulation(AppMotion.landSpring, 0, 1, 0));
    });
  }

  @override
  void dispose() {
    _land.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _land,
      builder: (context, child) {
        final t = _land.value;
        return Opacity(
          // Opacity is an effect: it never overshoots.
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * AppSizes.landRise),
            child: Transform.scale(
              scale: lerpDouble(AppMotion.landFromScale, 1, t),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
