import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/trip_ledger.dart';
import '../../shared/app_tab_bar.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import '../auth/auth_gate.dart' show AuthScope;
import '../home/save_row.dart';
import 'receipt_record_detail.dart';
import '../trip_map/trip_map_screen.dart';
import '../briefing/briefing_controller.dart';

/// Every save on this trip, newest first. Swipe a row left to remove it.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  /// Where these records live: the demo, the account, or only this phone.
  String _footer(BuildContext context, AppLocalizations l10n) {
    final scope = AppScope.of(context);
    final auth = context.getInheritedWidgetOfExactType<AuthScope>();
    final where = scope.settings.demoState
        ? l10n.recordsSavedDemo
        : (auth?.notifier?.isSignedIn ?? false)
        ? l10n.recordsSavedAccount
        : l10n.recordsSavedPhone;
    return '${l10n.recordsSwipeHint} $where';
  }

  /// Saves by local calendar day, newest day first.
  static List<(DateTime, List<TripSave>)> _byDay(List<TripSave> saves) {
    final days = <DateTime, List<TripSave>>{};
    for (final s in saves) {
      final l = s.savedAt.toLocal();
      (days[DateTime(l.year, l.month, l.day)] ??= []).add(s);
    }
    final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final d in keys) (d, days[d]!)];
  }

  /// "Day 2 · Wed, Oct 14", counted from the trip's first day (the first
  /// save's day when no trip dates are set).
  String _dayTitle(
    BuildContext context,
    AppLocalizations l10n,
    DateTime day,
    List<TripSave> saves,
  ) {
    final demo = AppScope.of(context).settings.demoState;
    final first =
        BriefingController.instance.tripPeriod(demo: demo)?.start ??
        _byDay(saves).last.$1;
    final n =
        DateTime.utc(
          day.year,
          day.month,
          day.day,
        ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
        1;
    final date = DateFormat.MMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(day);
    return n >= 1 ? '${l10n.tripDayShort(n)} · $date' : date;
  }

  final _market = MarketPriceRepository();
  Map<String, SourcedItem> _items = const {};

  @override
  void initState() {
    super.initState();
    _market.load().then((items) {
      if (!mounted) return;
      setState(() => _items = {for (final s in items) s.item.key: s});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final trip = AppScope.of(context).trip;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.background,
        child: ListenableBuilder(
          listenable: Listenable.merge([trip, AppScope.of(context).receipts]),
          builder: (context, _) => ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              MediaQuery.paddingOf(context).top + AppSpacing.xl,
              AppSpacing.screenMargin,
              AppTabBar.contentPadding(context),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sectionHeaderInset,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.recordsTitle, style: type.headline),
                    ),
                    // Where each save happened, on a map. Its own node, so a
                    // screen reader reaches it apart from the title.
                    Semantics(
                      container: true,
                      child: Pressable(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TripMapScreen(),
                          ),
                        ),
                        semanticLabel: l10n.tripMapTitle,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSizes.minTouchTarget,
                            minWidth: AppSizes.minTouchTarget,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: AppSizes.buttonIcon,
                                color: AppColors.primaryText,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              ExcludeSemantics(
                                child: Text(
                                  l10n.tripMapTitle,
                                  style: type.link,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.zoneGap),
              if (trip.loaded && trip.saves.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sectionHeaderInset,
                  ),
                  child: Text(
                    l10n.recordsEmpty,
                    style: type.bodyMd.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                )
              else if (trip.saves.isNotEmpty) ...[
                // One group per trip day, newest day first.
                for (final (day, saves) in _byDay(trip.saves)) ...[
                  SectionHeader(_dayTitle(context, l10n, day, trip.saves)),
                  GroupCard(
                    dividerInset: AppSpacing.rowIconTextInset,
                    clip: true,
                    children: [
                      for (final save in saves)
                        Dismissible(
                          key: ValueKey(save.id),
                          direction: DismissDirection.endToStart,
                          background: ColoredBox(
                            color: AppColors.errorContainer,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.groupPaddingH,
                                ),
                                child: Text(
                                  l10n.recordsRemove,
                                  style: type.label.copyWith(
                                    color: AppColors.errorText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onDismissed: (_) async {
                            HapticFeedback.mediumImpact();
                            final messenger = ScaffoldMessenger.of(context);
                            final wallet = AppScope.of(context).cashWallet;
                            trip.remove(save.id);
                            // The cash this record moved goes with it.
                            final cash = await wallet.removeLinked(save.id);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(l10n.recordsRemoved),
                                  action: SnackBarAction(
                                    label: l10n.recordsUndo,
                                    onPressed: () {
                                      trip.add(save);
                                      wallet.restore(cash);
                                    },
                                  ),
                                ),
                              );
                          },
                          child: SaveRow(save: save, items: _items),
                        ),
                    ],
                  ),
                ],
                GroupFooter(_footer(context, l10n)),
              ],
              if (AppScope.of(context).receipts.records.isNotEmpty) ...[
                SectionHeader(l10n.homeRecentReceipts),
                GroupCard(
                  children: [
                    for (final receipt in AppScope.of(context).receipts.records)
                      ReceiptRecordRow(record: receipt),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
