import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/bill_check.dart';
import '../../rules/haggle.dart' show marketCurrency, maxPriceThb;
import '../../services/ai/ai_trace.dart';
import '../../services/ai/bill_reader.dart';
import '../../shared/action_dock.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/pill.dart';
import '../../data/receipt_store.dart';
import '../../rules/receipt_record.dart';
import '../briefing/places_client.dart';
import '../records/receipt_record_detail.dart' show spendCategoryName;
import '../../shared/app_button.dart';
import '../../shared/surface.dart';
import '../../shared/pressable.dart';
import '../../services/location_service.dart';

/// Checks a Thai restaurant bill: Google Cloud Vision reads the Thai text,
/// then the phone proves the figures add up and says what was added on top
/// of the food and what is already inside the total.
///
/// Zones: hero (the total, or what is happening), content (how the total
/// was built, then the AI steps that ran), pinned dock.
class BillScreen extends StatefulWidget {
  const BillScreen({
    super.key,
    this.reader,
    this.initialPhotoPath,
    this.location,
    this.places,
  });

  /// Supplied by tests; the screen makes its own otherwise.
  final BillReader? reader;

  /// A photo already taken on the scan screen, read straight away.
  final String? initialPhotoPath;

  /// Where the phone is; [LocationService.current] when not supplied.
  final Future<({double latitude, double longitude})?> Function()? location;

  /// Supplied by tests; otherwise uses the project's Google Places function.
  final PlacesClient? places;

  @override
  State<BillScreen> createState() => _BillScreenState();
}

enum _Phase { start, reading, done }

class _BillScreenState extends State<BillScreen> {
  late final _reader = widget.reader ?? BillReader();
  late final _places = widget.places ?? PlacesClient();
  final _picker = ImagePicker();
  _Phase _phase = _Phase.start;
  BillReading? _reading;

  /// What would be saved: the proven bill, or the traveler's correction.
  ReceiptRecord? _record;
  bool _saved = false;
  bool? _savedAsCash;
  bool _categoryFromGoogle = false;
  bool _categoryManuallyChosen = false;
  final _receipts = ReceiptStore.shared;

