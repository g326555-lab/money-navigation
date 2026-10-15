import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/spacing.dart';
import '../core/typography.dart';

/// Section header that sits above a group, outside the card.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.first = false,
  });

  final String title;
  final Widget? trailing;

  /// The first header right under a zone boundary skips the top gap,
  /// because the zone gap already provides it.
  final bool first;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sectionHeaderInset,
        first ? 0 : AppSpacing.sectionHeaderTop,
        AppSpacing.sectionHeaderInset,
        AppSpacing.sectionHeaderBottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: type.sectionHeader)),
          ?trailing,
        ],
      ),
    );
  }
}

/// One white group of rows on the grey page. Rows are divided by inset
/// hairlines, never above the first or below the last row.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.dividerInset});

  final List<Widget> children;

  /// Where the hairline starts. Defaults to the text start of a plain row.
  final double? dividerInset;

  @override
  Widget build(BuildContext context) {
    final inset = dividerInset ?? AppSpacing.groupPaddingH;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.groupPaddingV),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.only(left: inset),
                  child: const Divider(
                    height: AppSizes.hairline,
                    thickness: AppSizes.hairline,
                    color: AppColors.divider,
                  ),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A row inside a [GroupCard]: title (and optional subtitle) on the left,
/// value on the right in tabular figures.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.valueStyle,
    this.titleStyle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final TextStyle? valueStyle;

  /// Overrides the title style, e.g. Thai text on an English screen.
  final TextStyle? titleStyle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.groupPaddingH,
          vertical: AppSpacing.rowPaddingV,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle ?? type.rowTitle),
                  if (subtitle != null)
                    Text(subtitle!, style: type.rowSubtitle),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.lg),
              Text(
                value!,
                textAlign: TextAlign.end,
                style: valueStyle ?? type.rowTitle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Source and date line under a group.
class GroupFooter extends StatelessWidget {
  const GroupFooter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sectionHeaderInset,
        AppSpacing.footerGap,
        AppSpacing.sectionHeaderInset,
        0,
      ),
      child: Text(text, style: AppTypography.of(context).footer),
    );
  }
}
