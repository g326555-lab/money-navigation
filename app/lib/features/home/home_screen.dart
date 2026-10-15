import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../app/demo_switch.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/exchange_rate.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_ledger.dart';
import '../../shared/app_tab_bar.dart';
import '../../shared/coin.dart';
import '../../shared/odometer.dart';
import '../../shared/pill.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import 'save_row.dart';
import '../../shared/surface.dart';
import '../../rules/trip_route.dart';
import '../assistant/assistant_screen.dart' show arrivalWords;
import '../briefing/arrival_alerts.dart';
import '../briefing/briefing_controller.dart';
import '../briefing/calendar_source.dart';
import '../briefing/trip_context.dart';
import 'briefing_card.dart';
import 'home_metrics.dart';
import 'nearby_card.dart';
import 'route_line.dart';

/// How many saves Home lists before "See all".
const homeRecentCount = 3;

/// Trip summary: what this trip has kept so far, in baht and in the
/// traveler's own currency, and the latest saves.
///
/// Zones: hero (the green kept card and the trip's route), content (the
/// morning briefing, the nearest trap, recent saves), action (the dark
/// suggestion while nothing is saved). The tab bar floats above.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onScan,
    required this.onSeeAll,
    required this.onSettings,
    required this.onOpenAssistant,
    this.briefing,
    this.alerts,
  });

  final VoidCallback onScan;
  final VoidCallback onOpenAssistant;

  /// Injected in tests; the app-wide ones otherwise.
  final BriefingController? briefing;
  final ArrivalAlerts? alerts;
  final VoidCallback onSeeAll;
  final VoidCallback onSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _market = MarketPriceRepository();
  Map<String, SourcedItem> _items = const {};

  /// The total on screen. When the traveler comes back from a save, a coin
  /// flies into the card first, then this rolls up to the new total; nothing
  /// moves while Home is hidden.
  double _shownTotal = 0;
  bool _sawLoaded = false;
  bool _arriving = false;

  /// Whose records the total is: the traveler's own (null) or a demo
  /// state's. Switching ledgers is not a save, so nothing flies.
  String? _ledger;

  final _stackKey = GlobalKey();
  final _coinKey = GlobalKey();
  late final _fly = AnimationController(
    vsync: this,
    duration: AppMotion.flyToTotal,
  );
  late final _bump = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  @override
  void dispose() {
    _fly.dispose();
    _bump.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Decides what the card shows for [total], starting the arrival when a
  /// save has just raised it.
  void _sync(double total, bool loaded, bool visible, String? ledger) {
    if (!loaded) return;
    if (!_sawLoaded || ledger != _ledger) {
      _sawLoaded = true;
      _ledger = ledger;
      _shownTotal = total;
      return;
    }
    if (!visible || _arriving || total == _shownTotal) return;
    if (total < _shownTotal || MediaQuery.disableAnimationsOf(context)) {
      _shownTotal = total;
      return;
    }
    _arriving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _fly.forward(from: 0);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _arriving = false;
        _shownTotal = keptTotalThb(AppScope.of(context).trip.saves);
      });
      _bump.forward(from: 0);
    });
  }

  BriefingController get _briefing =>
      widget.briefing ?? BriefingController.instance;
  ArrivalAlerts get _alerts => widget.alerts ?? ArrivalAlerts.instance;

  /// The country (and permission) the arrival check last ran for.
  String? _checkedCountry;

  late final _lifecycle = AppLifecycleListener(
    onResume: () => _briefing.refreshIfStale(),
  );

  /// Alerts once when the phone's location shows a new country.
  void _checkArrival(AppScope scope) {
    final country = _briefing.country;
    final facts = _briefing.facts;
    final key = '$country|${_alerts.permitted}';
    if (country == null || facts == null || key == _checkedCountry) return;
    // The demo state plays its arrival from the Assistant tab instead.
    if (scope.settings.demoState) return;
    _checkedCountry = key;
    final l10n = AppLocalizations.of(context);
    _alerts.checkArrival(
      homeCurrency: scope.settings.homeCurrency,
      country: country,
      facts: facts,
      words: (a) => arrivalWords(l10n, a),
    );
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _briefing.start();
    _alerts.checkPermission();
    _market.load().then((items) {
      if (!mounted) return;
      setState(() => _items = {for (final s in items) s.item.key: s});
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        scope.trip,
        scope.settings,
        scope.rates,
        _briefing,
        _alerts,
      ]),
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final l10n = AppLocalizations.of(context);
    final saves = scope.trip.saves;
    final total = keptTotalThb(saves);
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    _sync(
      total,
      scope.trip.loaded,
      visible,
      scope.trip.showingDemo ? scope.settings.demoPersona?.key : null,
    );
    final currency = scope.settings.homeCurrency;
    // The demo state keeps the stage figure fixed with the demo rate.
    final demoQuote = scope.settings.demoState
        ? scope.demoRates?.quoteFor(marketCurrency, currency)
        : null;
    final quote = currency == marketCurrency
        ? null
        : demoQuote ?? scope.rates.quoteFor(currency);
    final persona = scope.settings.demoPersona;
    final trip = TripContext.of(scope, _briefing.facts);
    final plan = scope.trip.loaded
        ? _briefing.cashPlan(trip.history, demo: scope.settings.demoState)
        : null;
    final traps = _briefing.traps(
      countryCode: _briefing.country,
      demo: scope.settings.demoState,
      homeCurrency: trip.homeCurrency,
      limit: HomeMetrics.homeWarnings + 2,
    );
    final wide = MediaQuery.sizeOf(context).width >= HomeMetrics.routeWideFrom;
    final route = tripRoute(
      saves,
      maxStops: wide
          ? HomeMetrics.routeStopsWide
          : HomeMetrics.routeStopsNarrow,
    );
    _briefing.places.languageCode = Localizations.localeOf(context)
        .languageCode;
    _checkArrival(scope);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          key: _stackKey,
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                MediaQuery.paddingOf(context).top,
                AppSpacing.screenMargin,
                AppTabBar.contentPadding(context),
              ),
              children: [
                Row(
                  children: [
                    if (persona != null && scope.demoPersonas != null)
                      Expanded(
                        child: _DemoPill(
                          label: l10n.demoPill(demoPersonaName(l10n, persona)),
                          semanticLabel: l10n.demoSwitchTo(
                            demoPersonaName(
                              l10n,
                              scope.demoPersonas!.other(persona),
                            ),
                          ),
                          onPressed: () => DemoSwitch.to(
                            context,
                            scope.demoPersonas!.other(persona),
                          ),
                        ),
                      ),
                    if (persona == null || scope.demoPersonas == null)
                      const Spacer(),
                    _SettingsButton(
                      label: l10n.settingsTitle,
                      onPressed: widget.onSettings,
                    ),
                  ],
                ),
                _KeptCard(
                  coinKey: _coinKey,
                  bump: _bump,
                  label: l10n.homeKeptLabel,
                  total: _shownTotal,
                  currency: marketCurrency,
                  // Nothing kept yet has no equivalent worth showing.
                  approx: quote == null || _shownTotal == 0
                      ? null
                      : l10n.homeKeptApprox(
                          AppFormat.estimate(
                            convertFromBase(_shownTotal, quote),
                            currency,
                          ),
                        ),
                ),
                if (currency != marketCurrency || saves.any((x) => x.isSample))
                  GroupFooter(
                    [
                      if (saves.any((x) => x.isSample)) l10n.homeKeptSamples,
                      if (currency != marketCurrency)
                        _rateLine(
                          l10n,
                          scope,
                          currency,
                          quote,
                          demo: demoQuote,
                        ),
                    ].join(' · '),
                  ),
                if (route.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  RouteLine(stops: route),
                ],
                const SizedBox(height: AppSpacing.zoneGap),
                // Nothing to say until the trip's records are read.
                if (scope.trip.loaded)
                  BriefingCard(
                    plan: plan,
                    calendarConnected:
                        _briefing.calendar.access == CalendarAccess.granted,
                    onConnect: _briefing.connectCalendar,
                    onOpen: widget.onOpenAssistant,
                  ),
                const SizedBox(height: AppSpacing.groupGap),
                NearbyCard(
                  // A demo traveler is not where the phone is.
                  state: scope.settings.demoState
                      ? NearbyState.idle
                      : _briefing.nearbyState,
                  traps: traps,
                  onAskLocation: () => _briefing.refresh(askLocation: true),
                  onOpen: widget.onOpenAssistant,
                ),
                const SizedBox(height: AppSpacing.zoneGap),
                if (!scope.trip.loaded)
                  const SizedBox.shrink()
                else if (saves.isEmpty)
                  _StartCard(
                    label: l10n.homeEmptyLabel,
                    title: l10n.homeEmptyTitle,
                    action: l10n.homeEmptyAction,
                    onPressed: widget.onScan,
                  )
                else ...[
                  SectionHeader(
                    l10n.homeRecent,
                    first: true,
                    trailing: saves.length > homeRecentCount
                        ? _Link(
                            label: l10n.homeSeeAll,
                            onPressed: widget.onSeeAll,
                          )
                        : null,
                  ),
                  GroupCard(
                    dividerInset: AppSpacing.rowIconTextInset,
                    children: [
                      for (final save in saves.take(homeRecentCount))
                        SaveRow(save: save, items: _items),
                    ],
                  ),
                ],
              ],
            ),
            if (_arriving)
              _FlyingCoin(
                progress: _fly,
                stackKey: _stackKey,
                targetKey: _coinKey,
              ),
          ],
        ),
      ),
    );
  }

  String _rateLine(
    AppLocalizations l10n,
    AppScope scope,
    String currency,
    RateQuote? quote, {
    RateQuote? demo,
  }) {
    if (quote == null) {
      return scope.rates.unavailable(currency)
          ? l10n.homeRateUnavailable(currency)
          : l10n.homeRateLoading;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMd(locale).format(DateTime.parse(quote.date));
    // Read the rate the way that gives a number above one.
    final pair = quote.rate >= 1
        ? l10n.ratePair(
            marketCurrency,
            AppFormat.rateValue(quote.rate),
            currency,
          )
        : l10n.ratePair(
            currency,
            AppFormat.rateValue(inverseRate(quote)),
            marketCurrency,
          );
    if (demo != null) return l10n.homeRateDemo(pair, date);
    return scope.rates.refreshFailed(currency)
        ? l10n.homeRateCached(pair, date)
        : l10n.homeRateSource(pair, date);
  }
}