  /// Once a bill has been read, the camera button offers another one, and
  /// keeps that label while the next photo is read.
  bool _readOnce = false;
  String? _photoSourcePath;

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
      _photoSourcePath = file.path;
    });
    // Where the bill is being paid: fetched alongside the reading, so the
    // record knows its shop's place from the start (same shop vs another
    // branch) and lands on the trip map. Null when location is off.
    final placeFuture = widget.location != null
        ? widget.location!()
        : LocationService.current().then(
            (p) => p == null
                ? null
                : (latitude: p.latitude, longitude: p.longitude),
          );
    final reading = await _reader.read(await file.readAsBytes());
    final here = await placeFuture;
    if (!mounted) return;
    reading.check == null
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.successNotification();
    await _receipts.load();
    if (!mounted) return;
    final check = reading.check;
    final now = DateTime.now();
    setState(() {
      _phase = _Phase.done;
      _reading = reading;
      _readOnce = true;
      _saved = false;
      _savedAsCash = null;
      _categoryFromGoogle = false;
      _categoryManuallyChosen = false;
      // A payment slip that prints only its total: kept as read, marked
      // not verified, so it can still be saved and corrected.
      _record = check == null
          ? switch (reading.printedTotal) {
              final total? => ReceiptRecord(
                id: 'bill-${now.microsecondsSinceEpoch}',
                savedAt: now,
                totalThb: total,
                verified: false,
                merchantName: reading.merchantName,
                lat: here?.latitude,
                lng: here?.longitude,
                category: categorize(merchantName: reading.merchantName),
              ),
              null => null,
            }
          : ReceiptRecord.fromCheck(
              check,
              id: 'bill-${now.microsecondsSinceEpoch}',
              savedAt: now,
              merchantName: reading.merchantName,
              lat: here?.latitude,
              lng: here?.longitude,
              category: categorize(merchantName: reading.merchantName),
            );
      _here = here == null ? null : (here.latitude, here.longitude);
    });
    final merchant = reading.merchantName;
    if (reading.check != null && merchant != null && here != null) {
      _places.languageCode = Localizations.localeOf(context).languageCode;
      unawaited(_lookupCategory(merchant, here.latitude, here.longitude));
    }
  }

  Future<void> _lookupCategory(String merchant, double lat, double lng) async {
    final place = await _places.lookup(merchant, lat: lat, lng: lng);
    if (!mounted || place == null || place.types.isEmpty) return;
    final record = _record;
    if (record == null || _categoryManuallyChosen) return;
    final category = categorize(
      placeTypes: place.types,
      merchantName: merchant,
    );
    final fromGoogle = hasCategoryPlaceType(place.types);
    if (record.category == category && _categoryFromGoogle == fromGoogle) {
      return;
    }
    final updated = record.withCategory(category);
    setState(() {
      _record = updated;
      _categoryFromGoogle = fromGoogle;
    });
    if (_saved) await _receipts.save(updated);
  }

  /// Where the phone was when the bill was read.
  (double, double)? _here;

  Future<void> _save() async {
    final record = _record;
    if (record == null || _saved) return;
    final cash = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _BillPaymentSheet(),
    );
    if (cash == null || !mounted) return;
    final scope = AppScope.of(context);
    await scope.cashWallet.setLinkedSpend(
      sourceId: record.id,
      amount: cash ? record.totalThb : null,
      currency: marketCurrency,
      description: AppLocalizations.of(context).cashWalletBill,
      at: record.savedAt,
    );
    var savedRecord = record;
    final photoSourcePath = _photoSourcePath;
    if (photoSourcePath != null && File(photoSourcePath).existsSync()) {
      final directory = await getApplicationSupportDirectory();
      final receiptDirectory = Directory('${directory.path}/receipts');
      await receiptDirectory.create(recursive: true);
      final photo = await File(photoSourcePath).copy(
        '${receiptDirectory.path}/${record.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.jpg',
      );
      savedRecord = record.withPhotoPath(photo.path);
      setState(() => _record = savedRecord);
    }
    // The phone copy is written at once; the account copy follows in the
    // background, so "Saved" never waits on the network.
    await _receipts.save(savedRecord);
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _saved = true;
        _savedAsCash = cash;
      });
    }
  }

  /// The traveler fixes what was read, or enters a bill the phone could not
  /// prove. The result is kept as their correction, never as verified.
  Future<void> _edit() async {
    final now = DateTime.now();
    final base =
        _record ??
        ReceiptRecord(
          id: 'bill-${now.microsecondsSinceEpoch}',
          savedAt: now,
          totalThb: 0,
          verified: false,
          merchantName: _reading?.merchantName,
          lat: _here?.$1,
          lng: _here?.$2,
          category: categorize(merchantName: _reading?.merchantName),
        );
    final edited = await showModalBottomSheet<ReceiptRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReceiptEditSheet(record: base),
    );
    if (edited == null || !mounted) return;
    setState(() {
      final changedCategory = _record?.category != edited.category;
      _record = edited;
      _saved = false;
      _savedAsCash = null;
      if (changedCategory) {
        _categoryFromGoogle = false;
        _categoryManuallyChosen = true;
      }
    });
  }

  /// Lines from the traveler's own saved bills at this shop; none when
  /// there is no history.
  List<Widget> _memory(AppLocalizations l10n, ReceiptRecord record) {
    final now = DateTime.now();
    final history = [
      for (final r in _receipts.records)
        if (r.id != record.id) r,
    ];
    final memory = merchantMemory(record, history, now);
    // Same name elsewhere is another branch: its habits, never a "visit".
    final brand = memory == null ? brandMemory(record, history, now) : null;
    final hint = formatHint(record, history, now);
    String money(double v) => AppFormat.cents(v, marketCurrency);
    String? brandHabit(BrandMemory b) {
      if (b.noServiceRecords == b.records) return l10n.billNoteNoService;
      if (b.serviceIncludedRecords == b.records) {
        return l10n.billNoteServiceIncluded;
      }
      if (b.serviceAddedRecords == b.records) return l10n.billBrandServiceAdded;
      return null;
    }

    return [
      if (memory != null)
        GroupFooter(
          l10n.billMemoryVisits(memory.visits, money(memory.lastTotalThb)),
        ),
      if (brand != null)
        if (brandHabit(brand) case final habit?)
          GroupFooter(l10n.billBrandMemory(habit, brand.records)),
      if (hint != null)
        GroupFooter(
          (hint.sameShop ? l10n.billMemoryNote : l10n.billMemoryNoteBranch)(
            hint.serviceIncluded
                ? l10n.billNoteServiceIncluded
                : hint.servicePercent != null
                ? l10n.billNoteServiceAdded(
                    AppFormat.roundedNumber(hint.servicePercent!),
                  )
                : l10n.billNoteNoService,
            hint.fromRecords,
          ),
        ),
    ];
  }

  Widget _recordActions(AppLocalizations l10n, ReceiptRecord? record) {
    return Column(
      children: [
        if (_savedAsCash != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: GroupFooter(
              _savedAsCash! ? l10n.cashWalletBillCash : l10n.cashWalletBillCard,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: DockPair(
            secondaryLabel: record == null ? l10n.billEnterIt : l10n.billEdit,
            onSecondary: _edit,
            primaryLabel: _saved ? l10n.billSaved : l10n.billSave,
            onPrimary: record == null || _saved || record.totalThb <= 0
                ? null
                : _save,
          ),
        ),
      ],
    );
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
                  primaryLabel: _readOnce
                      ? l10n.billTakeAnother
                      : l10n.billTake,
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
      BillFailure.doesNotAddUp when reading?.printedTotal != null => (
        l10n.billSlipTitle,
        l10n.billSlipBody,
      ),
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
      // The text was read but could not be proven: the traveler may enter
      // the bill themselves, kept as their own record.
      if (reading?.failure == BillFailure.doesNotAddUp) ...[
        if (_record case final r?) ..._correctionRows(l10n, r),
        _recordActions(l10n, _record),
      ],
    ];
  }

  List<Widget> _correctionRows(AppLocalizations l10n, ReceiptRecord r) => [
    SectionHeader(l10n.billYourRecord),
    GroupCard(
      children: [
        GroupRow(
          title: l10n.billShop,
          value: r.merchantName ?? l10n.billShopUnknown,
        ),
        GroupRow(
          title: l10n.billCategory,
          value: spendCategoryName(l10n, r.category),
        ),
        GroupRow(
          title: l10n.billTotal,
          value: AppFormat.cents(r.totalThb, marketCurrency),
        ),
      ],
    ),
    GroupFooter(
      r.userCorrected ? l10n.billCorrectedNote : l10n.receiptNotChecked,
    ),
  ];

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
      if (_record case final r?) ...[
        SectionHeader(l10n.billYourRecord),
        GroupCard(
          children: [
            GroupRow(
              title: l10n.billShop,
              value: r.merchantName ?? l10n.billShopUnknown,
            ),
            GroupRow(
              title: l10n.billCategory,
              value: spendCategoryName(l10n, r.category),
            ),
            if (r.userCorrected)
              GroupRow(
                title: l10n.billTotal,
                value: AppFormat.cents(r.totalThb, marketCurrency),
              ),
          ],
        ),
        GroupFooter(
          _categoryManuallyChosen
              ? l10n.billCategoryManual
              : _categoryFromGoogle
              ? l10n.billCategoryGoogle
              : l10n.billCategoryName,
        ),
        if (r.userCorrected) GroupFooter(l10n.billCorrectedNote),
        ..._memory(l10n, r),
      ],
      _recordActions(l10n, _record),
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

