import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/nearby_atms.dart';
import '../../rules/nearby_traps.dart';
import '../../rules/trip_map.dart';
import '../../shared/app_button.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../briefing/briefing_controller.dart';
import '../briefing/briefing_rows.dart';
import '../briefing/trip_context.dart';
import 'map_style.dart';
import 'pin_icons.dart';

/// Cash machines around the traveler on a quiet map, nearest first, each
/// with walking directions in Google Maps. The places are the same Google
/// Maps search the briefing ran (around the phone, or around the sample
/// calendar's first stop in the demo state); nothing is placed by hand.
class AtmMapScreen extends StatefulWidget {
  const AtmMapScreen({super.key, this.briefing, this.selectName});

  final BriefingController? briefing;

  /// A machine to select on arrival, e.g. the one a warning was about.
  final String? selectName;

  @override
  State<AtmMapScreen> createState() => _AtmMapScreenState();
}

class _AtmMapScreenState extends State<AtmMapScreen> {
  BriefingController get _briefing =>
      widget.briefing ?? BriefingController.instance;

  GoogleMapController? _map;
  final _scroll = ScrollController();
  final _icons = PinIcons();
  String? _selected;
  String? _framed;
  bool _locationBlocked = false;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    _briefing.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _icons.prepare(MediaQuery.devicePixelRatioOf(context)).then((_) {
      if (mounted) setState(() {});
    });
    // The traveler opened this to find cash: a real search is what they
    // asked for, so the location prompt may be shown once here.
    final settings = AppScope.of(context).settings;
    final demo = settings.demoState;
    _briefing.markDemo(demo);
    final demoKey = settings.demoPersona?.key;
    if (demo && demoKey != _briefing.demoKey) {
      // The demo traveler's surroundings come from the same pipeline as
      // the Assistant's, even when that tab was never opened.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _briefing.useDemo(
          demoKey,
          currency: settings.demoPersona?.localCurrency,
        ),
      );
    }
    if (!_asked && !demo) {
      _asked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await _briefing.refresh(askLocation: true);
    if (!mounted) return;
    final blocked =
        _briefing.nearbyState == NearbyState.noLocation &&
        await _briefing.location.deniedForever();
    if (mounted && blocked != _locationBlocked) {
      setState(() => _locationBlocked = blocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_briefing, scope.settings]),
      builder: (context, _) {
        final demo = scope.settings.demoState;
        final atms = nearbyAtms(_briefing.nearbyPlaces(demo: demo));
        final origin = _briefing.nearbyOrigin(demo: demo);
        final trip = TripContext.of(
          scope,
          demo ? _briefing.bundledFacts : _briefing.facts,
        );
        final traps = _briefing.traps(
          countryCode: _briefing.country,
          demo: demo,
          homeCurrency: trip.homeCurrency,
        );
        if (_selected == null && widget.selectName != null) {
          _selected = atms
              .where((a) => a.name == widget.selectName)
              .firstOrNull
              ?.id;
        }
        final pins = _pins(atms, origin);
        if (_map != null && pins.isNotEmpty && _signature(pins) != _framed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fit(pins);
          });
        }
        return _page(
          context,
          atms: atms,
          traps: traps,
          pins: pins,
          demo: demo,
          state: _briefing.nearbyStateFor(demo: demo),
        );
      },
    );
  }

  /// Map pins for the machines, plus the search point for framing only.
  static List<MapPin> _pins(
    List<NearbyAtm> atms,
    ({double lat, double lng})? origin,
  ) {
    final now = DateTime.now();
    return [
      for (final a in atms)
        MapPin(
          id: a.id,
          kind: PinKind.atm,
          lat: a.lat,
          lng: a.lng,
          at: now,
          title: a.name,
        ),
      if (origin != null && atms.isNotEmpty)
        MapPin(
          id: _originId,
          kind: PinKind.terminal,
          lat: origin.lat,
          lng: origin.lng,
          at: now,
        ),
    ];
  }

  static const _originId = 'search-origin';

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

  void _select(NearbyAtm atm, {bool fromList = false}) {
    HapticFeedback.selectionClick();
    setState(() => _selected = atm.id);
    final still = MediaQuery.disableAnimationsOf(context);
    final target = CameraUpdate.newLatLng(LatLng(atm.lat, atm.lng));
    if (still) {
      _map?.moveCamera(target);
    } else {
      _map?.animateCamera(target);
    }
    if (fromList && _scroll.hasClients && _scroll.offset > 0) {
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

  Widget _page(
    BuildContext context, {
    required List<NearbyAtm> atms,
    required List<TrapWarning> traps,
    required List<MapPin> pins,
    required bool demo,
    required NearbyState state,
  }) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final compact = MediaQuery.sizeOf(context).height <= AppSizes.compactHeight;
    final selected = atms.where((a) => a.id == _selected).firstOrNull;
    final searching = state == NearbyState.idle || state == NearbyState.loading;
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
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(l10n.atmMapTitle, style: type.bodyLg),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                if (atms.isNotEmpty) ...[
                  _hero(context, atms.first),
                  SizedBox(
                    height: compact ? AppSpacing.xl : AppSpacing.zoneGap,
                  ),
                  _mapCard(context, atms, pins, selected, demo: demo),
                  if (demo) GroupFooter(l10n.atmMapDemoOrigin),
                  SectionHeader(l10n.atmMapList),
                  GroupCard(
                    dividerInset: AppSpacing.rowIconTextInset,
                    children: [for (final a in atms) _row(context, a, traps)],
                  ),
                  GroupFooter(l10n.atmMapSource),
                ] else if (searching)
                  GroupCard(
                    children: [
                      GroupRow(
                        leading: const IconTile.blue(icon: Icons.atm_rounded),
                        title: l10n.atmMapLooking,
                      ),
                    ],
                  )
                else if (state == NearbyState.noLocation && !demo)
                  _noLocation(context)
                else
                  _empty(context, demo: demo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The one number: how far the nearest machine is.
  Widget _hero(BuildContext context, NearbyAtm nearest) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final distance = nearest.distanceM;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sectionHeaderInset,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.atmMapNearest, style: type.heroLabel),
            Text(
              distance == null
                  ? nearest.name
                  : l10n.atmMapMeters(AppFormat.roundedNumber(distance)),
              style: type.displayLg.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: distance == null ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (distance != null)
              Text(
                nearest.name,
                style: type.bodyMd.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapCard(
    BuildContext context,
    List<NearbyAtm> atms,
    List<MapPin> pins,
    NearbyAtm? selected, {
    required bool demo,
  }) {
    final l10n = AppLocalizations.of(context);
    final b = pinBounds(pins)!;
    final height =
        (MediaQuery.sizeOf(context).height * AppSizes.tripMapHeightFraction)
            .clamp(AppSizes.tripMapMinHeight, AppSizes.tripMapMaxHeight);
    final still = MediaQuery.disableAnimationsOf(context);
    return Surface(
      radius: AppRadius.lg,
      color: AppColors.background,
      shadows: AppElevation.e0,
      clip: true,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Semantics(
              container: true,
              label: l10n.atmMapMapLabel(atms.length),
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
                  padding: EdgeInsets.only(
                    top: _selected == null ? 0 : AppSizes.tripMapCardReserve,
                  ),
                  onMapCreated: (controller) {
                    _map = controller;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fit(pins);
                    });
                  },
                  onTap: (_) => _deselect(),
                  // The blue dot is the phone itself; the demo traveler is
                  // somewhere else, so it stays off there.
                  myLocationEnabled: !demo,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  indoorViewEnabled: false,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                  markers: !_icons.ready
                      ? const {}
                      : {
                          for (final a in atms)
                            Marker(
                              markerId: MarkerId(a.id),
                              position: LatLng(a.lat, a.lng),
                              icon: _icons.of(
                                PinKind.atm,
                                sample: false,
                                selected: a.id == _selected,
                              ),
                              anchor: const Offset(0.5, 0.5),
                              zIndexInt: a.id == _selected ? 1 : 0,
                              consumeTapEvents: true,
                              onTap: () => _select(a),
                              infoWindow: InfoWindow.noText,
                            ),
                        },
                ),
              ),
            ),
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
                    : _AtmCard(
                        key: ValueKey(selected.id),
                        atm: selected,
                        onClose: _deselect,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, NearbyAtm atm, List<TrapWarning> traps) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final here = trapsAt(atm, traps);
    final isSelected = atm.id == _selected;
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        hint: l10n.tripMapShowOnMap,
        child: Pressable(
          onPressed: () => _select(atm, fromList: true),
          haptic: _noHaptic,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            curve: AppMotion.enter,
            color: isSelected ? AppColors.surfaceSunken : AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: GroupRow(
                      leading: const IconTile.blue(icon: Icons.atm_rounded),
                      title: atm.name,
                      titleStyle: isSelected
                          ? type.rowTitle.copyWith(color: AppColors.primaryText)
                          : null,
                      subtitle: [
                        if (atm.distanceM != null)
                          l10n.atmMapAway(
                            AppFormat.roundedNumber(atm.distanceM!),
                          ),
                        for (final t in here) trapText(l10n, t).$1,
                      ].join(' · '),
                    ),
                  ),
                  _DirectionsButton(atm: atm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _noHaptic() async {}

  Widget _noLocation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupCard(
          children: [
            GroupRow(
              leading: const IconTile.blue(icon: Icons.near_me_rounded),
              title: _locationBlocked
                  ? l10n.atmMapLocationSettings
                  : l10n.atmMapNeedLocation,
              subtitle: l10n.nearbyLocationPrivacy,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: _locationBlocked
              ? l10n.atmMapLocationSettings
              : l10n.atmMapNeedLocation,
          icon: Icons.near_me_rounded,
          onPressed: _locationBlocked
              ? () =>
                    AppSettings.openAppSettings(type: AppSettingsType.location)
              : _search,
        ),
        const SizedBox(height: AppSpacing.sm),
        _searchInMaps(context),
      ],
    );
  }

  Widget _empty(BuildContext context, {required bool demo}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupCard(
          children: [
            GroupRow(
              leading: const IconTile.blue(icon: Icons.atm_rounded),
              title: l10n.atmMapEmpty,
            ),
          ],
        ),
        if (demo) GroupFooter(l10n.atmMapDemoOrigin),
        const SizedBox(height: AppSpacing.xl),
        if (!demo) ...[
          AppButton(
            label: l10n.atmMapRetry,
            icon: Icons.refresh_rounded,
            onPressed: _search,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _searchInMaps(context),
      ],
    );
  }

  Widget _searchInMaps(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppButton.secondary(
      label: l10n.atmMapSearchMaps,
      icon: Icons.map_outlined,
      onPressed: () => launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': 'ATM',
        }),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}

/// Walking directions to [atm]. On Android the Google Maps app starts
/// walking navigation straight away (its web link keeps the last travel
/// mode, often driving); elsewhere, or without the app, the web link with
/// the walking mode.
Future<void> openAtmDirections(NearbyAtm atm) async {
  if (Platform.isAndroid) {
    final app = Uri.parse('google.navigation:q=${atm.lat},${atm.lng}&mode=w');
    try {
      if (await launchUrl(app, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // No Maps app: the web link below.
    }
  }
  await launchUrl(
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${atm.lat},${atm.lng}',
      'travelmode': 'walking',
    }),
    mode: LaunchMode.externalApplication,
  );
}

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.atm});

  final NearbyAtm atm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.atmMapDirectionsTo(atm.name),
      onPressed: () => openAtmDirections(atm),
      icon: const Icon(Icons.directions_rounded),
      color: AppColors.primaryText,
    );
  }
}

/// The selected machine over the top of the map, with directions.
class _AtmCard extends StatelessWidget {
  const _AtmCard({super.key, required this.atm, required this.onClose});

  final NearbyAtm atm;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
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
        children: [
          const IconTile.blue(icon: Icons.atm_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    atm.name,
                    style: type.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (atm.distanceM != null)
                    Text(
                      l10n.atmMapAway(AppFormat.roundedNumber(atm.distanceM!)),
                      style: type.rowSubtitle,
                    ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => openAtmDirections(atm),
            icon: const Icon(Icons.directions_rounded),
            label: Text(l10n.atmMapDirections),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              minimumSize: const Size(
                AppSizes.minTouchTarget,
                AppSizes.minTouchTarget,
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
