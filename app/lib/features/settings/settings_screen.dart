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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only under the sign-in gate (absent in previews and tests).
              if (context.getInheritedWidgetOfExactType<AuthScope>() != null)
                const AccountSection(),
              SectionHeader(l10n.settingsCurrency, first: true),
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

/// An everyday page: grey background, back button, large title.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              MediaQuery.paddingOf(context).top,
              AppSpacing.screenMargin,
              MediaQuery.paddingOf(context).bottom + AppSpacing.zoneGap,
            ),
            children: [
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
              child,
            ],
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
