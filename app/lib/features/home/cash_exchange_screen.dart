import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/cash_exchange_repository.dart';
import '../../data/cash_wallet_store.dart';
import '../../features/briefing/phone_location.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/cash_exchange.dart';
import '../../shared/app_button.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import 'home_metrics.dart';

class CashExchangeScreen extends StatefulWidget {
  const CashExchangeScreen({
    super.key,
    required this.wallet,
    required this.walletCurrency,
    required this.foreignCurrency,
    this.repository,
    this.location,
  });

  final CashWalletStore wallet;
  final String walletCurrency;
  final String foreignCurrency;

  /// Injected in tests; the screen creates its own otherwise.
  final CashExchangeRepository? repository;
  final PhoneLocation? location;

  @override
  State<CashExchangeScreen> createState() => _CashExchangeScreenState();
}

class _CashExchangeScreenState extends State<CashExchangeScreen> {
  late final _repository = widget.repository ?? CashExchangeRepository();
  late final _location = widget.location ?? PhoneLocation();
  final _amount = TextEditingController();
  CashExchangeData? _data;
  double? _latitude;
  double? _longitude;
  String? _currency;
  String? _denomination;
  bool _loading = true;
  bool _locationUnavailable = false;
  bool _ratesUnavailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _locationUnavailable = false;
      _ratesUnavailable = false;
    });
    Object? raw;
    Object? position;
    try {
      final results = await Future.wait<Object?>([
        _repository.load(force: force),
        _location.read(ask: true),
      ]);
      raw = results[0];
      position = results[1];
    } on Object {
      // Both calls are written not to throw; if one still does, show the
      // honest unavailable state instead of staying on "Checking".
      raw = null;
      position = null;
    }
    if (!mounted) return;
    final now = DateTime.now();
    final data = raw is Map
        ? CashExchangeData.fromResponse(raw, now: now)
        : null;
    final currencies = data?.currencies(now).toList() ?? const <String>[];
    final suggested = widget.foreignCurrency.toUpperCase();
    final currency = currencies.contains(suggested)
        ? suggested
        : currencies.firstOrNull;
    final denominations =
        data?.denominations(currency ?? '', now) ?? const <String>[];
    setState(() {
      _data = data;
      _latitude = position is Position ? position.latitude : null;
      _longitude = position is Position ? position.longitude : null;
      _currency = currency;
      _denomination = denominations.firstOrNull;
      _locationUnavailable = position == null;
      // A fresh snapshot whose every source went stale has nothing to rank.
      _ratesUnavailable = currencies.isEmpty;
      _loading = false;
    });
  }

  List<ExchangeOffer> get _offers {
    final amount = parseExchangeAmount(_amount.text);
    final data = _data;
    final latitude = _latitude;
    final longitude = _longitude;
    final currency = _currency;
    final denomination = _denomination;
    if (data == null ||
        latitude == null ||
        longitude == null ||
        currency == null ||
        denomination == null ||
        amount == null) {
      return const [];
    }
    return nearbyCashExchangeOffers(
      data: data,
      latitude: latitude,
      longitude: longitude,
      currency: currency,
      denomination: denomination,
      foreignAmount: amount,
      now: DateTime.now(),
    );
  }

  Future<void> _openMap(ExchangeOffer offer) async {
    final lat = offer.shop.latitude;
    final lng = offer.shop.longitude;
    if (lat == null || lng == null) return;
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lat,$lng',
    });
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _recordExchange(ExchangeOffer offer) async {
    final l10n = AppLocalizations.of(context);
    final actual = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmExchangeSheet(
        estimatedPayout: offer.thbPayout,
        walletCurrency: widget.walletCurrency,
      ),
    );
    if (actual == null || !mounted) return;
    final now = DateTime.now();
    var saved = true;
    try {
      await widget.wallet.addExchangeCash(
        amount: actual,
        currency: widget.walletCurrency,
        sourceId: 'exchange-${now.microsecondsSinceEpoch}',
        description: l10n.cashWalletExchange,
        at: now,
      );
    } on Object {
      saved = false;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved ? l10n.exchangeRecorded : l10n.exchangeRecordFailed,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final data = _data;
    final currencies = data?.currencies(now).toList() ?? const <String>[];
    final denominations =
        data?.denominations(_currency ?? '', now) ?? const <String>[];
    final offers = _offers;
    final amountEntered = parseExchangeAmount(_amount.text) != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(
                          -(AppSizes.minTouchTarget - AppSizes.tabIcon) / 2,
                          0,
                        ),
                        child: IconButton(
                          tooltip: l10n.back,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.onSurface,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Expanded(
                        child: Text(l10n.exchangeTitle, style: type.bodyLg),
                      ),
                      IconButton(
                        tooltip: l10n.exchangeRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.onSurface,
                        onPressed: _loading ? null : () => _load(force: true),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenMargin,
                      AppSpacing.sm,
                      AppSpacing.screenMargin,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
                    ),
                    children: [
                      Text(l10n.exchangeTitle, style: type.headline),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.exchangeSubtitle, style: type.rowSubtitle),
                      const SizedBox(height: AppSpacing.xl),
                      Surface(
                        radius: AppRadius.xl,
                        color: AppColors.surface,
                        shadows: AppElevation.e0,
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.exchangeAmount, style: type.label),
                            const SizedBox(height: AppSpacing.sm),
                            Surface(
                              radius: AppRadius.md,
                              color: AppColors.surfaceSunken,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _amount,
                                      onChanged: (_) => setState(() {}),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9,.]'),
                                        ),
                                      ],
                                      style: type.title.copyWith(
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: AppFormat.roundedNumber(100),
                                        hintStyle: type.bodyLg.copyWith(
                                          color: AppColors.onSurfaceTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (currencies.isNotEmpty)
                                    DropdownButton<String>(
                                      value: currencies.contains(_currency)
                                          ? _currency
                                          : null,
                                      underline: const SizedBox.shrink(),
                                      style: type.bodyLg,
                                      items: [
                                        for (final currency in currencies)
                                          DropdownMenuItem(
                                            value: currency,
                                            child: Text(currency),
                                          ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _currency = value;
                                          _denomination = data
                                              ?.denominations(
                                                value ?? '',
                                                DateTime.now(),
                                              )
                                              .firstOrNull;
                                        });
                                      },
                                    )
                                  else
                                    Text(
                                      widget.foreignCurrency,
                                      style: type.bodyLg.copyWith(
                                        color: AppColors.onSurfaceSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (denominations.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                l10n.exchangeDenomination,
                                style: type.label,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  for (final d in denominations)
                                    Pressable(
                                      onPressed: () =>
                                          setState(() => _denomination = d),
                                      semanticLabel: d,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: AppSizes.minTouchTarget,
                                        ),
                                        child: Center(
                                          widthFactor: 1,
                                          child: Pill(
                                            label: d,
                                            fill: _denomination == d
                                                ? AppColors.surfaceDark
                                                : AppColors.surfaceDim,
                                            textColor: _denomination == d
                                                ? AppColors.onSurfaceDark
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.exchangeMixedDenomination,
                              style: type.footer,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_loading)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl,
                          ),
                          child: Center(
                            child: Text(
                              l10n.exchangeLoading,
                              style: type.rowSubtitle,
                            ),
                          ),
                        )
                      else if (_ratesUnavailable)
                        _Notice(text: l10n.exchangeNoData)
                      else if (_locationUnavailable)
                        _Notice(text: l10n.exchangeNoLocation)
                      else if (amountEntered &&
                          _denomination != null &&
                          offers.isEmpty)
                        _Notice(
                          text: l10n.exchangeNoNearby(
                            _kilometers(exchangeNearbyRadiusMeters, locale),
                          ),
                        )
                      else if (offers.isNotEmpty) ...[
                        SectionHeader(l10n.exchangeFreshness, first: true),
                        GroupCard(
                          dividerInset: AppSpacing.groupPaddingH,
                          children: [
                            for (var i = 0; i < offers.take(5).length; i++)
                              _OfferRow(
                                rank: i + 1,
                                offer: offers[i],
                                currency: _currency!,
                                walletCurrency: widget.walletCurrency,
                                isBest: i == 0,
                                onMap: () => _openMap(offers[i]),
                                onRecord: () => _recordExchange(offers[i]),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.exchangeCounterNote, style: type.rowSubtitle),
                        if (data?.generatedAt != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.exchangeUpdated(
                              DateFormat.jm(locale).format(data!.generatedAt!),
                            ),
                            style: type.footer,
                          ),
                        ],
                      ] else if (!_loading)
                        _Notice(
                          text: amountEntered
                              ? l10n.exchangeNoRates
                              : l10n.exchangeEnterAmount,
                        ),
                      const SizedBox(height: AppSpacing.zoneGap),
                      Pressable(
                        semanticLabel: l10n.exchangeAttribution,
                        onPressed: () => launchUrl(
                          Uri.parse('https://thairate.com/'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          l10n.exchangeAttribution,
                          style: type.footer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.rank,
    required this.offer,
    required this.currency,
    required this.walletCurrency,
    required this.isBest,
    required this.onMap,
    required this.onRecord,
  });

  final int rank;
  final ExchangeOffer offer;
  final String currency;
  final String walletCurrency;
  final bool isBest;
  final VoidCallback onMap;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final distance = _kilometers(offer.distanceMeters, locale);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.groupPaddingH,
        vertical: AppSpacing.rowPaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rank. ${offer.shop.name}',
                  style: type.rowTitle.copyWith(
                    color: isBest ? AppColors.primaryText : AppColors.onSurface,
                  ),
                ),
              ),
              Text(l10n.exchangeDistance(distance), style: type.footer),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(offer.shop.address, style: type.rowSubtitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.exchangeRateLine(
              AppFormat.rateValue(offer.tier.buyRate),
              exchangeWalletCurrency,
              currency,
            ),
            style: type.rowSubtitle.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            l10n.exchangePayout(
              AppFormat.roundedAmount(offer.thbPayout, exchangeWalletCurrency),
            ),
            style: type.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (offer.shop.sourceFetchedAt != null)
            Text(
              l10n.exchangeUpdated(
                DateFormat.jm(locale).format(offer.shop.sourceFetchedAt!),
              ),
              style: type.footer,
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              Pressable(
                onPressed: onMap,
                semanticLabel: l10n.exchangeMap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: AppSizes.pillIcon,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.exchangeMap,
                        style: type.link.copyWith(color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),
              ),
              Pressable(
                onPressed: onRecord,
                semanticLabel: l10n.exchangeAddToCash,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(l10n.exchangeAddToCash, style: type.link),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmExchangeSheet extends StatefulWidget {
  const _ConfirmExchangeSheet({
    required this.estimatedPayout,
    required this.walletCurrency,
  });

  final double estimatedPayout;
  final String walletCurrency;

  @override
  State<_ConfirmExchangeSheet> createState() => _ConfirmExchangeSheetState();
}

class _ConfirmExchangeSheetState extends State<_ConfirmExchangeSheet> {
  // Starts empty: the traveler types what the counter actually paid. The
  // estimate is only a hint, so one tap can never record it as real cash.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value => parseExchangeAmount(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final value = _value;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Surface(
        radius: AppRadius.sheet,
        color: AppColors.surface,
        shadows: AppElevation.e2Sheet,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          AppSpacing.md,
          AppSpacing.sheetPadding,
          AppSpacing.sheetPadding,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: HomeMetrics.grabberWidth,
                  height: HomeMetrics.grabberHeight,
                  decoration: const ShapeDecoration(
                    shape: StadiumBorder(),
                    color: AppColors.handle,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.exchangeConfirmTitle, style: type.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.exchangeConfirmBody(
                  AppFormat.roundedAmount(
                    widget.estimatedPayout,
                    exchangeWalletCurrency,
                  ),
                ),
                style: type.bodyMd.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Surface(
                radius: AppRadius.md,
                color: AppColors.surfaceSunken,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        style: type.title.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: AppFormat.roundedNumber(
                            widget.estimatedPayout,
                          ),
                          hintStyle: type.title.copyWith(
                            color: AppColors.onSurfaceTertiary,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Text(widget.walletCurrency, style: type.bodyLg),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l10n.exchangeUseActual,
                onPressed: value == null
                    ? null
                    : () => Navigator.pop(context, value),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: l10n.exchangeCancel,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Surface(
    radius: AppRadius.lg,
    color: AppColors.surface,
    shadows: AppElevation.e0,
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    child: Text(
      text,
      style: AppTypography.of(context).rowSubtitle,
      textAlign: TextAlign.center,
    ),
  );
}

/// Kilometres with one decimal in the reader's locale: "1.2".
String _kilometers(double meters, String locale) =>
    NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    ).format(meters / 1000);
