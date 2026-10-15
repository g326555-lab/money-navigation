import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/bill_check.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../services/ai/ai_trace.dart';
import '../../services/ai/bill_reader.dart';
import '../../shared/action_dock.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/pill.dart';

/// Checks a Thai restaurant bill: Google Cloud Vision reads the Thai text,
/// then the phone proves the figures add up and says what was added on top
/// of the food and what is already inside the total.
///
/// Zones: hero (the total, or what is happening), content (how the total
/// was built, then the AI steps that ran), pinned dock.
class BillScreen extends StatefulWidget {
  const BillScreen({super.key, this.reader, this.initialPhotoPath});

  /// Supplied by tests; the screen makes its own otherwise.
  final BillReader? reader;

  /// A photo already taken on the scan screen, read straight away.
  final String? initialPhotoPath;

  @override
  State<BillScreen> createState() => _BillScreenState();
}

enum _Phase { start, reading, done }

class _BillScreenState extends State<BillScreen> {
  late final _reader = widget.reader ?? BillReader();
  final _picker = ImagePicker();
  _Phase _phase = _Phase.start;
  BillReading? _reading;

  @override
  void initState() {
    super.initState();
    final path = widget.initialPhotoPath;
    if (path != null) _read(XFile(path));
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: billPhotoMaxWidth,
        imageQuality: billPhotoQuality,
      );
    } on PlatformException {
      return;
    }
    if (file == null || !mounted) return;
    await _read(file);
  }

  Future<void> _read(XFile file) async {
    setState(() {
      _phase = _Phase.reading;
      _reading = null;
    });
    final reading = await _reader.read(await file.readAsBytes());
    if (!mounted) return;
    reading.check == null
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.successNotification();
    setState(() {
      _phase = _Phase.done;
      _reading = reading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reading = _reading;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ContentWidth(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    0,
                    AppSpacing.screenMargin,
                    AppSpacing.zoneGap + ActionDock.heightOf(context),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      // The glyph, not its touch area, lines up with the text.
                      child: Transform.translate(
                        offset: const Offset(
                          -(AppSizes.minTouchTarget - AppSizes.tabIcon) / 2,
                          0,
                        ),
                        child: IconButton(
                          tooltip: l10n.scanClose,
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.onSurface,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.standard),
                      switchInCurve: AppMotion.enter,
                      child: KeyedSubtree(
                        key: ValueKey(_phase),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: switch (_phase) {
                            _Phase.start => _start(l10n),
                            _Phase.reading => _readingNow(l10n),
                            _Phase.done =>
                              reading?.check == null
                                  ? _failed(l10n, reading)
                                  : _result(l10n, reading!),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActionDock(
                child: DockPair(
                  secondaryLabel: l10n.billChoose,
                  onSecondary: _phase == _Phase.reading
                      ? null
                      : () => _pick(ImageSource.gallery),
                  primaryLabel: _phase == _Phase.start
                      ? l10n.billTake
                      : l10n.billTakeAnother,
                  onPrimary: _phase == _Phase.reading
                      ? null
                      : () => _pick(ImageSource.camera),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _start(AppLocalizations l10n) {
    final type = AppTypography.of(context);
    return [
      Text(l10n.billStartTitle, style: type.headline),
      const SizedBox(height: AppSpacing.md),
      Text(
        l10n.billStartBody,
        style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
      ),
    ];
  }

  List<Widget> _readingNow(AppLocalizations l10n) {
    final type = AppTypography.of(context);
    return [
      Text(l10n.billReading, style: type.heroLabel),
      const SizedBox(height: AppSpacing.lg),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: const LinearProgressIndicator(
          minHeight: AppSizes.progressStroke,
          color: AppColors.primaryText,
          backgroundColor: AppColors.surfaceDim,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        l10n.billReadingBody(AiEngine.cloudVision.displayName),
        style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
      ),
    ];
  }

  List<Widget> _failed(AppLocalizations l10n, BillReading? reading) {
    final type = AppTypography.of(context);
    final (title, body) = switch (reading?.failure) {
      BillFailure.offline => (l10n.billOfflineTitle, l10n.billOfflineBody),
      BillFailure.tooLarge => (l10n.billTooLargeTitle, l10n.billTooLargeBody),
      BillFailure.timeout => (l10n.billTimeoutTitle, l10n.billTimeoutBody),
      BillFailure.noText => (l10n.billNoTextTitle, l10n.billNoTextBody),
      BillFailure.doesNotAddUp => (l10n.billNoMatchTitle, l10n.billNoMatchBody),
      _ => (l10n.billServiceTitle, l10n.billServiceBody),
    };
    return [
      Text(title, style: type.headline),
      const SizedBox(height: AppSpacing.md),
      Text(
        body,
        style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
      ),
      for (final trace in reading?.traces ?? const <AiTrace>[])
        GroupFooter(_traceLine(l10n, trace)),
    ];
  }

  List<Widget> _result(AppLocalizations l10n, BillReading reading) {
    final type = AppTypography.of(context);
    final bill = reading.check!;
    String money(double v) => AppFormat.cents(v, marketCurrency);
    final added = type.rowTitle.copyWith(color: AppColors.errorText);
    return [
      Text(l10n.billTotalLabel, style: type.heroLabel),
      const SizedBox(height: AppSpacing.sm),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: AppFormat.rate(bill.total), style: type.displayLg),
              TextSpan(text: ' $marketCurrency', style: type.title),
            ],
          ),
          maxLines: 1,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (bill.serviceAddedOnTop)
            Pill(
              label: l10n.billServiceChip,
              fill: AppColors.errorContainer,
              textColor: AppColors.errorText,
            ),
          if (bill.vatAddedOnTop)
            Pill(
              label: l10n.billVatOnTopChip,
              fill: AppColors.errorContainer,
              textColor: AppColors.errorText,
            ),
          if (bill.vatIncluded)
            Pill(
              label: l10n.billVatInsideChip,
              fill: AppColors.primaryContainer,
              textColor: AppColors.onPrimaryContainer,
            ),
          if (bill.nothingAdded && !bill.vatIncluded)
            Pill(
              label: l10n.billNothingAddedChip,
              fill: AppColors.primaryContainer,
              textColor: AppColors.onPrimaryContainer,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.zoneGap),
      SectionHeader(l10n.billHowBuilt, first: true),
      GroupCard(
        children: [
          if (bill.subtotal case final v?)
            GroupRow(
              title: bill.kind == BillKind.itemsOnly && bill.itemCount != null
                  ? l10n.billItems(bill.itemCount!)
                  : l10n.billSubtotal,
              value: money(v),
            ),
          if (bill.discount case final v?)
            GroupRow(title: l10n.billDiscount, value: '−${money(v)}'),
          if (bill.serviceCharge case final v?)
            GroupRow(
              title: bill.servicePercent == null
                  ? l10n.billService
                  : l10n.billServicePercent(
                      AppFormat.roundedNumber(bill.servicePercent!),
                    ),
              subtitle: l10n.billAddedOnTop,
              value: '+${money(v)}',
              valueStyle: added,
            ),
          if (bill.vatAddedOnTop && bill.vat != null)
            GroupRow(
              title: _vatTitle(l10n, bill),
              subtitle: l10n.billAddedOnTop,
              value: '+${money(bill.vat!)}',
              valueStyle: added,
            ),
          GroupRow(
            title: l10n.billTotal,
            value: money(bill.total),
            valueStyle: type.rowTitle,
          ),
        ],
      ),
      if (bill.vatIncluded) ...[
        SectionHeader(l10n.billInsideTotal),
        GroupCard(
          children: [
            GroupRow(
              title: _vatTitle(l10n, bill),
              subtitle: l10n.billAlreadyIncluded,
              value: money(bill.vat!),
            ),
            GroupRow(title: l10n.billBeforeVat, value: money(bill.beforeVat!)),
          ],
        ),
      ],
      GroupFooter(l10n.billProof),
      for (final trace in reading.traces) GroupFooter(_traceLine(l10n, trace)),
    ];
  }

  String _vatTitle(AppLocalizations l10n, BillCheck bill) =>
      bill.vatPercent == null
      ? l10n.billVat
      : l10n.billVatPercent(AppFormat.roundedNumber(bill.vatPercent!));

  String _traceLine(AppLocalizations l10n, AiTrace trace) => switch (trace) {
    AiTrace(engine: AiEngine.cloudVision, count: final lines?) =>
      l10n.billVisionTrace(trace.engine.displayName, lines, trace.elapsedLabel),
    // The figures are checked by arithmetic rules, not by AI.
    AiTrace(engine: AiEngine.onDevice) => l10n.billCheckedTrace(
      trace.elapsedLabel,
    ),
    _ => l10n.aiTrace(trace.engine.displayName, trace.elapsedLabel),
  };
}

/// Photos are scaled down before upload, so a receipt stays readable and
/// well under the text reader's size limit.
const double billPhotoMaxWidth = 2000;
const int billPhotoQuality = 85;
