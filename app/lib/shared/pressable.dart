import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import 'surface.dart';

/// Tap target that sinks when pressed: it scales down fast, any [Surface]
/// inside tightens its shadow, and on release it springs back from wherever
/// it was. Used instead of Material ripples.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.scale = AppMotion.pressedScale,
    this.haptic = HapticFeedback.selectionClick,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  /// Scale when fully pressed.
  final double scale;

  /// Played when a tap is confirmed.
  final Future<void> Function() haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final _depth = AnimationController.unbounded(vsync: this);

  void _down() {
    _depth.animateTo(
      1,
      duration: AppMotion.of(context, AppMotion.pressIn),
      curve: AppMotion.enter,
    );
  }

  void _up() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _depth.value = 0;
      return;
    }
    _depth.animateWith(
      SpringSimulation(
        AppMotion.pressRelease,
        _depth.value,
        0,
        _depth.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      // Its own node, so TalkBack / VoiceOver find this control instead of
      // merging it into the row around it.
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _down() : null,
        onTapCancel: _up,
        onTapUp: (_) => _up(),
        onTap: enabled
            ? () {
                widget.haptic();
                widget.onPressed!();
              }
            : null,
        child: PressDepth(
          depth: _depth,
          child: AnimatedBuilder(
            animation: _depth,
            builder: (context, child) => Transform.scale(
              scale: 1 - (1 - widget.scale) * _depth.value,
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
