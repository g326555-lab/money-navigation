import 'package:flutter/widgets.dart';

import '../core/motion.dart';

/// A number whose digits roll to a new value one by one, rightmost first,
/// like a trip meter. Separators and units do not move. Tabular figures in
/// [style] keep every digit the same width, so nothing shifts while rolling.
/// With reduce motion the new value simply appears.
class Odometer extends StatelessWidget {
  const Odometer({super.key, required this.text, required this.style});

  /// The formatted value, e.g. "1,286".
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final chars = text.characters.toList();
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var i = 0; i < chars.length; i++)
            _isDigit(chars[i])
                ? _Digit(
                    // Keyed from the right so the ones digit stays the ones
                    // digit when the number grows a place.
                    key: ValueKey(chars.length - i),
                    digit: chars[i],
                    style: style,
                    delay: reduce
                        ? Duration.zero
                        : AppMotion.digitStagger * (chars.length - 1 - i),
                    duration: AppMotion.of(context, AppMotion.digitRoll),
                  )
                : Text(chars[i], style: style),
        ],
      ),
    );
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
}

class _Digit extends StatefulWidget {
  const _Digit({
    super.key,
    required this.digit,
    required this.style,
    required this.delay,
    required this.duration,
  });

  final String digit;
  final TextStyle style;
  final Duration delay;
  final Duration duration;

  @override
  State<_Digit> createState() => _DigitState();
}

class _DigitState extends State<_Digit> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late String _from = widget.digit;
  late String _to = widget.digit;

  @override
  void didUpdateWidget(_Digit old) {
    super.didUpdateWidget(old);
    if (old.digit == widget.digit) return;
    _from = _to;
    _to = widget.digit;
    _controller
      ..duration = widget.duration
      ..value = 0;
    if (widget.duration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = AppMotion.enter.transform(_controller.value);
        if (t >= 1) return Text(_to, style: widget.style);
        // The old digit slides up and out, the new one up and in.
        return ClipRect(
          child: Stack(
            children: [
              Opacity(
                opacity: 1 - t,
                child: FractionalTranslation(
                  translation: Offset(0, -AppMotion.digitTravel * t),
                  child: Text(_from, style: widget.style),
                ),
              ),
              Opacity(
                opacity: t,
                child: FractionalTranslation(
                  translation: Offset(0, AppMotion.digitTravel * (1 - t)),
                  child: Text(_to, style: widget.style),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
