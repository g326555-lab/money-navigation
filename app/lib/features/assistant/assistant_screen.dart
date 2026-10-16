import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/arrival_alert.dart';
import '../../rules/day_cash.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/nearby_traps.dart';
import '../../rules/pay_route.dart';
import '../../rules/personal_context.dart';
import '../../shared/app_button.dart';
import '../../shared/app_tab_bar.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import '../briefing/arrival_alerts.dart';
import '../briefing/briefing_controller.dart';
import '../briefing/briefing_rows.dart';
import '../briefing/calendar_source.dart';
import '../briefing/trip_context.dart';
import '../briefing/trip_dates.dart';
import '../../data/card_catalog_repository.dart';
import '../../rules/card_catalog.dart';
import '../../data/market_price_repository.dart';
import '../home/save_row.dart';
import '../records/receipt_record_detail.dart';
import 'card_face.dart';
import 'card_facts_sheet.dart';
import 'facts_section.dart';
import '../home/cash_balance_card.dart';
import 'pay_compare_card.dart';
import '../trip_map/atm_map_screen.dart';

/// The demo state's arrival: the Thai traveler lands in Japan.
const demoArrivalCountry = 'JP';

/// The assistant: today's cash and stops, which way to pay, traps nearby,
/// the card facts behind the numbers and the arrival alert.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.briefing, this.alerts});

  final BriefingController? briefing;
  final ArrivalAlerts? alerts;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  BriefingController get _briefing =>
      widget.briefing ?? BriefingController.instance;
  ArrivalAlerts get _alerts => widget.alerts ?? ArrivalAlerts.instance;

  /// The stop the comparison is for; null compares for an unknown place.
  String? _selected;

  static String _key(StopCash s) =>
      '${s.event.start.toIso8601String()}|${s.event.title}|${s.event.location}';

  final _catalog = CardCatalogRepository();
  List<CatalogCard> _cards = const [];
  final _market = MarketPriceRepository();
  Map<String, SourcedItem> _items = const {};

  @override
  void initState() {
    super.initState();
    _briefing.start();
    _catalog.load().then((cards) {
      if (mounted) setState(() => _cards = cards);
    });
    _market.load().then((items) {
      if (mounted) {
        setState(() => _items = {for (final s in items) s.item.key: s});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        _briefing,
        _briefing.card,
        _alerts,
        scope.trip,
        scope.receipts,
        scope.cashWallet,
        scope.settings,
        scope.rates,
      ]),
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    _briefing.markDemo(scope.settings.demoState);
    final demoKey = scope.settings.demoPersona?.key;
    if (demoKey != _briefing.demoKey) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _briefing.useDemo(
          demoKey,
          currency: scope.settings.demoPersona?.localCurrency,
        ),
      );
    }
    final trip = TripContext.of(
      scope,
      // The demo state keeps the facts it shipped with.
      scope.settings.demoState ? _briefing.bundledFacts : _briefing.facts,
    );
    final plan = _briefing.cashPlan(
      trip.history,
      demo: scope.settings.demoState,
    );
    final profile = _briefing.card.profile;
    final traps = _briefing.traps(
      countryCode: _briefing.country,
      demo: scope.settings.demoState,
      homeCurrency: trip.homeCurrency,
    );
    final selected = plan?.stops.where((s) => _key(s) == _selected).firstOrNull;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.background,
        child: RefreshIndicator(
          color: AppColors.onSurface,
          onRefresh: () => _briefing.refresh(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              MediaQuery.viewPaddingOf(context).top + AppSpacing.lg,
              AppSpacing.screenMargin,
              AppTabBar.contentPadding(context),
            ),
            children: [
              Text(l10n.assistantTitle, style: type.headline),
              Text(
                DateFormat.MMMMEEEEd(locale).format(DateTime.now()),
                style: type.heroLabel.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CashBalanceCard(
                wallet: scope.cashWallet,
                currency: trip.localCurrency,
                foreignCurrency: trip.homeCurrency,
                onFindNearby: () => _openAtmMap(),
                demo: scope.settings.demoState,
                prominent: true,
              ),
              const SizedBox(height: AppSpacing.zoneGap),
              SectionHeader(_stopsTitle(l10n, demo: scope.settings.demoState)),
              ?_tripStrip(demo: scope.settings.demoState),
              // A past trip day: what was really recorded that day. The
              // demo's sample calendar has no past days to show.
              if (!(scope.settings.demoState &&
                  _isPast(scope.settings.demoState)))
                _stops(l10n, plan, selected, demo: scope.settings.demoState),
              if (_isPast(scope.settings.demoState))
                ..._pastDay(l10n, scope, demo: scope.settings.demoState),
              // The demo's stops come from its sample calendar, never the
              // phone's.
              if (scope.settings.demoState) GroupFooter(l10n.calendarSample),
              const SizedBox(height: AppSpacing.zoneGap),
              PayCompareCard(
                trip: trip,
                profile: profile,
                withdrawalThb: plan?.amountThb,
                place: selected?.event.payment ?? PlacePayment.unknown,
                onEditCard: () => _editCard(trip),
              ),
              if (selected != null)
                GroupFooter(
                  l10n.assistantPayFor(
                    selected.event.matchedPlace ?? selected.event.location!,
                  ),
                ),
              SectionHeader(l10n.assistantCard),
              _cardGroup(l10n, profile, trip),
              GroupFooter(
                _briefing.card.feeFromAccount
                    ? l10n.assistantCardFromAccount
                    : l10n.assistantCardFooter,
              ),
              SectionHeader(
                l10n.assistantNearby,
                trailing: Pressable(
                  onPressed: _openAtmMap,
                  semanticLabel: l10n.nearbyMapLabel,
                  child: Text(
                    l10n.nearbyMapLabel,
                    style: type.link.copyWith(color: AppColors.primaryText),
                  ),
                ),
              ),
              _nearby(l10n, traps, demo: scope.settings.demoState),
              SectionHeader(l10n.assistantArrival),
              _arrival(l10n, scope, trip),
              SectionHeader(l10n.assistantFacts),
              FactsSection(repository: _briefing.live),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stops(
    AppLocalizations l10n,
    DayCashPlan? plan,
    StopCash? selected, {
    required bool demo,
  }) {
    final access = demo ? CalendarAccess.granted : _briefing.calendar.access;
    if (access != CalendarAccess.granted) {
      return GroupCard(
        children: [
          _ActionRow(
            icon: const IconTile.blue(icon: Icons.event_rounded),
            title: access == CalendarAccess.denied
                ? l10n.calendarDenied
                : l10n.calendarConnect,
            subtitle: l10n.calendarPrivacy,
            onPressed: access == CalendarAccess.denied
                ? AppSettings.openAppSettings
                : _connectCalendar,
          ),
        ],
      );
    }
    final stops = plan?.stops ?? const <StopCash>[];
    if (stops.isEmpty) {
      return GroupCard(
        children: [
          GroupRow(
            leading: const IconTile.blue(icon: Icons.event_available_rounded),
            title: _briefing.eventsLoading
                ? l10n.calendarReading
                : _noStops(l10n, demo: demo),
            subtitle: l10n.calendarPrivacy,
          ),
        ],
      );
    }
    return GroupCard(
      children: [
        for (final s in stops)
          Pressable(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = s == selected ? null : _key(s));
            },
            semanticLabel: l10n.assistantPayFor(
              s.event.matchedPlace ?? s.event.location!,
            ),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.quick),
              curve: AppMotion.enter,
              color: s == selected
                  ? AppColors.surfaceSunken
                  : AppColors.surface,
              child: StopRow(stop: s),
            ),
          ),
      ],
    );
  }

  Widget _cardGroup(
    AppLocalizations l10n,
    TravelerProfile profile,
    TripContext trip,
  ) {
    final fee = profile.cardFeePercent;
    final value = profile.atmFeeValue;
    final atm = switch (profile.atmFeePolicy) {
      AtmFeePolicy.unknown => l10n.cardAtmUnknown,
      AtmFeePolicy.noFee => l10n.cardAtmNoFee,
      AtmFeePolicy.refundsFees => l10n.cardAtmRefunds,
      AtmFeePolicy.chargesFixed => l10n.cardAtmFixedValue(
        AppFormat.amount(value ?? 0, trip.homeCurrency),
      ),
      AtmFeePolicy.chargesPercent => l10n.cardAtmPercentValue(
        AppFormat.percent(value ?? 0),
      ),
    };
    return GroupCard(
      dividerInset: AppSpacing.rowIconTextInset,
      children: [
        // The chosen card, or the two ways to choose one.
        if (_cards.where((c) => c.id == _briefing.card.productId).firstOrNull
            case final card?)
          _ActionRow(
            icon: SizedBox(
              width: AppSizes.cardThumbWidth,
              child: CardFace(card: card, compact: true),
            ),
            title: '${card.issuer} ${card.name}',
            subtitle: cardFeeLine(l10n, card),
            onPressed: () => _editCard(trip),
          )
        else if (_cards.isNotEmpty)
          _ActionRow(
            icon: const IconTile.blue(icon: Icons.add_card_rounded),
            title: l10n.cardAdd,
            subtitle: l10n.cardAddBody,
            onPressed: () => _editCard(trip),
          ),
        _ActionRow(
          icon: const IconTile.blue(icon: Icons.credit_card_rounded),
          title: l10n.cardFeeRow,
          subtitle: fee == null ? l10n.cardFeeMissing : null,
          value: fee == null ? null : AppFormat.percent(fee),
          onPressed: () => _editCard(trip),
        ),
        _ActionRow(
          icon: const IconTile.orange(icon: Icons.account_balance_rounded),
          title: l10n.cardAtmRow,
          value: atm,
          onPressed: () => _editCard(trip),
        ),
      ],
    );
  }

  Widget _nearby(
    AppLocalizations l10n,
    List<TrapWarning> traps, {
    required bool demo,
  }) {
    switch (demo ? _briefing.demoNearbyState : _briefing.nearbyState) {
      case NearbyState.noLocation:
        return GroupCard(
          children: [
            _ActionRow(
              icon: const IconTile.blue(icon: Icons.near_me_rounded),
              title: l10n.nearbyNeedLocation,
              subtitle: l10n.nearbyLocationPrivacy,
              onPressed: () => _briefing.refresh(askLocation: true),
            ),
          ],
        );
      case NearbyState.idle || NearbyState.loading:
        return GroupCard(
          children: [
            GroupRow(
              leading: const IconTile.blue(icon: Icons.near_me_rounded),
              title: l10n.nearbyLooking,
            ),
          ],
        );
      case NearbyState.done:
        if (traps.isEmpty) {
          return GroupCard(
            children: [
              GroupRow(
                leading: const IconTile(
                  icon: Icons.check_rounded,
                  light: AppColors.iconGreenLight,
                  dark: AppColors.iconGreen,
                ),
                title: l10n.nearbyClear,
                subtitle: l10n.nearbyClearBasis,
              ),
            ],
          );
        }
        return GroupCard(
          dividerInset: AppSpacing.rowIconTextInset,
          children: [
            for (final t in traps)
              _mapTrapRow(
                trap: t,
                onPressed: switch (t.kind) {
                  TrapKind.atmFee || TrapKind.atmConversion =>
                    () => _openAtmMap(select: t.placeName),
                  TrapKind.cashOnlyMarket => () => launchUrl(
                    Uri.https('www.google.com', '/maps/search/', {
                      'api': '1',
                      'query': t.placeName,
                    }),
                    mode: LaunchMode.externalApplication,
                  ),
                },
              ),
          ],
        );
    }
  }

  Widget _mapTrapRow({
    required TrapWarning trap,
    required VoidCallback onPressed,
  }) => Pressable(
    onPressed: onPressed,
    semanticLabel:
        '${trap.placeName} · ${AppLocalizations.of(context).nearbyMapLabel}',
    child: TrapRow(trap: trap),
  );

  Widget _arrival(AppLocalizations l10n, AppScope scope, TripContext trip) {
    final shown = _alerts.lastShown;
    final demoTarget =
        scope.settings.demoState && trip.homeCurrency == marketCurrency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupCard(
          dividerInset: AppSpacing.rowIconTextInset,
          children: [
            GroupRow(
              leading: const IconTile(
                icon: Icons.flight_land_rounded,
                light: AppColors.iconGreenLight,
                dark: AppColors.iconGreen,
              ),
              title: shown != null
                  ? _words(l10n, shown).title
                  : _alerts.permitted == true
                  ? l10n.arrivalOn
                  : l10n.arrivalOff,
              subtitle: shown == null
                  ? l10n.arrivalOnBody
                  : (_alerts.lastWasDemo
                        ? l10n.arrivalShownDemo(_words(l10n, shown).body)
                        : _words(l10n, shown).body),
            ),
            if (_alerts.permitted != true)
              _ActionRow(
                icon: const IconTile.blue(icon: Icons.notifications_rounded),
                title: _alerts.permitted == false
                    ? l10n.arrivalBlocked
                    : l10n.arrivalAllow,
                onPressed: _alerts.permitted == false
                    ? () => AppSettings.openAppSettings(
                        type: AppSettingsType.notification,
                      )
                    : _alerts.requestPermission,
              ),
          ],
        ),
        if (demoTarget && _briefing.facts != null) ...[
          const SizedBox(height: AppSpacing.groupGap),
          AppButton.secondary(
            label: l10n.arrivalDemoTrigger,
            icon: Icons.flight_land_rounded,
            onPressed: () async {
              if (_alerts.permitted == null) await _alerts.requestPermission();
              if (!context.mounted) return;
              await _alerts.demoArrival(
                homeCurrency: trip.homeCurrency,
                country: demoArrivalCountry,
                facts: _briefing.facts!,
                words: (a) => _words(l10n, a),
              );
            },
          ),
          GroupFooter(l10n.arrivalDemoFooter),
        ],
      ],
    );
  }

  /// Calendar access first, then the trip's dates when none are set.
  Future<void> _connectCalendar() async {
    final granted = await _briefing.connectCalendar();
    if (!granted || !mounted || _briefing.trip.period != null) return;
    await askTripDates(context, _briefing);
  }

  bool _isPast(bool demo) {
    final now = DateTime.now();
    return _briefing
        .dayShown(demo: demo)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  /// The saves and receipts recorded on the day shown, earliest first.
  List<Widget> _pastDay(
    AppLocalizations l10n,
    AppScope scope, {
    required bool demo,
  }) {
    final day = _briefing.dayShown(demo: demo);
    bool sameDay(DateTime t) {
      final l = t.toLocal();
      return DateTime(l.year, l.month, l.day) == day;
    }

    final rows = <(DateTime, Widget)>[
      for (final s in scope.trip.saves)
        if (sameDay(s.savedAt)) (s.savedAt, SaveRow(save: s, items: _items)),
      for (final r in scope.receipts.records)
        if (sameDay(r.savedAt)) (r.savedAt, ReceiptRecordRow(record: r)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      SectionHeader(l10n.tripDayRecords),
      GroupCard(
        dividerInset: AppSpacing.rowIconTextInset,
        children: rows.isEmpty
            ? [GroupRow(title: l10n.tripDayNoRecords)]
            : [for (final (_, row) in rows) row],
      ),
      if (demo && rows.isNotEmpty) GroupFooter(l10n.tripDayRecordsSample),
    ];
  }

  bool _showingToday({required bool demo}) {
    final now = DateTime.now();
    return _briefing.dayShown(demo: demo) ==
        DateTime(now.year, now.month, now.day);
  }

  String _stopsTitle(AppLocalizations l10n, {required bool demo}) =>
      _showingToday(demo: demo)
      ? l10n.assistantStops
      : l10n.tripStopsOn(
          DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag())
              .format(_briefing.dayShown(demo: demo)),
        );

  String _noStops(AppLocalizations l10n, {required bool demo}) {
    if (_showingToday(demo: demo)) return l10n.calendarNoStops;
    return demo ? l10n.calendarSampleOnlyToday : l10n.calendarNoStopsOn;
  }

  /// The trip's days to pick from, or the question that sets them. Shown
  /// once the calendar can be read (always in the demo).
  Widget? _tripStrip({required bool demo}) {
    if (!demo && _briefing.calendar.access != CalendarAccess.granted) {
      return null;
    }
    final period = _briefing.tripPeriod(demo: demo);
    if (period == null) {
      if (demo) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.groupGap),
        child: TripDatesPrompt(
          onPressed: () => askTripDates(context, _briefing),
        ),
      );
    }
    return TripDayStrip(
      period: period,
      day: _briefing.dayShown(demo: demo),
      sample: demo,
      onDay: (d) {
        _selected = null;
        _briefing.showDay(d);
      },
      onChange: demo ? null : () => askTripDates(context, _briefing),
    );
  }

  Future<void> _openAtmMap({String? select}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AtmMapScreen(briefing: _briefing, selectName: select),
    ),
  );

  Future<void> _editCard(TripContext trip) =>
      showCardFactsSheet(context, _briefing.card, trip.homeCurrency);
}

/// The notification's words for [alert].
ArrivalWords arrivalWords(AppLocalizations l10n, ArrivalAlert alert) => (
  title: l10n.arrivalTitle(_countryName(l10n, alert.country)),
  body: alert.atmOffersConversion
      ? l10n.arrivalBodyAtm(alert.localCurrency, alert.homeCurrency)
      : l10n.arrivalBody(alert.localCurrency, alert.homeCurrency),
  channel: l10n.arrivalChannel,
);

ArrivalWords _words(AppLocalizations l10n, ArrivalAlert a) =>
    arrivalWords(l10n, a);

String _countryName(AppLocalizations l10n, String code) => switch (code) {
  'JP' => l10n.countryJapan,
  'TH' => l10n.countryThailand,
  _ => code,
};

/// A tappable row with a chevron.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    required this.onPressed,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final row = GroupRow(
      leading: icon,
      title: title,
      subtitle: subtitle,
      value: value,
    );
    if (onPressed == null) return row;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: title,
      child: Row(
        children: [
          Expanded(child: row),
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
