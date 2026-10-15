import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/receipt_store.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_map.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import 'map_style.dart';
import 'pin_icons.dart';

/// Where the trip's money went: saved receipts and haggles that have a
/// place, as pins on a quiet grey map, with the same records listed by day
/// underneath. Tapping a pin or a row selects it in both.
class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  GoogleMapController? _map;
  final _receipts = ReceiptStore.shared;
  final _icons = PinIcons();
  String? _selected;

  @override
  void initState() {
    super.initState();
    _receipts.load();
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
    super.dispose();
  }

  void _select(MapPin pin, {bool move = false}) {
    HapticFeedback.selectionClick();
    setState(() => _selected = pin.id);
    if (move) {
      _map?.animateCamera(CameraUpdate.newLatLng(LatLng(pin.lat, pin.lng)));
    }
  }

  void _fit(List<MapPin> pins) {
    final b = pinBounds(pins);
    if (b == null) return;
    _map?.moveCamera(
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
        return _page(context, pins);
      },
    );
  }

  Widget _page(BuildContext context, List<MapPin> pins) {
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                0,
                AppSpacing.screenMargin,
                MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(
                      -(AppSizes.minTouchTarget - AppSizes.tabIcon) / 2,
                      0,
                    ),
                    child: IconButton(
                      tooltip: l10n.back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.onSurface,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.tripMapTitle, style: type.headline),
                const SizedBox(height: AppSpacing.zoneGap),
                if (pins.isEmpty)
                  Text(
                    l10n.tripMapEmpty,
                    style: type.bodyMd.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  )
                else ...[
                  _mapCard(context, pins, selected),
                  for (final d in days) ..._day(context, d.day, d.pins),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapCard(BuildContext context, List<MapPin> pins, MapPin? selected) {
    final b = pinBounds(pins)!;
    return Surface(
      radius: AppRadius.lg,
      color: AppColors.surface,
      shadows: AppElevation.e0,
      clip: true,
      child: SizedBox(
        height: AppSizes.tripMapHeight,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng((b.south + b.north) / 2, (b.west + b.east) / 2),
                zoom: AppSizes.tripMapStartZoom,
              ),
              style: tripMapStyle,
              onMapCreated: (controller) {
                _map = controller;
                // Frame every pin once the map knows its size.
                WidgetsBinding.instance.addPostFrameCallback((_) => _fit(pins));
              },
              onTap: (_) => setState(() => _selected = null),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              markers: {
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
                    consumeTapEvents: true,
                    onTap: () => _select(p),
                    infoWindow: InfoWindow.noText,
                  ),
              },
            ),
            if (selected != null)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _PinCard(pin: selected),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _day(BuildContext context, DateTime day, List<MapPin> pins) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final kept = keptOnDay(pins);
    return [
      SectionHeader(
        DateFormat.MMMEd(locale).format(day),
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
            Pressable(
              onPressed: () => _select(p, move: true),
              child: GroupRow(
                leading: _kindTile(p.kind),
                title: p.title ?? _kindName(l10n, p.kind),
                subtitle: _rowSubtitle(context, p),
                value: _rowValue(p),
                valueStyle: p.keptThb != null && p.keptThb! > 0
                    ? AppTypography.of(context).rowTitle
                          .copyWith(color: AppColors.primaryText)
                    : null,
              ),
            ),
        ],
      ),
    ];
  }

  static String _rowValue(MapPin p) {
    if (p.keptThb case final k? when k > 0) {
      return '+${AppFormat.roundedAmount(k, marketCurrency)}';
    }
    final amount = p.amountThb;
    return amount == null ? '' : AppFormat.cents(amount, marketCurrency);
  }

  String _rowSubtitle(BuildContext context, MapPin p) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.Hm(locale).format(p.at);
    final notes = [
      time,
      _kindName(l10n, p.kind),
      if (p.isSample) l10n.tripMapSample,
      if (!p.verified) l10n.tripMapCorrected,
    ];
    return notes.join(' · ');
  }
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

/// The selected record, floating over the map.
class _PinCard extends StatelessWidget {
  const _PinCard({required this.pin});

  final MapPin pin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.MMMd(locale).add_Hm().format(pin.at);
    final amount = pin.amountThb;
    final kept = pin.keptThb;
    return Surface(
      radius: AppRadius.md,
      color: AppColors.surface,
      shadows: AppElevation.e2,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _kindTile(pin.kind),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                  [
                    when,
                    if (amount != null) AppFormat.cents(amount, marketCurrency),
                  ].join(' · '),
                  style: type.rowSubtitle,
                ),
              ],
            ),
          ),
          if (kept != null && kept > 0)
            Pill(
              label: l10n.tripMapKept(
                AppFormat.roundedAmount(kept, marketCurrency),
              ),
              fill: AppColors.primaryContainer,
              textColor: AppColors.onPrimaryContainer,
            )
          else if (pin.isSample)
            Pill(
              label: l10n.tripMapSample,
              fill: AppColors.surfaceDim,
              textColor: AppColors.onSurface,
            ),
        ],
      ),
    );
  }
}
