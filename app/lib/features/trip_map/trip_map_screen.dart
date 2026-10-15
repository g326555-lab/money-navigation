import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/receipt_store.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_map.dart';
import '../../shared/app_button.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../scan/scan_screen.dart';
import 'map_style.dart';
import 'pin_icons.dart';

/// Where the trip's money went: saved receipts and haggles that have a
/// place, as pins on a quiet grey map, with the same records listed by day
/// underneath. Tapping a pin or a row selects it in both. The list is the
/// accessible path; the map is a picture of it.
class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  /// How long the map host may take to answer before the page says, quietly,
  /// that the map needs a connection.
  static const _reachTimeout = Duration(seconds: 3);
  static const _mapHost = 'maps.googleapis.com';

  GoogleMapController? _map;
  final _scroll = ScrollController();
  final _receipts = ReceiptStore.shared;
  final _icons = PinIcons();
  String? _selected;

  /// The pin set the camera was last framed on, so new records reframe it.
  String? _framed;
  bool _offline = false;

  /// Receipts load on their own; until they have, "no places" is not yet
  /// true, so the empty state waits.
  bool _receiptsLoaded = false;

  @override
  void initState() {
    super.initState();
    _receipts.load().whenComplete(() {
      if (mounted) setState(() => _receiptsLoaded = true);
    });
    _checkReach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _icons.prepare(MediaQuery.devicePixelRatioOf(context)).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _map?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Map tiles fail silently without a connection; the pins and the list
  /// still work, so the page only adds one quiet line under the map.
  Future<void> _checkReach() async {
    var reachable = false;
    try {
      final found = await InternetAddress.lookup(_mapHost)
          .timeout(_reachTimeout);
      reachable = found.isNotEmpty;
    } on Object {
      reachable = false;
    }
    if (mounted && _offline == reachable) {
      setState(() => _offline = !reachable);
    }
  }

  void _select(MapPin pin, {bool fromList = false}) {
    HapticFeedback.selectionClick();
    setState(() => _selected = pin.id);
    if (!fromList) return;
    final still = MediaQuery.disableAnimationsOf(context);
    final target = CameraUpdate.newLatLng(LatLng(pin.lat, pin.lng));
    if (still) {
      _map?.moveCamera(target);
    } else {
      _map?.animateCamera(target);
    }
    // The map sits above the list: bring it back into view so the tap has
    // a visible result.
    if (_scroll.hasClients && _scroll.offset > 0) {
      if (still) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(
          0,
          duration: AppMotion.emphasized,
          curve: AppMotion.move,
        );
      }
    }
  }

  void _deselect() {
    if (_selected != null) setState(() => _selected = null);
  }

  static String _signature(List<MapPin> pins) =>
      pins.map((p) => p.id).join(',');

  void _fit(List<MapPin> pins) {
    final b = pinBounds(pins);
    if (b == null || _map == null) return;
    _framed = _signature(pins);
    _map!.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(b.south, b.west),
          northeast: LatLng(b.north, b.east),
        ),
        AppSpacing.xl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = AppScope.of(context).trip;
    return ListenableBuilder(
      listenable: Listenable.merge([trip, _receipts]),
      builder: (context, _) {
        final pins = pinsFrom(receipts: _receipts.records, saves: trip.saves);
        // Records can arrive after the map was framed (receipts load on
        // their own): frame again on the new set.
        if (_map != null && pins.isNotEmpty && _signature(pins) != _framed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fit(pins);
          });
        }
        return _page(context, pins, loaded: trip.loaded && _receiptsLoaded);
      },
    );
  }

  Widget _page(
    BuildContext context,
    List<MapPin> pins, {
    required bool loaded,
  }) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final days = pinsByDay(pins);
    final selected = pins.where((p) => p.id == _selected).firstOrNull;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                0,
                AppSpacing.screenMargin,
                MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
              ),
              children: [
                // Navigation row: back, then the page's name at body size so
                // the hero number below stays the largest thing here.
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
                      if (pins.isNotEmpty)
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(l10n.tripMapTitle, style: type.bodyLg),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (pins.isEmpty) ...[
                  if (loaded) _empty(context),
                ] else ...[
                  _hero(context, pins),
                  const SizedBox(height: AppSpacing.zoneGap),
                  _mapCard(context, pins, selected),
                  if (_offline) GroupFooter(l10n.tripMapOffline),
                  for (final (i, d) in days.indexed)
                    ..._day(context, d.day, d.pins, first: i == 0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One sentence and the one action that puts a place on this map.
  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sectionHeaderInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tripMapTitle, style: type.headline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tripMapEmpty,
            style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: AppSpacing.zoneGap),
          AppButton.secondary(
            label: l10n.tripMapEmptyAction,
            icon: Icons.document_scanner_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const ScanScreen(),
                fullscreenDialog: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The one number: money kept at the places on this map, or how many
  /// places there are when none of them kept money (receipts only).
  Widget _hero(BuildContext context, List<MapPin> pins) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final kept = keptOnDay(pins);
    final keeping = pins.where((p) => (p.keptThb ?? 0) > 0).toList();
    final hasSamples = keeping.any((p) => p.isSample);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sectionHeaderInset,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kept > 0 ? l10n.tripMapKeptAt(keeping.length) : l10n.tripMapOnMap,
              style: type.heroLabel,
            ),
            Text(
              kept > 0
                  ? AppFormat.roundedAmount(kept, marketCurrency)
                  : l10n.tripMapPlaces(pins.length),
              style: type.displayLg,
            ),
            if (kept > 0 && hasSamples) ...[
              const SizedBox(height: AppSpacing.sm),
              Pill(
                label: l10n.homeKeptSamples,
                fill: AppColors.surface,
                textColor: AppColors.onSurfaceSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mapCard(BuildContext context, List<MapPin> pins, MapPin? selected) {
    final l10n = AppLocalizations.of(context);
    final b = pinBounds(pins)!;
    final height =
        (MediaQuery.sizeOf(context).height * AppSizes.tripMapHeightFraction)
            .clamp(AppSizes.tripMapMinHeight, AppSizes.tripMapMaxHeight);
    final still = MediaQuery.disableAnimationsOf(context);
    return Surface(
      radius: AppRadius.lg,
      // The map's own land colour, so the card never flashes white before
      // the first tiles arrive (or when they cannot).
      color: AppColors.background,
      shadows: AppElevation.e0,
      clip: true,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Pins are not reachable by screen readers; the list below is.
            Semantics(
              container: true,
              label: l10n.tripMapMapLabel(pins.length),
              child: ExcludeSemantics(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      (b.south + b.north) / 2,
                      (b.west + b.east) / 2,
                    ),
                    zoom: AppSizes.tripMapStartZoom,
                  ),
                  style: tripMapStyle,
                  onMapCreated: (controller) {
                    _map = controller;
                    // Frame every pin once the map knows its size.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fit(pins);
                    });
                  },
                  onTap: (_) => _deselect(),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  indoorViewEnabled: false,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                  // Until our pins are drawn, show none rather than
                  // Google's red default for a frame.
                  markers: !_icons.ready
                      ? const {}
                      : {
                          for (final p in pins)
                            Marker(
                              markerId: MarkerId(p.id),
                              position: LatLng(p.lat, p.lng),
                              icon: _icons.of(
                                p.kind,
                                sample: p.isSample,
                                selected: p.id == _selected,
                              ),
                              anchor: const Offset(0.5, 0.5),
                              // The selected pin sits above its neighbours.
                              zIndexInt: p.id == _selected ? 1 : 0,
                              consumeTapEvents: true,
                              onTap: () => _select(p),
                              infoWindow: InfoWindow.noText,
                            ),
                        },
                ),
              ),
            ),
            // The selected place floats at the top, so Google's logo and
            // legal text along the bottom edge always stay visible.
            Positioned(
              left: AppSizes.tripMapCardInset,
              right: AppSizes.tripMapCardInset,
              top: AppSizes.tripMapCardInset,
              child: AnimatedSwitcher(
                duration: still ? AppMotion.quick : AppMotion.standard,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) {
                  final fade = FadeTransition(opacity: animation, child: child);
                  if (still) return fade;
                  return SlideTransition(
                    position: Tween(
                      begin: AppMotion.mapCardDrop,
                      end: Offset.zero,
                    ).animate(animation),
                    child: fade,
                  );
                },
                child: selected == null
                    ? const SizedBox.shrink(key: ValueKey('none'))
                    : _PinCard(
                        key: ValueKey(selected.id),
                        pin: selected,
                        onClose: _deselect,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _day(
    BuildContext context,
    DateTime day,
    List<MapPin> pins, {
    required bool first,
  }) {
    final l10n = AppLocalizations.of(context);
    final kept = keptOnDay(pins);
    return [
      SectionHeader(
        _dayName(context, day),
        trailing: kept > 0
            ? Text(
                l10n.tripMapKeptDay(
                  AppFormat.roundedAmount(kept, marketCurrency),
                ),
                style: AppTypography.of(context).link
                    .copyWith(color: AppColors.primaryText),
              )
            : null,
      ),
      GroupCard(
        dividerInset: AppSpacing.rowIconTextInset,
        children: [
          for (final p in pins)
            MergeSemantics(
              child: Semantics(
                selected: p.id == _selected,
                hint: l10n.tripMapShowOnMap,
                child: Pressable(
                  onPressed: () => _select(p, fromList: true),
                  // _select plays the selection click itself.
                  haptic: _noHaptic,
                  child: GroupRow(
                    leading: _kindTile(p.kind),
                    title: p.title ?? _kindName(l10n, p.kind),
                    subtitle: _meta(context, p),
                    value: _rowValue(p),
                    valueStyle: (p.keptThb ?? 0) > 0
                        ? AppTypography.of(context).rowTitle
                              .copyWith(color: AppColors.primaryText)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    ];
  }

  static Future<void> _noHaptic() async {}

  /// "Today", "Yesterday", then the weekday and date.
  String _dayName(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return l10n.tripMapToday;
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return l10n.tripMapYesterday;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMEd(locale).format(day);
  }

  static String _rowValue(MapPin p) {
    if (p.keptThb case final k? when k > 0) {
      return '+${AppFormat.roundedAmount(k, marketCurrency)}';
    }
    final amount = p.amountThb;
    return amount == null ? '' : AppFormat.cents(amount, marketCurrency);
  }
}

/// Time, kind, and whether the record is a sample or the traveler's own
/// correction: the same line in the list and on the map card.
String _meta(BuildContext context, MapPin p, {bool withDate = false}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final time =
      (withDate ? DateFormat.MMMd(locale).add_Hm() : DateFormat.Hm(locale))
          .format(p.at);
  return [
    time,
    _kindName(l10n, p.kind),
    if (p.isSample) l10n.tripMapSample,
    if (!p.verified) l10n.tripMapCorrected,
  ].join(' · ');
}

String _kindName(AppLocalizations l10n, PinKind kind) => switch (kind) {
  PinKind.receipt => l10n.tripMapKindReceipt,
  PinKind.haggle => l10n.tripMapKindHaggle,
  PinKind.atm => l10n.tripMapKindAtm,
  PinKind.terminal => l10n.tripMapKindTerminal,
};

Widget _kindTile(PinKind kind) => switch (kind) {
  PinKind.haggle => const IconTile.orange(icon: Icons.storefront_rounded),
  PinKind.receipt => const IconTile(
    icon: Icons.receipt_long_rounded,
    light: AppColors.iconYellowLight,
    dark: AppColors.iconYellow,
  ),
  PinKind.atm => const IconTile.blue(icon: Icons.atm_rounded),
  PinKind.terminal => const IconTile.blue(icon: Icons.credit_card_rounded),
};

Color pinKindColor(PinKind kind) => switch (kind) {
  PinKind.haggle => AppColors.iconOrange,
  PinKind.receipt => AppColors.iconYellow,
  PinKind.atm || PinKind.terminal => AppColors.iconBlue,
};

/// The selected record, floating over the top of the map: what it was,
/// when, what was paid and what it kept, with a way to close it.
class _PinCard extends StatelessWidget {
  const _PinCard({super.key, required this.pin, required this.onClose});

  final MapPin pin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final amount = pin.amountThb;
    final kept = pin.keptThb;
    return Surface(
      radius: AppRadius.sm,
      color: AppColors.surface,
      shadows: AppElevation.e2,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        0,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kindTile(pin.kind),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.title ?? _kindName(l10n, pin.kind),
                    style: type.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _meta(context, pin, withDate: true),
                    style: type.rowSubtitle,
                  ),
                  if (amount != null || (kept ?? 0) > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (kept != null && kept > 0)
                          Pill(
                            label: l10n.tripMapKept(
                              AppFormat.roundedAmount(kept, marketCurrency),
                            ),
                            fill: AppColors.primaryContainer,
                            textColor: AppColors.onPrimaryContainer,
                          ),
                        if (amount != null)
                          Text(
                            l10n.tripMapPaid(
                              AppFormat.cents(amount, marketCurrency),
                            ),
                            style: type.caption.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.tripMapClose,
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              size: AppSizes.tripMapCloseIcon,
              color: AppColors.onSurfaceTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