/// The hero: soft green card, label, the kept total and the coin.
class _KeptCard extends StatelessWidget {
  const _KeptCard({
    required this.coinKey,
    required this.bump,
    required this.label,
    required this.total,
    required this.currency,
    required this.approx,
  });

  final GlobalKey coinKey;

  /// 0..1 while the total bumps after a coin lands.
  final Animation<double> bump;
  final String label;
  final double total;
  final String currency;
  final String? approx;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Surface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.heroCardPadding),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryContainer, AppColors.primaryContainerEnd],
      ),
      shadows: AppElevation.e1Green,
      edgeLight: EdgeLights.onTile,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: type.heroLabel.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedBuilder(
                  animation: bump,
                  builder: (context, child) => Transform.scale(
                    // Up to totalBump and back, once.
                    scale:
                        1 +
                        (AppMotion.totalBump - 1) *
                            math.sin(bump.value * math.pi),
                    alignment: Alignment.bottomLeft,
                    child: child,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Odometer(
                          text: AppFormat.roundedNumber(total),
                          style: type.displayLg,
                        ),
                        Text('\u00A0$currency', style: type.title),
                      ],
                    ),
                  ),
                ),
                if (approx != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Pill.onGreen(
                    label: approx!,
                    shadows: AppElevation.pillOnGreen,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          LivingCoin(key: coinKey, size: AppSizes.heroCoinCompact),
        ],
      ),
    );
  }
}

