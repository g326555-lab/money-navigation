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
import 'atm_result_screen.dart';
import 'detection_overlay.dart';
import 'scan_controller.dart';
import 'scan_steps_sheet.dart';

enum _CameraStatus { starting, ready, unavailable, denied }

/// Camera screen: point at an ATM, take a photo (or choose one), watch the
/// real steps, then open the verdict.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _scan = ScanController();
  final _picker = ImagePicker();
  CameraController? _camera;
  _CameraStatus _cameraStatus = _CameraStatus.starting;
  bool _torch = false;
  bool _capturing = false;
  bool _picking = false;
  bool _resultOpen = false;

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
      _camera = null;
      _torch = false;
      camera?.dispose();
    } else if (state == AppLifecycleState.resumed &&
        camera == null &&
        !_picking &&
        _scan.state.photoPath == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
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
      // A photo was picked or taken while the camera was starting.
      if (!mounted || _picking || _scan.state.photoPath != null) {
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
    }
  }

  /// Releases the camera while a photo is reviewed, so it does not stay on
  /// (battery, heat, the system camera-in-use indicator).
  void _stopCamera() {
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
      _boxes.duration = AppMotion.of(context, AppMotion.emphasized);
      _boxes.forward();
    }
    if (state.verdict != null && !_resultOpen) {
      _resultOpen = true;
      HapticFeedback.mediumImpact();
      Timer(AppMotion.of(context, AppMotion.resultHold), _openResult);
    } else if (state.failure != null) {
      HapticFeedback.heavyImpact();
    }
    setState(() {});
  }

  Future<void> _openResult() async {
    final state = _scan.state;
    if (!mounted || state.verdict == null) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.of(context, AppMotion.standard),
        reverseTransitionDuration: AppMotion.of(context, AppMotion.standard),
        pageBuilder: (_, _, _) => AtmResultScreen(state: state),
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

  void _retry() {
    _resultOpen = false;
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
      final file = await camera.takePicture();
      _stopCamera();
      await _scan.scanPhoto(file.path);
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
                              progress: AppMotion.enter.transform(_boxes.value),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _CameraView(controller: _camera, status: _cameraStatus),
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
                      )
                    : _CaptureControls(
                        key: const ValueKey('controls'),
                        hint: _hint(l10n),
                        canShoot: _camera != null && !_capturing,
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
    required this.onShoot,
    required this.onChoose,
  });

  final String hint;
  final bool canShoot;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppSizes.glassBlur,
                  sigmaY: AppSizes.glassBlur,
                ),
                child: ColoredBox(
                  color: AppColors.cameraGlass,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: AppTypography.of(context).label
                          .copyWith(color: AppColors.onSurfaceDark),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _GlassButton(
                      icon: Icons.photo_library_outlined,
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

class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: AppMotion.of(context, AppMotion.quick),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: AppSizes.shutter,
            height: AppSizes.shutter,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onSurfaceDark,
                width: AppSpacing.xs,
              ),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.onSurfaceDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
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
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppSizes.glassBlur,
              sigmaY: AppSizes.glassBlur,
            ),
            child: ColoredBox(
              color: AppColors.cameraGlass,
              child: SizedBox.square(
                dimension: AppSizes.cameraControl,
                child: Icon(icon, color: AppColors.onSurfaceDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
