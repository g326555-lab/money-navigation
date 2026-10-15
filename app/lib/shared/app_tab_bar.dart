import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colors.dart';
import '../core/elevation.dart';
import '../core/motion.dart';
import '../core/spacing.dart';
import '../core/typography.dart';
import 'surface.dart';

class AppTab {
  const AppTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Floating glass tab bar (DESIGN.md "Components"). Place it in a Stack or as
/// `Scaffold.bottomNavigationBar` with `extendBody: true`; content scrolls
/// under it. Use [AppTabBar.contentPadding] for the scroll view's bottom.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<AppTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Bottom padding a scroll view needs so its last item clears the bar.
  static double contentPadding(BuildContext context) =>
      AppSizes.tabBarHeight +
      AppSizes.tabBarInsetBottom +
      MediaQuery.paddingOf(context).bottom +
      AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.tabBarHeight / 2);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.tabBarInsetH,
          0,
          AppSizes.tabBarInsetH,
          AppSizes.tabBarInsetBottom,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.tabBarMaxWidth,
            ),
            child: Surface(
              radius: AppSizes.tabBarHeight / 2,
              shadows: AppElevation.e2,
              edgeLight: EdgeLights.onGlass,
              clip: true,
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  outer: const ColorFilter.matrix(AppColors.glassSaturate),
                  inner: ImageFilter.blur(
                    sigmaX: AppSizes.tabBlur,
                    sigmaY: AppSizes.tabBlur,
                  ),
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColors.glassFill,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: radius,
                      side: const BorderSide(
                        color: AppColors.glassBorder,
                        width: AppSizes.hairline,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: AppSizes.tabBarHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) => _Tabs(
                        width: constraints.maxWidth,
                        tabs: tabs,
                        selected: selected,
                        onSelected: onSelected,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.width,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final double width;
  final List<AppTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final inset = (AppSizes.tabBarHeight - AppSizes.tabIndicatorHeight) / 2;
    final slot = (width - inset * 2) / tabs.length;
    return Stack(
      children: [
        AnimatedPositioned(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.enter,
          left: inset + slot * selected,
          top: inset,
          width: slot,
          height: AppSizes.tabIndicatorHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.tabIndicator,
              borderRadius: BorderRadius.circular(
                AppSizes.tabIndicatorHeight / 2,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    tab: tabs[i],
                    active: i == selected,
                    labelStyle: type.tabLabel,
                    onTap: () {
                      if (i == selected) return;
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.active,
    required this.labelStyle,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.onSurface : AppColors.onSurfaceTertiary;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              child: Icon(
                active ? tab.activeIcon : tab.icon,
                key: ValueKey(active),
                size: AppSizes.tabIcon,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            AnimatedDefaultTextStyle(
              duration: AppMotion.of(context, AppMotion.quick),
              style: labelStyle.copyWith(color: color),
              child: Text(tab.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
