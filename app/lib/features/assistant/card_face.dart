import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/card_catalog.dart';
import '../../shared/surface.dart';

/// A plain drawing of a card's front: its colour, issuer, product name and
/// network written out. No issuer or network logo is reproduced.
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.compact = false});

  final CatalogCard card;

  /// The small version for list rows: colour and network only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final ink = card.faceTextLight
        ? AppColors.onSurfaceDark
        : AppColors.onSurface;
    final face = Color(card.faceColor);
    return AspectRatio(
      aspectRatio: AppSizes.cardAspect,
      child: Surface(
        radius: compact ? AppSizes.cardThumbRadius : AppRadius.lg,
        color: face,
        shadows: compact ? AppElevation.e0 : AppElevation.e1,
        padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.lg),
        child: compact
            ? Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  child: Text(
                    card.network.toUpperCase(),
                    style: type.tabLabel.copyWith(color: ink),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.issuer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.label.copyWith(color: ink),
                  ),
                  const Spacer(),
                  Text(
                    card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.title.copyWith(color: ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.kind.toUpperCase(),
                          style: type.caption.copyWith(color: ink),
                        ),
                      ),
                      Text(
                        card.network.toUpperCase(),
                        style: type.bodyLg.copyWith(color: ink),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// "Foreign purchases: up to 3%" from the card's stated fees.
String cardFeeLine(AppLocalizations l10n, CatalogCard card) {
  final fee = cardForeignFee(card);
  if (fee == null) return l10n.cardForeignFeeNone;
  final percent = AppFormat.percent(fee.percent);
  return fee.upTo
      ? l10n.cardForeignFeeUpTo(percent)
      : l10n.cardForeignFeeValue(percent);
}

/// "Card terms · checked Oct 16" for each official source.
String cardSourceLine(
  BuildContext context,
  AppLocalizations l10n,
  CardSource source,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return l10n.cardSourceChecked(
    source.label,
    DateFormat.MMMd(locale).format(DateTime.parse(source.checked)),
  );
}
