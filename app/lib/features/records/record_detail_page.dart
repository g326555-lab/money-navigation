import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/nearby_atms.dart' show isMapPosition;
import '../../shared/app_button.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pill.dart';

/// The page every saved record opens into: a back row, one hero number,
/// then what was read, what it did to cash on hand and where it was.
class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({
    super.key,
    required this.title,
    required this.heroLabel,
    required this.heroValue,
    this.heroColor,
    required this.savedAt,
    required this.isSample,
    required this.children,
  });

  final String title;
  final String heroLabel;
  final String heroValue;
  final Color? heroColor;
  final DateTime savedAt;
  final bool isSample;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final compact = MediaQuery.sizeOf(context).height <= AppSizes.compactHeight;
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
                          child: Text(
                            title,
                            style: type.bodyLg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sectionHeaderInset,
                  ),
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(heroLabel, style: type.heroLabel),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            heroValue,
                            maxLines: 1,
                            style: type.displayLg.copyWith(
                              color: heroColor ?? AppColors.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          DateFormat.yMMMd(locale)
                              .add_Hm()
                              .format(savedAt.toLocal()),
                          style: type.bodyMd.copyWith(
                            color: AppColors.onSurfaceSecondary,
                          ),
                        ),
                        if (isSample) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Pill(
                            label: l10n.recordSample,
                            fill: AppColors.surface,
                            textColor: AppColors.onSurfaceSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.xl : AppSpacing.zoneGap),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What this record did to cash on hand: the linked ledger movement, or
/// that cash did not change. Read from the wallet in view, so a demo
/// record shows the demo ledger and an own record the traveler's.
class RecordCashSection extends StatelessWidget {
  const RecordCashSection({super.key, required this.sourceId});

  final String sourceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final wallet = AppScope.of(context).cashWallet;
    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final linked = [
          for (final m in wallet.movements)
            if (m.sourceId == sourceId) m,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(l10n.cashWalletTitle),
            GroupCard(
              dividerInset: AppSpacing.rowIconTextInset,
              children: [
                if (linked.isEmpty)
                  GroupRow(
                    leading: const IconTile(
                      icon: Icons.payments_rounded,
                      light: AppColors.iconGreenLight,
                      dark: AppColors.iconGreen,
                    ),
                    title: l10n.recordCashNone,
                    subtitle: l10n.recordCashNoneBody,
                  ),
                for (final m in linked)
                  GroupRow(
                    leading: const IconTile(
                      icon: Icons.payments_rounded,
                      light: AppColors.iconGreenLight,
                      dark: AppColors.iconGreen,
                    ),
                    title: m.signedAmount >= 0
                        ? l10n.recordCashAdded
                        : l10n.recordCashSpent,
                    value:
                        '${m.signedAmount >= 0 ? '+' : '−'}'
                        '${AppFormat.roundedAmount(m.signedAmount.abs(), m.currency)}',
                    valueStyle: type.rowTitle.copyWith(
                      color: m.signedAmount >= 0
                          ? AppColors.primaryText
                          : AppColors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Where the record was made, with a way to see it in Google Maps.
class RecordPlaceSection extends StatelessWidget {
  const RecordPlaceSection({
    super.key,
    required this.placeName,
    this.lat,
    this.lng,
  });

  final String? placeName;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final located = isMapPosition(lat, lng);
    final name = placeName;
    if (name == null && !located) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.recordWhere),
        GroupCard(
          children: [
            GroupRow(
              leading: const IconTile.blue(icon: Icons.place_rounded),
              title: name ?? l10n.recordWhere,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.groupGap),
        AppButton.secondary(
          label: l10n.recordOpenInMaps,
          icon: Icons.map_outlined,
          onPressed: () => launchUrl(
            Uri.https('www.google.com', '/maps/search/', {
              'api': '1',
              'query': located ? '$lat,$lng' : name!,
            }),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
