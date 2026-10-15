import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/card_catalog.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import 'card_face.dart';

/// Every catalogue card by issuer, the traveler's own currency first.
/// Returns the chosen card.
class CardPickerScreen extends StatelessWidget {
  const CardPickerScreen({
    super.key,
    required this.cards,
    required this.homeCurrency,
    this.selectedId,
  });

  final List<CatalogCard> cards;
  final String homeCurrency;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final byIssuer = <String, List<CatalogCard>>{};
    final ordered = [
      ...cards.where((c) => c.homeCurrency == homeCurrency),
      ...cards.where((c) => c.homeCurrency != homeCurrency),
    ];
    for (final c in ordered) {
      (byIssuer[c.issuer] ??= []).add(c);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                0,
                AppSpacing.screenMargin,
                MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
              ),
              children: [
                Transform.translate(
                  offset: const Offset(
                    -(AppSizes.minTouchTarget - AppSizes.tabIcon) / 2,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.onSurface,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sectionHeaderInset,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(l10n.cardPickerTitle, style: type.headline),
                  ),
                ),
                for (final MapEntry(key: issuer, value: list)
                    in byIssuer.entries) ...[
                  SectionHeader(issuer),
                  GroupCard(
                    dividerInset: AppSpacing.rowIconTextInset,
                    children: [
                      for (final c in list)
                        Pressable(
                          semanticLabel: '${c.issuer} ${c.name}',
                          onPressed: () => Navigator.of(context).pop(c),
                          child: Row(
                            children: [
                              Expanded(
                                child: GroupRow(
                                  leading: SizedBox(
                                    width: AppSizes.cardThumbWidth,
                                    child: CardFace(card: c, compact: true),
                                  ),
                                  title: c.name,
                                  titleStyle: c.id == selectedId
                                      ? type.rowTitle.copyWith(
                                          color: AppColors.primaryText,
                                        )
                                      : null,
                                  subtitle: [
                                    c.homeCurrency,
                                    cardFeeLine(l10n, c),
                                  ].join(' · '),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.lg,
                                ),
                                child: Icon(
                                  c.id == selectedId
                                      ? Icons.check_rounded
                                      : Icons.chevron_right_rounded,
                                  color: c.id == selectedId
                                      ? AppColors.primaryText
                                      : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                GroupFooter(l10n.cardPickerFooter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
