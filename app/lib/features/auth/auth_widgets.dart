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

Future<void> _noHaptic() async {}

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
                        // Going back is not an outcome; no haptic.
                        haptic: _noHaptic,
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
                      child: BalancedText(title, style: type.headline),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sectionHeaderInset,
                      ),
                      child: BalancedText(subtitle!, style: type.heroLabel),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.zoneGap),
                  ...children,
                ],
              ),
            ),
            // Content scrolls away under the status bar instead of
            // running through the clock and icons.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: padding.top,
              child: const ColoredBox(color: AppColors.background),
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

/// The place under a group where a step's error appears. It opens and
/// closes smoothly, so what sits below moves instead of jumping, and a new
/// message cross-fades over the old one.
class AuthMessageSlot extends StatelessWidget {
  const AuthMessageSlot(this.text, {super.key});

  /// The error to show, or null for none.
  final String? text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.move,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.quick),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : AuthMessage(text!, key: ValueKey(text)),
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
      widthFactor: 1,
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
                  // Muted while the page is working, so it does not look
                  // tappable when it is not.
                  style: type.label.copyWith(
                    color: onPressed == null
                        ? AppColors.onSurfaceMuted
                        : emphasis
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
    this.ring = true,
  });

  final String title;
  final String? subtitle;
  final bool selected;

  /// Null while the page is saving.
  final VoidCallback? onPressed;

  /// Show the empty disc on unchosen rows. A short set of choices (two or
  /// three) shows it, so the rows read as options; a long list hides it and
  /// marks only the chosen row, so thirty empty marks do not crowd it.
  final bool ring;
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
                SelectionMark(selected: selected, ring: ring),
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
  /// Check inside a chosen [SelectionMark], as points of its 24 box: the
  /// short arm starts left of centre, the long arm ends high on the right,
  /// so the check sits optically centred in the disc.
  static const selectionCheck = [
    Offset(7, 12.5),
    Offset(10.5, 16),
    Offset(17, 9),
  ];

  /// The coin on the welcome card, about 1.4 lines of the 46 number high:
  /// here the number is the hero and the coin only says "money", so it is
  /// smaller than the success-screen coin (132, compact 88).
  static const double welcomeCoin = 72;

  /// The small green dot before "Example".
  static const double tagDot = 8;
}

/// The round mark at the end of a choice row: a green disc with a dark
/// check when chosen, a plain grey disc otherwise, so the choice reads by
/// the check and not by colour alone.
class SelectionMark extends StatelessWidget {
  const SelectionMark({super.key, required this.selected, this.ring = true});

  final bool selected;

  /// Draw the empty disc when not chosen (see [AuthChoiceRow.ring]).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.tabIcon,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (ring)
            const DecoratedBox(
              decoration: ShapeDecoration(
                shape: CircleBorder(),
                color: AppColors.surfaceDim,
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
                  child: CustomPaint(painter: _CheckPainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark at the end of the email row once the address reads right. It
/// always holds its place, so the field never changes width as it appears,
/// and it lands with the same small settle as a selection check.
class EmailCheck extends StatelessWidget {
  const EmailCheck({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedScale(
        scale: visible ? 1 : AppMotion.checkFrom,
        duration: AppMotion.of(context, AppMotion.standard),
        curve: visible ? AppMotion.settle : AppMotion.exit,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AppMotion.of(context, AppMotion.quick),
          child: const Icon(
            Icons.check_circle_rounded,
            size: AppSizes.tabIcon,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

/// The check in a [SelectionMark], stroked with round ends so it reads as
/// firmly as the disc around it (the icon-font check is a hairline at 16).
class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / AppSizes.tabIcon;
    final points = [for (final p in AuthSizes.selectionCheck) p * scale];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.progressStroke * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.onPrimary,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => false;
}

/// Text whose lines are evened out, like CSS `text-wrap: balance`: it takes
/// the narrowest width that still needs the same number of lines, so a
/// heading never ends on one orphaned word at the Fold cover width.
///
/// Give [maxWidth] where the parent asks for intrinsic sizes (a
/// LayoutBuilder cannot answer them); otherwise the width is measured.
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.text, {
    super.key,
    required this.style,
    this.maxWidth,
  });

  final String text;
  final TextStyle style;
  final double? maxWidth;

  /// Halvings of the width range; 10 lands within a fraction of a point.
  static const _steps = 10;

  @override
  Widget build(BuildContext context) {
    if (maxWidth != null) return _balanced(context, maxWidth!);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _balanced(context, constraints.maxWidth),
    );
  }

  Widget _balanced(BuildContext context, double width) {
    final painter = TextPainter(
      // Measure with what Text will render: the inherited style merged in.
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    );
    int linesAt(double w) {
      painter.layout(maxWidth: w);
      return painter.computeLineMetrics().length;
    }

    final lines = width.isFinite ? linesAt(width) : 1;
    var fits = width;
    if (lines > 1) {
      var tooNarrow = 0.0;
      for (var i = 0; i < _steps; i++) {
        final mid = (tooNarrow + fits) / 2;
        if (linesAt(mid) <= lines) {
          fits = mid;
        } else {
          tooNarrow = mid;
        }
      }
    }
    painter.dispose();
    final child = Text(text, style: style);
    if (lines <= 1) return child;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: SizedBox(width: fits.ceilToDouble(), child: child),
    );
  }
}
