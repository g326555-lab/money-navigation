import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/spacing.dart';

/// A card that rises a little and fades in the first time it scrolls into
/// view, so a long page feels alive without moving anything already seen.
/// With reduce motion it is simply there.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({super.key, required this.child});

  final Widget child;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );
  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
      return;
    }
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  /// Starts once the top of the card is inside the screen; a card built
  /// ahead of time below the fold waits until it is scrolled to.
  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top > MediaQuery.sizeOf(context).height) return;
    _started = true;
    _position?.removeListener(_check);
    _reveal.forward();
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _reveal, curve: AppMotion.enter);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * AppSizes.revealRise),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// [children] of a scrolling page with every card revealed on scroll;
/// spacers are left as they are.
List<Widget> revealOnScroll(List<Widget> children) => [
  for (final c in children)
    if (c is SizedBox) c else RevealOnScroll(child: c),
];
