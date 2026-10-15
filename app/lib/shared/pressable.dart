import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/motion.dart';

/// Tap target with a pressed scale and a selection haptic, used instead of
/// Material ripples.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapCancel: () => _setDown(false),
        onTapUp: (_) => _setDown(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? AppMotion.pressedScale : 1,
          duration: AppMotion.of(context, AppMotion.quick),
          curve: AppMotion.move,
          child: widget.child,
        ),
      ),
    );
  }
}
