import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/spacing.dart';

/// Pinned action area at the bottom of a full-screen flow. Content scrolls
/// under it; a hairline on top separates it from the content.
class ActionDock extends StatelessWidget {
  const ActionDock({super.key, required this.child});

  final Widget child;

  static double _bottomPadding(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AppSpacing.md + (bottom > 0 ? bottom : AppSpacing.sm);
  }

  /// Height of a dock holding one primary button, for the bottom padding of
  /// the content that scrolls under it.
  static double heightOf(BuildContext context) =>
      AppSpacing.md + AppSizes.buttonHeight + _bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.dockBlur,
          sigmaY: AppSizes.dockBlur,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.dockFill,
            border: Border(
              top: BorderSide(
                color: AppColors.divider,
                width: AppSizes.hairline,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.md,
              AppSpacing.screenMargin,
              _bottomPadding(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