/// The one dark card: what to do first while nothing is saved.
class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.label,
    required this.title,
    required this.action,
    required this.onPressed,
  });

  final String label;
  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: action,
      child: Surface(
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceDarkTop, AppColors.surfaceDark],
        ),
        shadows: AppElevation.e1,
        edgeLight: EdgeLights.onDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: type.label.copyWith(color: AppColors.primaryOnDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: type.title.copyWith(color: AppColors.onSurfaceDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  action,
                  style: type.bodyLg.copyWith(color: AppColors.onSurfaceDark),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.stepIcon,
                  color: AppColors.onSurfaceDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Says the demo state is on, and swaps to the other prepared traveler.
class _DemoPill extends StatelessWidget {
  const _DemoPill({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: AppColors.surface,
              shadows: AppElevation.e1,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.chipPadding,
                AppSpacing.sm,
                AppSpacing.chipPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.label.copyWith(color: AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: AppSizes.pillIcon,
                    color: AppColors.onSurfaceTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: const SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Icon(
          Icons.tune_rounded,
          size: AppSizes.tabIcon,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Align(
          widthFactor: 1,
          child: Text(label, style: AppTypography.of(context).link),
        ),
      ),
    );
  }
}

/// The coin from "Save to trip", flying on an arc from where the save
/// button was up into the card's coin.
class _FlyingCoin extends StatelessWidget {
  const _FlyingCoin({
    required this.progress,
    required this.stackKey,
    required this.targetKey,
  });

  final Animation<double> progress;
  final GlobalKey stackKey;
  final GlobalKey targetKey;

  @override
  Widget build(BuildContext context) {
    final stack = stackKey.currentContext?.findRenderObject() as RenderBox?;
    final target = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || target == null) return const SizedBox.shrink();
    final size = stack.size;
    final end = target.localToGlobal(
      target.size.center(Offset.zero),
      ancestor: stack,
    );
    final start = Offset(size.width / 2, size.height - AppSizes.buttonHeight);
    // Bulges outwards on the way up, like something tossed into a jar.
    final control = Offset(
      (start.dx + end.dx) / 2 + AppSizes.flyArcBulge,
      end.dy,
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final t = AppMotion.move.transform(progress.value);
            final p =
                start * ((1 - t) * (1 - t)) +
                control * (2 * (1 - t) * t) +
                end * (t * t);
            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset:
                    p - const Offset(AppSizes.flyCoin, AppSizes.flyCoin) / 2,
                child: Transform.scale(
                  scale: 1 - (1 - AppMotion.flyEndScale) * t,
                  child: const Coin(size: AppSizes.flyCoin),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
