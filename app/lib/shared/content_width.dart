import 'package:flutter/widgets.dart';

import '../core/spacing.dart';

/// Keeps a page's content at a readable phone width on wide screens (the
/// unfolded Fold, tablets); on phones it changes nothing. The page's own
/// background still fills the screen around it.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
