import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../data/card_catalog_repository.dart';
import '../../rules/card_catalog.dart';
import '../../rules/personal_context.dart';
import '../../services/text_recognition_service.dart';
import '../../shared/app_button.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../home/home_metrics.dart';
import 'card_face.dart';
import 'card_picker_screen.dart';
import 'card_profile_store.dart';

/// Wide enough for the printed name on a card photo; small enough to read
/// quickly on the phone.
const cardPhotoMaxWidth = 1600.0;

/// Edits the card's foreign fee and the home bank's ATM fee.
Future<void> showCardFactsSheet(
  BuildContext context,
  CardProfileStore store,
  String homeCurrency,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: false,
  backgroundColor: Colors.transparent,
  builder: (_) => _CardFactsSheet(store: store, homeCurrency: homeCurrency),
);

class _CardFactsSheet extends StatefulWidget {
  const _CardFactsSheet({required this.store, required this.homeCurrency});

  final CardProfileStore store;
  final String homeCurrency;

  @override
  State<_CardFactsSheet> createState() => _CardFactsSheetState();
}

class _CardFactsSheetState extends State<_CardFactsSheet> {
  late final _fee = TextEditingController(
    text: _plain(widget.store.profile.cardFeePercent),
  );
  late final _atmValue = TextEditingController(
    text: _plain(widget.store.profile.atmFeeValue),
  );
  late AtmFeePolicy _policy = widget.store.profile.atmFeePolicy;
  late String? _productId = widget.store.productId;
  String? _error;

  final _catalog = CardCatalogRepository();
  List<CatalogCard> _cards = const [];
  CatalogCard? _card;

  /// A card the photo matched, waiting for the traveler's yes.
  CatalogCard? _pending;
  bool _scanning = false;
  bool _scanMissed = false;

