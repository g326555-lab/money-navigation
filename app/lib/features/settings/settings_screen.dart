import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/demo_switch.dart';
import '../../core/colors.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import '../../shared/content_width.dart';
import '../auth/account_section.dart';
import '../auth/auth_gate.dart' show AuthScope;
import 'photo_credits.dart';

/// The traveler's own currency and how the app speaks Thai for them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return _Page(
      title: l10n.settingsTitle,
      child: ListenableBuilder(
        listenable: Listenable.merge([scope.settings, scope.rates]),
        builder: (context, _) {
          final settings = scope.settings;
          final code = settings.homeCurrency;
          final name = scope.rates.currencies[code];
          // Only under the sign-in gate (absent in previews and tests).
          final account =
              context.getInheritedWidgetOfExactType<AuthScope>() != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (account) const AccountSection(first: true),
              SectionHeader(l10n.settingsCurrency, first: !account),
              GroupCard(
                children: [
                  _TapRow(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CurrencyPickerScreen(),
                      ),
                    ),
                    child: GroupRow(
                      title: name ?? code,
                      subtitle: name == null ? null : code,
                      value: l10n.settingsChange,
                      valueStyle: AppTypography.of(context).link,
                    ),
                  ),
                ],
              ),
              GroupFooter(l10n.settingsCurrencyFooter),
              SectionHeader(l10n.settingsSpeaking),
              GroupCard(
                children: [
                  for (final ending in PoliteEnding.values)
                    _ChoiceRow(
                      title: _endingTitle(l10n, ending),
                      subtitle: l10n.settingsEndingExample(
                        endingText(l10n, ending),
                      ),
                      selected: settings.politeEnding == ending,
                      onPressed: () => settings.setPoliteEnding(ending),
                    ),
                ],
              ),
              GroupFooter(l10n.settingsSpeakingFooter),
              // Offered only when the demo file could be read.
              if (scope.demoPersonas case final demo?) ...[
                SectionHeader(l10n.settingsDemo),
                GroupCard(
                  children: [
                    _ChoiceRow(
                      title: l10n.settingsDemoOff,
                      subtitle: l10n.settingsDemoOffHint,
                      selected: !settings.demoState,
                      onPressed: () => DemoSwitch.to(context, null),
                    ),
                    for (final persona in demo.personas)
                      _ChoiceRow(
                        title: demoPersonaName(l10n, persona),
                        subtitle: l10n.settingsDemoPersonaHint(
                          demoPersonaDetail(l10n, persona),
                        ),
                        selected: settings.demoPersona?.key == persona.key,
                        onPressed: () => DemoSwitch.to(context, persona),
                      ),
                  ],
                ),
                GroupFooter(l10n.settingsDemoFooter),
              ],
              SectionHeader(l10n.settingsAbout),
              GroupCard(
                children: [
                  _TapRow(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreditsScreen(),
                      ),
                    ),
                    child: GroupRow(title: l10n.settingsCredits),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _endingTitle(AppLocalizations l10n, PoliteEnding ending) =>
      switch (ending) {
        PoliteEnding.male => l10n.settingsEndingMale,
        PoliteEnding.female => l10n.settingsEndingFemale,
        PoliteEnding.none => l10n.settingsEndingNone,
      };
}

/// The Thai particle that ends a polite question for [ending].
String endingText(AppLocalizations l10n, PoliteEnding ending) =>
    switch (ending) {
      PoliteEnding.male => l10n.politeEndingMale,
      PoliteEnding.female => l10n.politeEndingFemale,
      PoliteEnding.none => '',
    };

/// The particle that ends a polite statement ("ตกลง 125 บาทค่ะ"); women
/// use ค่ะ in statements and คะ in questions.
String statementEndingText(AppLocalizations l10n, PoliteEnding ending) =>
    switch (ending) {
      PoliteEnding.male => l10n.politeEndingMale,
      PoliteEnding.female => l10n.politeEndingFemaleStatement,
      PoliteEnding.none => '',
    };

