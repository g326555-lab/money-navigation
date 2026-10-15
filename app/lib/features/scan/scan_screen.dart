import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/colors.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/pressable.dart';
import '../speak/haggle_screen.dart';
import 'atm_result_screen.dart';
import 'scan_guide.dart';
import 'detection_overlay.dart';
import 'scan_controller.dart';
import 'scan_steps_sheet.dart';
import '../../services/ai/cloud_functions.dart';
import 'bill_screen.dart';
import '../../app/app_scope.dart';
import '../../rules/demo_rates.dart';
import '../../rules/exchange_rate.dart';
import '../../services/rate_service.dart';
import 'part_b_result_screen.dart';
import '../../services/ai/photo_kind_classifier.dart';

enum _CameraStatus { starting, ready, unavailable, denied }

/// Camera screen: point at an ATM, take a photo (or choose one), watch the
/// real steps, then open the verdict.
/// Fixed rates for the demo state (CLAUDE.md "Demo data").
const demoRatesAsset = 'assets/data/demo_rates.json';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final _scan = ScanController(
    rateFor: _rateFor,
    classifier: PhotoKindClassifier(),
  );

  /// Fixed demo rates, loaded once; used only in the demo state.
  DemoRates? _demoRates;

  /// THB to [quote]: the fixed demo rate in the demo state, otherwise the
  /// live daily rate (null until it has been fetched).
  RateQuote? _rateFor(String quote) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) return null;
    if (scope.settings.demoState) {
      return _demoRates?.quoteFor(RateService.base, quote);
    }
    return scope.rates.quoteFor(quote);
  }

  final _picker = ImagePicker();
  CameraController? _camera;
  _CameraStatus _cameraStatus = _CameraStatus.starting;
  bool _torch = false;
  bool _capturing = false;
  bool _picking = false;

  /// True while voice haggling is on top; the camera stays off meanwhile.
  bool _otherFlowOpen = false;
  bool _resultOpen = false;
  bool _failureFelt = false;

  late final AnimationController _boxes = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scan.addListener(_onScanChanged);
    _startCamera();
    rootBundle
        .loadString(demoRatesAsset)
        .then((json) => _demoRates = parseDemoRates(json));
    // Card terminals abroad and rate boards are judged against the daily rate.
    final rates = context.getInheritedWidgetOfExactType<AppScope>()?.rates;
    rates?.ensure('JPY');
    rates?.ensure('USD');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scan
      ..removeListener(_onScanChanged)
      ..dispose();
    _camera?.dispose();
    _boxes.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      // Also abandons a start still in flight.
      _cameraGeneration++;
      _camera = null;
      _torch = false;
      camera?.dispose();
    } else if (state == AppLifecycleState.resumed &&
        camera == null &&
        !_picking &&
        !_otherFlowOpen &&
        _scan.state.photoPath == null) {
      _startCamera();
    }
  }

  /// Bumped whenever the camera must stop; a start that finishes under an
  /// older generation disposes its controller instead of showing it.
  int _cameraGeneration = 0;
  bool _cameraStarting = false;

  Future<void> _startCamera() async {
    if (_cameraStarting || _camera != null) return;
    _cameraStarting = true;
    final generation = ++_cameraGeneration;
    try {
      final cameras = await availableCameras();
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (back.isEmpty) {
        _setCameraStatus(_CameraStatus.unavailable);
        return;
      }
      final controller = CameraController(
        back.first,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      // Focus and expose for the framed screen, not the bright surroundings.
      final center = Offset(0.5, AppSizes.scanGuideCenterY);
      try {
        await controller.setFocusPoint(center);
        await controller.setExposurePoint(center);
      } on CameraException {
        // Some cameras have no point focus; continuous auto focus remains.
      }
      // A photo was picked or taken while the camera was starting.
      if (!mounted ||
          generation != _cameraGeneration ||
          _picking ||
          _otherFlowOpen ||
          _scan.state.photoPath != null) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraStatus = _CameraStatus.ready;
      });
    } on CameraException catch (e) {
      _setCameraStatus(
        e.code.contains('AccessDenied')
            ? _CameraStatus.denied
            : _CameraStatus.unavailable,
      );
    } finally {
      _cameraStarting = false;
    }
  }

  /// Releases the camera while a photo is reviewed, so it does not stay on
  /// (battery, heat, the system camera-in-use indicator).
  void _stopCamera() {
    _cameraGeneration++;
    final camera = _camera;
    if (camera == null) return;
    setState(() {
      _camera = null;
      _torch = false;
    });
    camera.dispose();
  }

  void _setCameraStatus(_CameraStatus status) {
    if (mounted) setState(() => _cameraStatus = status);
  }

  void _onScanChanged() {
    final state = _scan.state;
    if (state.lines.isNotEmpty && _boxes.value == 0) {
      _boxes.duration = AppMotion.of(
        context,
        DetectionOverlay.durationFor(DetectionOverlay.valueCount(state.lines)),
      );
      _boxes.forward();
    }
    if (state.hasResult && !_resultOpen) {
      _resultOpen = true;
      // The success haptic plays on the verdict screen, when the amount
      // kept settles, so the user feels the result rather than the hand-off.
      Timer(AppMotion.of(context, AppMotion.resultHold), _openResult);
    } else if (state.failure != null && !_failureFelt) {
      _failureFelt = true;
      HapticFeedback.heavyImpact();
    }
    setState(() {});
  }

  Future<void> _openResult() async {
    final state = _scan.state;
    if (!mounted || !state.hasResult) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.of(context, AppMotion.emphasized),
        reverseTransitionDuration: AppMotion.of(context, AppMotion.standard),
        pageBuilder: (context, _, _) => switch (state) {
          ScanState(dcc: _?) => DccResultScreen(
            state: state,
            demo: AppScope.of(context).settings.demoState,
          ),
          ScanState(board: _?) => BoardResultScreen(
            state: state,
            demo: AppScope.of(context).settings.demoState,
          ),
          _ => AtmResultScreen(state: state),
        },
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
          );
          // Opaque slide from the sheet, so the two screens never mix.
          return SlideTransition(
            position: Tween(
              begin: AppMotion.sheetRise,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
    _retry();
  }

  /// Opens voice haggling; the camera is released while it is open so the
  /// microphone session does not compete with it.
  Future<void> _openHaggle() async {
    _stopCamera();
    _otherFlowOpen = true;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const HaggleScreen()));
    _otherFlowOpen = false;
    if (mounted && _camera == null && _scan.state.photoPath == null) {
      _startCamera();
    }
  }

  /// Opens the bill check. The camera is released while it is open, since
  /// the bill photo is taken with the system camera.
  Future<void> _openBill({String? photoPath}) async {
    _stopCamera();
    _otherFlowOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BillScreen(initialPhotoPath: photoPath),
      ),
    );
    _otherFlowOpen = false;
    if (mounted && _camera == null && _scan.state.photoPath == null) {
      _startCamera();
    }
  }

  void _retry() {
    _resultOpen = false;
    _failureFelt = false;
    _boxes.value = 0;
    _scan.reset();
    if (_camera == null) _startCamera();
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || _capturing || _scan.state.isWorking) return;
    setState(() => _capturing = true);
    HapticFeedback.selectionClick();
    try {
      final view = MediaQuery.sizeOf(context);
      final file = await camera.takePicture();
      _stopCamera();
      await _scan.scanPhoto(
        file.path,
        region: ScanRegion(view: view, guide: scanGuideRect(view)),
      );
    } on CameraException {
      _setCameraStatus(_CameraStatus.unavailable);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _choosePhoto() async {
    if (_picking || _scan.state.isWorking) return;
    _picking = true;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        _stopCamera();
        _picking = false;
        await _scan.scanPhoto(file.path);
      }
    } on PlatformException {
      // The picker is already open or the photo library is unavailable;
      // the camera screen stays as it is.
    } finally {
      _picking = false;
      // Picker cancelled: the system closed the camera while it was open.
      if (mounted && _camera == null && _scan.state.photoPath == null) {
        _startCamera();
      }
    }
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    final next = !_torch;
    await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _torch = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _scan.state;
    final hasPhoto = state.photoPath != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cameraBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              // The whole photo stays visible in a fixed area above the
              // sheet, so it never jumps while the steps arrive and the user
              // can see the button the verdict points to.
              Positioned.fill(
                bottom: AppSizes.scanSheetReserve,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenMargin,
                      AppSizes.cameraControl + AppSpacing.screenMargin,
                      AppSpacing.screenMargin,
                      AppSpacing.lg,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(state.photoPath!), fit: BoxFit.contain),
                        if (state.photoSize != null)
                          AnimatedBuilder(
                            animation: _boxes,
                            builder: (_, _) => DetectionOverlay(
                              lines: state.lines,
                              imageSize: state.photoSize!,
                              progress: _boxes.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              _CameraView(controller: _camera, status: _cameraStatus),
              if (_camera != null) const ScanGuide(),
            ],
            // Keeps the light status bar and top controls legible over a
            // bright preview (DESIGN.md camera scrim).
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: AppSizes.cameraScrimHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cameraScrimTop,
                        AppColors.cameraScrimEnd,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        _GlassButton(
                          icon: Icons.close_rounded,
                          label: l10n.scanClose,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const Spacer(),
                      if (!hasPhoto && CloudFunctions.configured) ...[
                        _GlassButton(
                          icon: Icons.receipt_long_rounded,
                          label: l10n.billOpen,
                          onPressed: _openBill,
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (!hasPhoto) ...[
                        _GlassButton(
                          icon: Icons.mic_rounded,
                          label: l10n.speakOpen,
                          onPressed: _openHaggle,
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (!hasPhoto && _camera != null)
                        _GlassButton(
                          icon: _torch
                              ? Icons.flashlight_off_rounded
                              : Icons.flashlight_on_rounded,
                          label: _torch ? l10n.scanFlashOff : l10n.scanFlashOn,
                          onPressed: _toggleTorch,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.standard),
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(
                    begin: AppMotion.sheetRise,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
                child: hasPhoto
                    ? ScanStepsSheet(
                        key: const ValueKey('sheet'),
                        state: state,
                        onRetry: _retry,
                        onCheckBill: CloudFunctions.configured
                            ? () => _openBill(photoPath: state.photoPath)
                            : null,
                      )
                    : _CaptureControls(
                        key: const ValueKey('controls'),
                        hint: _hint(l10n),
                        canShoot: _camera != null && !_capturing,
                        cameraOff:
                            _cameraStatus == _CameraStatus.unavailable ||
                            _cameraStatus == _CameraStatus.denied,
                        onShoot: _takePhoto,
                        onChoose: _choosePhoto,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hint(AppLocalizations l10n) => switch (_cameraStatus) {
    _CameraStatus.denied => l10n.scanCameraDenied,
    _CameraStatus.unavailable => l10n.scanCameraUnavailable,
    _ => l10n.scanHint,
  };
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller, required this.status});

  final CameraController? controller;
  final _CameraStatus status;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    if (camera == null || !camera.value.isInitialized) {
      return const ColoredBox(color: AppColors.cameraBackground);
    }
    final preview = camera.value.previewSize!;
    // previewSize is reported in landscape; the phone is held upright.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(camera),
        ),
      ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  const _CaptureControls({
    super.key,
    required this.hint,
    required this.canShoot,
    required this.cameraOff,
    required this.onShoot,
    required this.onChoose,
  });

  final String hint;
  final bool canShoot;

  /// No camera (simulator, no permission): choosing a photo becomes the one
  /// action, in the shutter's place, instead of a dead shutter.
  final bool cameraOff;
  final VoidCallback onShoot;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dark glass behind the hint keeps it legible over a bright scene.
            _CameraGlass(
              shape: const StadiumBorder(
                side: BorderSide(
                  color: AppColors.cameraGlassBorder,
                  width: AppSizes.hairline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.standard),
                  curve: AppMotion.move,
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: AppTypography.of(context).label
                        .copyWith(color: AppColors.onSurfaceDark),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (cameraOff)
              _ChoosePhotoButton(
                label: l10n.scanChoosePhoto,
                onPressed: onChoose,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _GlassButton(
                        icon: Icons.photo_library_rounded,
                        label: l10n.scanChoosePhoto,
                        onPressed: onChoose,
                      ),
                    ),
                  ),
                  _Shutter(
                    enabled: canShoot,
                    label: l10n.scanShutter,
                    onPressed: onShoot,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Clips its child to [shape] and lays dark glass under it, with a light
/// hairline so the edge stays visible on pure black.
class _CameraGlass extends StatelessWidget {
  const _CameraGlass({required this.shape, required this.child});

  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlur,
          sigmaY: AppSizes.glassBlur,
        ),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.cameraGlass,
            shape: shape,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shutter: a white ring with a disc that sinks while pressed and springs
/// back on release, and shrinks while the photo is being taken.
class _Shutter extends StatefulWidget {
  const _Shutter({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedOpacity(
          duration: AppMotion.of(context, AppMotion.quick),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: AppSizes.shutter,
            height: AppSizes.shutter,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onSurfaceDark,
                width: AppSpacing.xs,
              ),
            ),
            child: AnimatedScale(
              scale: _down ? AppMotion.shutterPressedScale : 1,
              duration: AppMotion.of(
                context,
                _down ? AppMotion.quick : AppMotion.standard,
              ),
              curve: _down ? AppMotion.move : AppMotion.settle,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one action when there is no camera: a white pill in the shutter's
/// place, the brightest thing on the black screen.
class _ChoosePhotoButton extends StatelessWidget {
  const _ChoosePhotoButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      child: Container(
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: const ShapeDecoration(
          color: AppColors.onSurfaceDark,
          shape: StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_rounded,
              size: AppSizes.cameraIcon,
              color: AppColors.onSurface,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: type.bodyLg),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Pressable(
        semanticLabel: label,
        onPressed: onPressed,
        child: _CameraGlass(
          shape: const CircleBorder(
            side: BorderSide(
              color: AppColors.cameraGlassBorder,
              width: AppSizes.hairline,
            ),
          ),
          child: SizedBox.square(
            dimension: AppSizes.cameraControl,
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: AppSizes.cameraIcon,
                color: AppColors.onSurfaceDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
