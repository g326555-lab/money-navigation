import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/account_models.dart';
import '../../services/auth/auth_failure.dart';
import '../../shared/app_button.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';

/// First run after signing in: who is travelling, which money they think
/// in and are billed in, and the app's language. Each answer starts from a
/// sensible default, so one tap on the button is enough.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late ProfileDraft _draft = _defaults(TravelerType.visitorInThailand);
  bool _busy = false;
  String? _error;

  static ProfileDraft _defaults(TravelerType type) =>
      defaultsFor(type, deviceCurrency: SettingsStore.deviceCurrency());

  @override
  void initState() {
    super.initState();
    context.getInheritedWidgetOfExactType<AppScope>()?.rates.loadCurrencies();
  }

  Future<void> _save() async {
    final auth = AuthScope.read(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.completeSetup(_draft);
      HapticFeedback.mediumImpact();
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(
        () => _error = failureMessage(l10n, e.failure, signingIn: false),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useOtherAccount() async {
    final auth = AuthScope.read(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signOut();
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(
        () => _error = failureMessage(l10n, e.failure, signingIn: false),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCurrency({required bool home}) async {
    final l10n = AppLocalizations.of(context);
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SetupCurrencyPicker(
          title: home ? l10n.authHomeCurrency : l10n.authCardCurrency,
          selected: home ? _draft.homeCurrency : _draft.cardCurrency,
        ),
      ),
    );
    if (code == null || !mounted) return;
    setState(() {
      _draft = home
          ? _draft.copyWith(homeCurrency: code)
          : _draft.copyWith(cardCurrency: code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final names = AppScope.of(context).rates.currencies;
    final thaiTitle = AppTypography.thai.rowTitle;
    String currencyName(String code) => names[code] ?? code;

    return AuthPage(
      title: l10n.authSetupTitle,
      subtitle: l10n.authSetupIntro,
      showBack: false,
      dock: AppButton(
        label: l10n.authSetupStart,
        busy: _busy,
        onPressed: _draft.isValid ? _save : null,
      ),
      children: [
        SectionHeader(l10n.authSetupTypeHeader, first: true),
        GroupCard(
          dividerInset: AppSpacing.rowIconTextInset,
          children: [
            for (final t in TravelerType.values)
              AuthChoiceRow(
                title: switch (t) {
                  TravelerType.visitorInThailand => l10n.authTypeVisitor,
                  TravelerType.thaiAbroad => l10n.authTypeThai,
                },
                subtitle: switch (t) {
                  TravelerType.visitorInThailand => l10n.authTypeVisitorSub,
                  TravelerType.thaiAbroad => l10n.authTypeThaiSub,
                },
                leading: switch (t) {
                  TravelerType.visitorInThailand => const IconTile.blue(
                    icon: Icons.flight_land_rounded,
                  ),
                  TravelerType.thaiAbroad => const IconTile.orange(
                    icon: Icons.flight_takeoff_rounded,
                  ),
                },
                selected: _draft.travelerType == t,
                onPressed: () {
                  if (_draft.travelerType != t) {
                    setState(() => _draft = _defaults(t));
                  }
                },
              ),
          ],
        ),
        SectionHeader(l10n.authSetupMoneyHeader),
        GroupCard(
          children: [
            _CurrencyRow(
              title: l10n.authHomeCurrency,
              name: currencyName(_draft.homeCurrency),
              code: _draft.homeCurrency,
              onPressed: _busy ? null : () => _pickCurrency(home: true),
            ),
            _CurrencyRow(
              title: l10n.authCardCurrency,
              name: currencyName(_draft.cardCurrency),
              code: _draft.cardCurrency,
              onPressed: _busy ? null : () => _pickCurrency(home: false),
            ),
          ],
        ),
        SectionHeader(l10n.authSetupLanguageHeader),
        GroupCard(
          children: [
            for (final lang in AppLanguage.values)
              AuthChoiceRow(
                title: switch (lang) {
                  AppLanguage.en => l10n.authLanguageEn,
                  AppLanguage.th => l10n.authLanguageTh,
                },
                // Each language is written in its own script.
                titleStyle: lang == AppLanguage.th ? thaiTitle : type.rowTitle,
                selected: _draft.language == lang,
                onPressed: () =>
                    setState(() => _draft = _draft.copyWith(language: lang)),
              ),
          ],
        ),
        if (_error != null)
          AuthMessage(_error!)
        else
          GroupFooter(l10n.authSetupFooter),
        const SizedBox(height: AppSpacing.groupGap),
        AuthTextLink(
          label: l10n.authSetupOtherAccount,
          onPressed: _busy ? null : _useOtherAccount,
        ),
      ],
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.title,
    required this.name,
    required this.code,
    required this.onPressed,
  });

  final String title;
  final String name;
  final String code;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: '$title, $name',
      child: ExcludeSemantics(
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
                      if (name != code) Text(name, style: type.rowSubtitle),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // The code in a pill with a chevron: this row opens a list.
                DecoratedBox(
                  decoration: const ShapeDecoration(
                    shape: StadiumBorder(),
                    color: AppColors.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.chipPadding,
                      AppSpacing.sm,
                      AppSpacing.chipPadding,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(code, style: type.rowTitle),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: AppSizes.buttonIcon,
                          color: AppColors.onSurfaceTertiary,
                        ),
                      ],
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

/// Every currency the daily rate source covers; returns the chosen code.
class SetupCurrencyPicker extends StatelessWidget {
  const SetupCurrencyPicker({
    super.key,
    required this.title,
    required this.selected,
  });

  final String title;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rates = AppScope.of(context).rates;
    return ListenableBuilder(
      listenable: rates,
      builder: (context, _) {
        final currencies = rates.currencies.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        return AuthPage(
          title: title,
          children: currencies.isEmpty
              ? [AuthMessage(l10n.currencyOffline, isError: false)]
              : [
                  GroupCard(
                    children: [
                      for (final c in currencies)
                        AuthChoiceRow(
                          title: c.value,
                          subtitle: c.key,
                          selected: c.key == selected,
                          onPressed: () => Navigator.of(context).pop(c.key),
                        ),
                    ],
                  ),
                  GroupFooter(l10n.currencySource),
                ],
        );
      },
    );
  }
}