/// Every currency the daily rate source covers.
class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  @override
  void initState() {
    super.initState();
    context.getInheritedWidgetOfExactType<AppScope>()!.rates.loadCurrencies();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return _Page(
      title: l10n.settingsCurrency,
      child: ListenableBuilder(
        listenable: Listenable.merge([scope.settings, scope.rates]),
        builder: (context, _) {
          final currencies = scope.rates.currencies.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final selected = scope.settings.homeCurrency;
          if (currencies.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sectionHeaderInset,
              ),
              child: Text(
                l10n.currencyOffline,
                style: AppTypography.of(context).bodyMd
                    .copyWith(color: AppColors.onSurfaceSecondary),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GroupCard(
                children: [
                  for (final c in currencies)
                    _ChoiceRow(
                      title: c.value,
                      subtitle: c.key,
                      selected: c.key == selected,
                      onPressed: () async {
                        await scope.settings.setHomeCurrency(c.key);
                        scope.rates.ensure(c.key);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              GroupFooter(l10n.currencySource),
            ],
          );
        },
      ),
    );
  }
}

/// Authors and licences of the photos the photo-kind model learned from.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final Future<List<PhotoCredit>?> _credits = DefaultAssetBundle.of(
    context,
  ).loadString(photoCreditsAsset).then(parsePhotoCredits);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _credits,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final credits = snapshot.data;
        if (!done || credits == null || snapshot.hasError) {
          return _Page(
            title: l10n.settingsCredits,
            child: done
                ? GroupFooter(l10n.creditsUnavailable)
                : const SizedBox.shrink(),
          );
        }
        // 442 rows: built only as they scroll into view.
        return _Page(
          title: l10n.settingsCredits,
          header: GroupFooter(l10n.settingsCreditsHint(credits.length)),
          itemCount: credits.length,
          itemBuilder: (context, i) => _CreditRow(
            credit: credits[i],
            first: i == 0,
            last: i == credits.length - 1,
          ),
          child: GroupFooter(l10n.creditsFooter),
        );
      },
    );
  }
}

/// One credit as a row of a grouped card, the card drawn row by row so the
/// list can be lazy.
class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.credit,
    required this.first,
    required this.last,
  });

  final PhotoCredit credit;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    const corner = Radius.circular(AppRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: first ? corner : Radius.zero,
          bottom: last ? corner : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          GroupRow(
            title: credit.title,
            // Title, author, source and licence: what CC BY and CC BY-SA
            // ask a credit to carry.
            subtitle:
                '${l10n.creditsRow(credit.author, credit.license)}\n${credit.source}',
            titleStyle: type.rowSubtitle.copyWith(color: AppColors.onSurface),
          ),
          if (!last)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.groupPaddingH),
              child: Divider(
                height: AppSizes.hairline,
                thickness: AppSizes.hairline,
                color: AppColors.divider,
              ),
            ),
        ],
      ),
    );
  }
}

/// An everyday page: grey background, back button, large title.
class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.child,
    this.header,
    this.itemCount = 0,
    this.itemBuilder,
  });

  final String title;

  /// Below the rows (or alone when there are none).
  final Widget child;

  /// Above the rows.
  final Widget? header;

  /// Rows built lazily as they scroll into view.
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ContentWidth(
          child: Builder(
            builder: (context) {
              final top = <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pressable(
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: l10n.back,
                    child: const SizedBox.square(
                      dimension: AppSizes.minTouchTarget,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: AppSizes.tabIcon,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sectionHeaderInset,
                  ),
                  child: Text(title, style: type.headline),
                ),
                const SizedBox(height: AppSpacing.zoneGap),
                ?header,
              ];
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  MediaQuery.paddingOf(context).top,
                  AppSpacing.screenMargin,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
                ),
                itemCount: top.length + itemCount + 1,
                itemBuilder: (context, i) {
                  if (i < top.length) return top[i];
                  final row = i - top.length;
                  if (row < itemCount) return itemBuilder!(context, row);
                  return child;
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Pressable(onPressed: onPressed, child: child);
}

/// A row that is one option among several, with a check when chosen.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.selected,
    required this.onPressed,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Semantics(
      selected: selected,
      child: Pressable(
        onPressed: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.groupPaddingH,
              vertical: AppSpacing.rowPaddingV,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: type.rowTitle),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: type.rowSubtitle.copyWith(
                            fontFamily: AppFonts.latin,
                            fontFamilyFallback: AppFonts.latinFallback,
                            height: thaiMinLineHeight,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // The check lands with a small settle when chosen and fades
                // when another row takes it.
                AnimatedScale(
                  scale: selected ? 1 : AppMotion.checkFrom,
                  duration: AppMotion.of(context, AppMotion.standard),
                  curve: selected ? AppMotion.settle : AppMotion.exit,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: AppMotion.of(context, AppMotion.quick),
                    child: const Icon(
                      Icons.check_rounded,
                      size: AppSizes.tabIcon,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
