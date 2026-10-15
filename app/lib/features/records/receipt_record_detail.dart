import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/receipt_record.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import 'record_detail_page.dart';

/// A saved receipt as a row; opens the receipt with its photo.
class ReceiptRecordRow extends StatelessWidget {
  const ReceiptRecordRow({super.key, required this.record});

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMd(locale)
        .add_Hm()
        .format(record.savedAt.toLocal());
    final name = record.merchantName ?? l10n.billShopUnknown;
    final total = AppFormat.amount(record.totalThb, marketCurrency);
    return Pressable(
      semanticLabel: '$name · $total',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ReceiptRecordDetail(record: record)),
      ),
      child: GroupRow(
        leading: const IconTile(
          icon: Icons.receipt_long_rounded,
          light: AppColors.iconYellowLight,
          dark: AppColors.iconYellow,
        ),
        title: name,
        subtitle: record.isSample ? l10n.saveSampleWhen(date) : date,
        value: total,
        valueStyle: type.rowTitle,
      ),
    );
  }
}

/// One receipt: the photo it was read from, the figures read off it, what
/// it did to cash on hand and where it was paid.
class ReceiptRecordDetail extends StatelessWidget {
  const ReceiptRecordDetail({super.key, required this.record});

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final path = record.photoPath;
    final photo = path != null && File(path).existsSync() ? File(path) : null;
    return RecordDetailPage(
      title: record.merchantName ?? l10n.billShopUnknown,
      heroLabel: l10n.recordReceiptHero,
      heroValue: AppFormat.amount(record.totalThb, marketCurrency),
      savedAt: record.savedAt,
      isSample: record.isSample,
      children: [
        SectionHeader(l10n.recordPhoto, first: true),
        if (photo != null)
          _Photo(file: photo)
        else
          GroupCard(
            children: [
              GroupRow(
                leading: const IconTile(
                  icon: Icons.image_not_supported_rounded,
                  light: AppColors.iconYellowLight,
                  dark: AppColors.iconYellow,
                ),
                title: l10n.receiptPhotoMissing,
              ),
            ],
          ),
        SectionHeader(l10n.recordChecks),
        GroupCard(
          children: [
            GroupRow(
              title: l10n.billShop,
              value: record.merchantName ?? l10n.billShopUnknown,
            ),
            GroupRow(
              title: l10n.billCategory,
              value: spendCategoryName(l10n, record.category),
            ),
            if (record.subtotalThb != null)
              GroupRow(
                title: l10n.billSubtotal,
                value: AppFormat.cents(record.subtotalThb!, marketCurrency),
              ),
            if ((record.discountThb ?? 0) > 0)
              GroupRow(
                title: l10n.billDiscount,
                value:
                    '−${AppFormat.cents(record.discountThb!, marketCurrency)}',
              ),
            if (record.serviceThb != null)
              GroupRow(
                title: l10n.billService,
                value: AppFormat.cents(record.serviceThb!, marketCurrency),
              ),
            if (record.vatThb != null)
              GroupRow(
                title: l10n.billVat,
                subtitle: record.vatOnTop
                    ? l10n.billVatOnTopChip
                    : l10n.billVatInsideChip,
                value: AppFormat.cents(record.vatThb!, marketCurrency),
              ),
            GroupRow(
              title: l10n.billTotal,
              value: AppFormat.cents(record.totalThb, marketCurrency),
              valueStyle: type.rowTitle,
            ),
          ],
        ),
        GroupFooter(
          record.userCorrected
              ? l10n.billCorrectedNote
              : record.verified
              ? l10n.receiptChecked
              : l10n.receiptNotChecked,
        ),
        RecordCashSection(sourceId: record.id),
        RecordPlaceSection(
          placeName: record.placeName,
          lat: record.lat,
          lng: record.lng,
        ),
      ],
    );
  }
}

/// The receipt photo in a card; a tap opens it full screen to zoom.
class _Photo extends StatelessWidget {
  const _Photo({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height =
        (MediaQuery.sizeOf(context).height * AppSizes.tripMapHeightFraction)
            .clamp(AppSizes.tripMapMinHeight, AppSizes.tripMapMaxHeight);
    return Pressable(
      semanticLabel: l10n.recordPhotoOpen,
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _PhotoViewer(file: file),
        ),
      ),
      child: Surface(
        radius: AppRadius.lg,
        color: AppColors.surfaceSunken,
        shadows: AppElevation.e0,
        clip: true,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                l10n.receiptPhotoMissing,
                style: AppTypography.of(context).rowSubtitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: AppSizes.photoMaxZoom,
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: IconButton(
                  tooltip: l10n.tripMapClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceDark,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A spending category in the reader's language.
String spendCategoryName(AppLocalizations l10n, SpendCategory category) =>
    switch (category) {
      SpendCategory.food => l10n.spendFood,
      SpendCategory.transport => l10n.spendTransport,
      SpendCategory.shopping => l10n.spendShopping,
      SpendCategory.lodging => l10n.spendLodging,
      SpendCategory.other => l10n.spendOther,
    };