  @override
  void initState() {
    super.initState();
    _catalog.load().then((cards) {
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _card = cards.where((c) => c.id == _productId).firstOrNull;
      });
    });
  }

  /// Takes the card's fees and ATM policy from its catalogue entry.
  void _use(CatalogCard card) {
    final profile = profileFromCard(card, homeCurrency: widget.homeCurrency);
    HapticFeedback.selectionClick();
    setState(() {
      _card = card;
      _pending = null;
      _scanMissed = false;
      _productId = card.id;
      _fee.text = _plain(profile.cardFeePercent);
      _policy = profile.atmFeePolicy;
      _atmValue.text = _plain(profile.atmFeeValue);
      _error = null;
    });
  }

  Future<void> _choose() async {
    final chosen = await Navigator.of(context).push<CatalogCard>(
      MaterialPageRoute(
        builder: (_) => CardPickerScreen(
          cards: _cards,
          homeCurrency: widget.homeCurrency,
          selectedId: _productId,
        ),
      ),
    );
    if (chosen != null && mounted) _use(chosen);
  }

  /// Photo of the card's front, read on the phone and deleted at once.
  /// Only letters are compared; digits never leave cardFaceWords.
  Future<void> _scan() async {
    final XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: cardPhotoMaxWidth,
      );
    } on PlatformException {
      return;
    }
    if (photo == null || !mounted) return;
    setState(() {
      _scanning = true;
      _scanMissed = false;
      _pending = null;
    });
    final reader = TextRecognitionService();
    List<CatalogCard> found = const [];
    try {
      final read = await reader.readFile(photo.path);
      found = matchCardFace(read.lines.map((l) => l.text).join('\n'), _cards);
    } on Object {
      found = const [];
    } finally {
      await reader.close();
      try {
        await File(photo.path).delete();
      } on Object {
        // The picker's temporary copy; the system clears it anyway.
      }
    }
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _pending = found.firstOrNull;
      _scanMissed = found.isEmpty;
    });
  }

  /// The chosen card's face at a card's real proportions, never wider
  /// than a card held at arm's length on a big screen.
  Widget _bigFace(CatalogCard card) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.cardFaceMaxWidth),
      child: CardFace(card: card),
    ),
  );

  List<Widget> _cardSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final pending = _pending;
    final card = _card;
    return [
      if (pending != null) ...[
        _bigFace(pending),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.cardScanConfirm, style: type.title),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: l10n.haggleNo,
                onPressed: () => setState(() {
                  _pending = null;
                  _scanMissed = true;
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton.green(
                label: l10n.haggleYes,
                onPressed: () => _use(pending),
              ),
            ),
          ],
        ),
      ] else if (card != null) ...[
        _bigFace(card),
        const SizedBox(height: AppSpacing.md),
        Text(cardFeeLine(l10n, card), style: type.rowTitle),
        Text(l10n.cardFilled, style: type.footer),
        if (card.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.cardFromIssuer, style: type.label),
          for (final b in card.benefits)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('\u2022 ${b.of(language)}', style: type.rowSubtitle),
            ),
        ],
        for (final n in card.notes)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(n.of(language), style: type.footer),
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final s in card.sources)
          Pressable(
            onPressed: () => launchUrl(
              Uri.parse(s.url),
              mode: LaunchMode.externalApplication,
            ),
            semanticLabel: s.label,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cardSourceLine(context, l10n, s),
                  style: type.link.copyWith(color: AppColors.primaryText),
                ),
              ),
            ),
          ),
      ],
      if (_scanning) ...[
        const SizedBox(height: AppSpacing.md),
        Text(l10n.cardScanReading, style: type.rowSubtitle),
      ] else if (_scanMissed) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.cardScanNoMatch,
          style: type.label.copyWith(color: AppColors.onSurfaceSecondary),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      if (_cards.isNotEmpty)
        AppButton.secondary(
          label: card == null ? l10n.cardChooseList : l10n.cardChange,
          icon: Icons.list_rounded,
          onPressed: _choose,
        ),
      const SizedBox(height: AppSpacing.sm),
      if (_cards.isNotEmpty)
        AppButton.secondary(
          label: l10n.cardScan,
          icon: Icons.photo_camera_outlined,
          onPressed: _scanning ? null : _scan,
        ),
      if (_cards.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.cardScanPrivacy, style: type.footer),
      ],
      if (card != null)
        Pressable(
          onPressed: () => setState(() {
            _card = null;
            _productId = null;
          }),
          semanticLabel: l10n.cardNotThis,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.cardNotThis, style: type.link),
            ),
          ),
        ),
    ];
  }

  static String _plain(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _fee.dispose();
    _atmValue.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final feeText = _fee.text.replaceAll(',', '.').trim();
    final fee = feeText.isEmpty ? null : double.tryParse(feeText);
    if (feeText.isNotEmpty &&
        (fee == null || fee < 0 || fee > CardProfileStore.maxFeePercent)) {
      setState(() => _error = l10n.cardFeeInvalid);
      return;
    }
    final needsValue =
        _policy == AtmFeePolicy.chargesFixed ||
        _policy == AtmFeePolicy.chargesPercent;
    final value = double.tryParse(_atmValue.text.replaceAll(',', '.').trim());
    if (needsValue && (value == null || value < 0)) {
      setState(() => _error = l10n.cardAtmValueInvalid);
      return;
    }
    await widget.store.setCardFee(fee);
    await widget.store.setAtmPolicy(_policy, value: needsValue ? value : null);
    await widget.store.setProductId(_productId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final policies = {
      AtmFeePolicy.unknown: l10n.cardAtmUnknown,
      AtmFeePolicy.noFee: l10n.cardAtmNoFee,
      AtmFeePolicy.refundsFees: l10n.cardAtmRefunds,
      AtmFeePolicy.chargesFixed: l10n.cardAtmFixed(widget.homeCurrency),
      AtmFeePolicy.chargesPercent: l10n.cardAtmPercent,
    };
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Grabber(),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.cardSheetTitle, style: type.title),
                const SizedBox(height: AppSpacing.lg),
                ..._cardSection(context),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.cardManual, style: type.sectionHeader),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.cardFeeLabel, style: type.rowTitle),
                const SizedBox(height: AppSpacing.sm),
                _Field(controller: _fee, suffix: '%'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.homeCurrency == 'THB'
                      ? l10n.cardFeeHintThai
                      : l10n.cardFeeHintOther,
                  style: type.footer,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.cardAtmLabel, style: type.rowTitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final e in policies.entries)
                      _Choice(
                        label: e.value,
                        selected: _policy == e.key,
                        onPressed: () => setState(() => _policy = e.key),
                      ),
                  ],
                ),
                if (_policy == AtmFeePolicy.chargesFixed ||
                    _policy == AtmFeePolicy.chargesPercent) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Field(
                    controller: _atmValue,
                    suffix: _policy == AtmFeePolicy.chargesFixed
                        ? widget.homeCurrency
                        : '%',
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: type.label.copyWith(color: AppColors.errorText),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(l10n.cardSheetPrivacy, style: type.footer),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: l10n.cardSheetSave, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: HomeMetrics.grabberWidth,
      height: HomeMetrics.grabberHeight,
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: AppColors.handle,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.suffix});

  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Surface(
      radius: AppRadius.md,
      color: AppColors.surfaceSunken,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: type.title.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          Text(suffix, style: type.bodyLg),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: selected ? AppColors.surfaceDark : AppColors.surfaceSunken,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: type.label.copyWith(
                color: selected ? AppColors.onSurfaceDark : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
