import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/app_tab_bar.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import '../auth/auth_gate.dart' show AuthScope;
import '../home/save_row.dart';
import '../trip_map/trip_map_screen.dart';

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
          listenable: trip,
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
                GroupCard(
                  dividerInset: AppSpacing.rowIconTextInset,
                  clip: true,
                  children: [
                    for (final save in trip.saves)
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
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          trip.remove(save.id);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(l10n.recordsRemoved),
                                action: SnackBarAction(
                                  label: l10n.recordsUndo,
                                  onPressed: () => trip.add(save),
                                ),
                              ),
                            );
                        },
                        child: SaveRow(save: save, items: _items),
                      ),
                  ],
                ),
                GroupFooter(_footer(context, l10n)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
