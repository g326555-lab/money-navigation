import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/facts_cache.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../briefing/facts_repository.dart';

/// "Facts checked online": what the daily check read today, each figure with
/// its page and time, and why a figure was kept when the check failed.
class FactsSection extends StatelessWidget {
  const FactsSection({super.key, required this.repository});

  final FactsRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final snapshot = repository.snapshot;
    final facts = repository.facts;
    final summary = snapshot?.summary(DateTime.now());
    final headline = summary == null || summary.checked == 0
        ? l10n.factsNotToday
        : l10n.factsSummary(
            summary.checked,
            summary.updated,
            summary.unchanged,
            summary.kept,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupCard(
          dividerInset: AppSpacing.rowIconTextInset,
          children: [
            GroupRow(
              leading: const IconTile(
                icon: Icons.fact_check_rounded,
                light: AppColors.iconGreenLight,
                dark: AppColors.iconGreen,
              ),
              title: headline,
              subtitle: repository.offline && snapshot != null
                  ? l10n.factsOffline(
                      DateFormat.MMMd(locale).add_Hm().format(snapshot.savedAt),
                    )
                  : null,
            ),
            for (final f in facts)
              if (_name(l10n, f.key) case final name?)
                _FactRow(fact: f, name: name, locale: locale),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.footerGap,
            left: AppSpacing.sectionHeaderInset,
            right: AppSpacing.sectionHeaderInset,
          ),
          child: Text(l10n.factsFooter, style: type.footer),
        ),
      ],
    );
  }

  static String? _name(AppLocalizations l10n, String key) => switch (key) {
    'th.atm_fee.kasikorn.visa' => l10n.factThAtmVisa,
    'th.atm_fee.kasikorn.mastercard' => l10n.factThAtmMastercard,
    'market.mango.checkraka.lowest' => l10n.factMangoLowest,
    _ => null,
  };
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.fact,
    required this.name,
    required this.locale,
  });

  final LiveFact fact;
  final String name;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final status = switch (fact.status) {
      'updated' => l10n.factUpdated,
      'unchanged' => l10n.factUnchanged,
      'kept' when (fact.note ?? '').contains('HTTP 403') =>
        l10n.factKeptBlocked,
      'kept'
          when const {
            'quote_not_in_page',
            'number_not_in_quote',
            'no_quote',
            'no_value',
          }.contains(fact.note) =>
        l10n.factKeptNoMatch,
      'kept' => l10n.factKeptOther,
      _ => l10n.factNew,
    };
    final host = Uri.tryParse(fact.sourceUrl)?.host.replaceFirst('www.', '');
    final when = DateFormat.MMMd(locale).add_Hm().format(fact.checkedAt);
    final unit = fact.unit.replaceFirst('/kg', '');
    final value = AppFormat.amount(fact.value, unit);
    final perKg = fact.unit.endsWith('/kg');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.groupPaddingH,
        vertical: AppSpacing.rowPaddingV,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: AppSizes.rowIconTile + AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: type.rowTitle),
                Text(
                  status,
                  style: type.rowSubtitle.copyWith(
                    color: fact.status == 'kept'
                        ? AppColors.onSurfaceSecondary
                        : AppColors.primaryText,
                  ),
                ),
                if (fact.quote != null && fact.status != 'kept')
                  Text('“${fact.quote}”', style: type.rowSubtitle),
                Text(
                  l10n.factSourceLine(host ?? fact.sourceUrl, when),
                  style: type.footer,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            perKg ? '$value/kg' : value,
            style: type.rowTitle.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
