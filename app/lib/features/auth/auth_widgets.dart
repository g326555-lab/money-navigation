import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_failure.dart';
import '../../shared/action_dock.dart';
import '../../shared/content_width.dart';
import '../../shared/pressable.dart';

/// The sentence that explains [failure]. Null for a cancelled Apple or
/// Google sheet: closing it is a choice, not an error. [signingIn] picks the
/// fallback for an unknown error: "Couldn't sign in" only fits sign-in.
String? failureMessage(
  AppLocalizations l10n,
  AuthFailure failure, {
  bool signingIn = true,
}) => switch (failure) {
  AuthFailure.cancelled => null,
  AuthFailure.invalidCredentials => l10n.authErrInvalidCredentials,
  AuthFailure.emailTaken => l10n.authErrEmailTaken,
  AuthFailure.emailNotConfirmed => l10n.authErrEmailNotConfirmed,
  AuthFailure.weakPassword => l10n.authErrWeakPassword,
  AuthFailure.codeInvalid => l10n.authErrCodeInvalid,
  AuthFailure.emailRejected => l10n.authErrEmailRejected,
  AuthFailure.emailUndeliverable => l10n.authErrEmailUndeliverable,
  AuthFailure.rateLimited => l10n.authErrRateLimited,
  AuthFailure.offline => l10n.authErrOffline,
  AuthFailure.notConfigured => l10n.authErrNotConfigured,
  AuthFailure.unknown => signingIn ? l10n.authErrUnknown : l10n.authErrTryAgain,
};

/// An everyday page for the account flow: grey page, optional back button,
/// large title, content, and a pinned action dock.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.dock,
    this.showBack = true,
  });

  final String title;

  /// One line under the title that says why this page asks what it asks.
  final String? subtitle;
  final List<Widget> children;
  final Widget? dock;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final padding = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            ContentWidth(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  padding.top + (showBack ? 0 : AppSizes.minTouchTarget),
                  AppSpacing.screenMargin,
                  (dock == null
                          ? padding.bottom
                          : ActionDock.heightOf(context)) +
                      AppSpacing.zoneGap,
                ),
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Pressable(
                        onPressed: () => Navigator.of(context).maybePop(),
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
                    child: Semantics(
                      header: true,
                      child: Text(title, style: type.headline),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sectionHeaderInset,
                      ),
                      child: Text(subtitle!, style: type.heroLabel),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.zoneGap),
                  ...children,
                ],
              ),
            ),
            if (dock != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ActionDock(child: dock!),
              ),
          ],
        ),
      ),
    );
  }
}

/// One labelled text input as a row inside a [GroupCard]: a small label
/// above, the text in row-title size, no box of its own.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.onToggleObscure,
    this.onSubmitted,
    this.onChanged,
    this.hint,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.trailing,
    this.scrollBottom,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;

  /// Shows the show/hide control for a password when set.
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;

  /// A mark at the end of the row, e.g. a check once the email reads right.
  final Widget? trailing;

  /// Room to keep clear below the field when the keyboard opens: what sits
  /// under it on the page. Defaults to the height of an action dock.
  final double? scrollBottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.groupPaddingH,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // One node for screen readers: the label names the field.
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: type.rowSubtitle),
                  TextField(
                    // Keep the field and what follows it clear of the keyboard.
                    scrollPadding: EdgeInsets.only(
                      bottom:
                          (scrollBottom ?? ActionDock.heightOf(context)) +
                          AppSpacing.xl,
                    ),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    autofocus: autofocus,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: !obscure,
                    maxLength: maxLength,
                    onSubmitted: onSubmitted,
                    onChanged: onChanged,
                    cursorColor: AppColors.primaryText,
                    style: type.rowTitle,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      hintText: hint,
                      hintStyle: type.rowTitle.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null)
            SizedBox.square(
              dimension: AppSizes.minTouchTarget,
              child: Center(child: trailing),
            ),
          if (onToggleObscure != null)
            Pressable(
              onPressed: onToggleObscure,
              semanticLabel: obscure
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              child: SizedBox.square(
                dimension: AppSizes.minTouchTarget,
                child: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: AppSizes.tabIcon,
                  color: AppColors.onSurfaceTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A short message under a group: the reason a step failed (red, with a
/// leading mark so colour is not the only signal) or a neutral note.
class AuthMessage extends StatelessWidget {
  const AuthMessage(this.text, {super.key, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final color = isError ? AppColors.errorText : AppColors.onSurfaceSecondary;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sectionHeaderInset,
          AppSpacing.md,
          AppSpacing.sectionHeaderInset,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError) ...[
              // As tall as one caption line, so the mark sits on the first
              // line however the text wraps.
              Icon(
                Icons.error_outline_rounded,
                size: type.caption.fontSize! * type.caption.height!,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(text, style: type.caption.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain text action in the content zone (switch between sign in and
/// create account, forgot password). 48 high so it is easy to hit.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The main way onward among the links (e.g. "Create account").
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: label,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sectionHeaderInset,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  label,
                  style: type.label.copyWith(
                    color: emphasis
                        ? AppColors.onSurface
                        : AppColors.onSurfaceSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row that is one option among several, with a check when chosen.
class AuthChoiceRow extends StatelessWidget {
  const AuthChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.subtitle,
    this.titleStyle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onPressed;
  final TextStyle? titleStyle;

  /// A 40 icon tile before the text; the group's hairline then starts at 72.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onPressed,
        haptic: HapticFeedback.selectionClick,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.groupPaddingH,
              vertical: AppSpacing.rowPaddingV,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle ?? type.rowTitle),
                      if (subtitle != null)
                        Text(subtitle!, style: type.rowSubtitle),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SelectionMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sizes of the account screens' own marks, derived from the row tokens.
/// Candidates for lib/core/spacing.dart when another screen needs them.
abstract final class AuthSizes {
  /// Ring of an unchosen [SelectionMark] (24 across).
  static const double selectionRing = 1.5;

  /// Check inside a chosen [SelectionMark].
  static const double selectionGlyph = 16;

  /// The coin on the welcome card: two icon tiles high.
  static const double welcomeCoin = AppSizes.iconTile * 2;

  /// The small green dot before "Example".
  static const double tagDot = 8;
}

/// The round mark at the end of a choice row: a green disc with a white
/// check when chosen, an empty grey ring otherwise, so the choice reads
/// without relying on colour alone.
class SelectionMark extends StatelessWidget {
  const SelectionMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.tabIcon,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: ShapeDecoration(
              shape: CircleBorder(
                side: BorderSide(
                  color: AppColors.onSurfaceTertiary,
                  width: AuthSizes.selectionRing,
                ),
              ),
            ),
            child: SizedBox.expand(),
          ),
          AnimatedScale(
            scale: selected ? 1 : AppMotion.checkFrom,
            duration: AppMotion.of(context, AppMotion.standard),
            curve: selected ? AppMotion.settle : AppMotion.exit,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.quick),
              child: const DecoratedBox(
                decoration: ShapeDecoration(
                  shape: CircleBorder(),
                  color: AppColors.primary,
                ),
                child: SizedBox.expand(
                  child: Icon(
                    Icons.check_rounded,
                    size: AuthSizes.selectionGlyph,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
