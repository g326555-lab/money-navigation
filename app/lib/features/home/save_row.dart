import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_ledger.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import '../records/save_detail_screen.dart';

/// One saved result as a row: what it was, when, and what it kept.
class SaveRow extends StatelessWidget {
  const SaveRow({super.key, required this.save, required this.items});

  final TripSave save;

  /// Market items by key, to name a haggle in the reader's language.
  final Map<String, SourcedItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final type = AppTypography.of(context);
    final date = DateFormat.MMMd(locale)
        .add_Hm()
        .format(save.savedAt.toLocal());
    // A demo sample says so wherever it is listed.
    final when = save.isSample ? l10n.saveSampleWhen(date) : date;
    final kept = l10n.saveKeptValue(
      AppFormat.roundedAmount(save.keptThb, marketCurrency),
    );
    final row = switch (save.kind) {
      SaveKind.atmConversion => GroupRow(
        leading: const IconTile.blue(icon: Icons.atm_rounded),
        title: l10n.saveAtmTitle,
        subtitle: when,
        value: kept,
        valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
      ),
      SaveKind.terminalDcc => GroupRow(
        leading: const IconTile.blue(icon: Icons.credit_card_rounded),
        title: l10n.saveTerminalTitle,
        subtitle: when,
        value: kept,
        valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
      ),
      SaveKind.haggle => GroupRow(
        leading: const IconTile.orange(icon: Icons.storefront_rounded),
        title: l10n.saveHaggleTitle(_itemName(context)),
        subtitle: l10n.saveHaggleSubtitle(
          AppFormat.roundedAmount(save.paidThb ?? 0, marketCurrency),
          when,
        ),
        value: kept,
        valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
      ),
    };
    return Pressable(
      semanticLabel: '${row.title} · $when · $kept',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              SaveDetailScreen(save: save, itemName: _itemName(context)),
        ),
      ),
      child: row,
    );
  }

  String _itemName(BuildContext context) {
    // An item outside the price list keeps the name the seller used.
    const newPrefix = 'new:';
    final key = save.itemKey;
    if (key != null && key.startsWith(newPrefix)) {
      return key.substring(newPrefix.length);
    }
    final item = items[save.itemKey]?.item;
    if (item == null) return AppLocalizations.of(context).saveHaggleUnknownItem;
    return Localizations.localeOf(context).languageCode == 'th'
        ? item.nameTh
        : item.nameEn;
  }
}