/// The traveler's own version of a bill: shop name, total, and how service
/// and VAT were charged.
class _ReceiptEditSheet extends StatefulWidget {
  const _ReceiptEditSheet({required this.record});

  final ReceiptRecord record;

  @override
  State<_ReceiptEditSheet> createState() => _ReceiptEditSheetState();
}

enum _Service { none, added, included }

class _ReceiptEditSheetState extends State<_ReceiptEditSheet> {
  late final _name = TextEditingController(
    text: widget.record.merchantName ?? '',
  );
  late final _total = TextEditingController(
    text: widget.record.totalThb > 0
        ? AppFormat.rate(widget.record.totalThb)
        : '',
  );
  late final _percent = TextEditingController(
    text: widget.record.servicePercent == null
        ? ''
        : AppFormat.roundedNumber(widget.record.servicePercent!),
  );
  late _Service _service = widget.record.serviceIncluded
      ? _Service.included
      : widget.record.servicePercent != null || widget.record.serviceThb != null
      ? _Service.added
      : _Service.none;
  late bool _vatOnTop = widget.record.vatOnTop;
  late SpendCategory _category = widget.record.category;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _total, _percent]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _percent.dispose();
    super.dispose();
  }

  /// "125,50" is a decimal comma; "1,250" and "1,250.50" group thousands.
  double? _number(TextEditingController c) {
    final t = c.text.trim();
    if (_decimalComma.hasMatch(t)) {
      return double.tryParse(t.replaceAll(',', '.'));
    }
    return double.tryParse(t.replaceAll(',', ''));
  }

  static final _decimalComma = RegExp(r'^\d+,\d{1,2}$');

  bool get _totalValid {
    final total = _number(_total);
    return total != null && total > 0 && total <= maxPriceThb;
  }

  bool get _valid {
    if (!_totalValid) return false;
    if (_service == _Service.added) {
      final p = _number(_percent);
      return p != null && p > 0 && p < 100;
    }
    return true;
  }

  bool get _financialChanged {
    final r = widget.record;
    final service = r.serviceIncluded
        ? _Service.included
        : r.servicePercent != null || r.serviceThb != null
        ? _Service.added
        : _Service.none;
    return _name.text.trim() != (r.merchantName ?? '') ||
        _number(_total) != r.totalThb ||
        _service != service ||
        (_service == _Service.added && _number(_percent) != r.servicePercent) ||
        _vatOnTop != r.vatOnTop;
  }

  bool get _changed => _financialChanged || _category != widget.record.category;

  void _done() {
    if (!_valid) return;
    // Nothing changed: keep the proven record as it was.
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    if (!_financialChanged) {
      Navigator.of(context).pop(widget.record.withCategory(_category));
      return;
    }
    final name = _name.text.trim();
    final edited = widget.record.corrected(
      totalThb: _number(_total),
      servicePercent: _service == _Service.added ? _number(_percent) : null,
      serviceIncluded: _service == _Service.included,
      // "No service charge" must clear what was read, not keep it.
      serviceCharged: _service != _Service.none,
      vatOnTop: _vatOnTop,
      category: _category,
    );
    Navigator.of(context).pop(
      ReceiptRecord.fromJson({
        ...edited.toJson(),
        'merchantName': name.isEmpty ? null : name,
        if (_service != _Service.added) 'servicePercent': null,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    Widget field(
      TextEditingController c,
      String label, {
      bool number = false,
      String? suffix,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: type.sectionHeader),
        const SizedBox(height: AppSpacing.sm),
        Surface(
          radius: AppRadius.sm,
          color: AppColors.surfaceSunken,
          child: TextField(
            controller: c,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: number
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(billAmountChars),
                  ]
                : null,
            style: number ? type.title : type.bodyLg,
            decoration: InputDecoration(
              suffixText: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
    Widget choice(String label, bool selected, VoidCallback onTap) => Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onTap,
        semanticLabel: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            widthFactor: 1,
            child: Pill(
              label: label,
              fill: selected ? AppColors.surfaceDark : AppColors.surfaceDim,
              textColor: selected
                  ? AppColors.onSurfaceDark
                  : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          0,
          AppSpacing.sheetPadding,
          AppSpacing.sheetPadding + insets,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billEditTitle, style: type.title),
            const SizedBox(height: AppSpacing.xl),
            field(_name, l10n.billShop),
            Text(l10n.billCategoryEdit, style: type.sectionHeader),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in SpendCategory.values)
                  choice(
                    spendCategoryName(l10n, category),
                    _category == category,
                    () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            field(_total, l10n.billTotal, number: true, suffix: marketCurrency),
            if (_total.text.isNotEmpty && !_totalValid) ...[
              Text(
                l10n.billTotalInvalid(
                  AppFormat.roundedAmount(maxPriceThb, marketCurrency),
                ),
                style: type.caption.copyWith(color: AppColors.errorText),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(l10n.billService, style: type.sectionHeader),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                choice(
                  l10n.billServiceNone,
                  _service == _Service.none,
                  () => setState(() => _service = _Service.none),
                ),
                choice(
                  l10n.billAddedOnTop,
                  _service == _Service.added,
                  () => setState(() => _service = _Service.added),
                ),
                choice(
                  l10n.billServiceIncludedChoice,
                  _service == _Service.included,
                  () => setState(() => _service = _Service.included),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_service == _Service.added)
              field(
                _percent,
                l10n.billServicePercentLabel,
                number: true,
                suffix: '%',
              ),
            Text(l10n.billVat, style: type.sectionHeader),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                choice(
                  l10n.billVatInsideChip,
                  !_vatOnTop,
                  () => setState(() => _vatOnTop = false),
                ),
                choice(
                  l10n.billVatOnTopChip,
                  _vatOnTop,
                  () => setState(() => _vatOnTop = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.billUseCorrection,
              onPressed: _valid ? _done : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillPaymentSheet extends StatelessWidget {
  const _BillPaymentSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sheetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cashPaymentMethod, style: type.title),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.cashPaymentExplainer,
              style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.cashPaymentCash,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: l10n.cashPaymentCard,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Room for a grouped amount like "123,456.78".
const billAmountChars = 12;
