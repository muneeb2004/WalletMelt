import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../utils/haptics.dart';
import 'app_spacing.dart';
import 'wm_card.dart';
import 'wm_palette.dart';
import 'wm_type.dart';

export '../utils/haptics.dart';
export '../widgets/app_bottom_sheet.dart';
export '../widgets/confirm_dialog.dart';
export 'app_motion.dart';
export 'app_spacing.dart';
export 'wm_card.dart';
export 'wm_palette.dart';
export 'wm_type.dart';

/// Legacy colour constants (ADR-0010).
///
/// Neutral and brand values follow the Tonal palette. Status constants keep
/// their *fill* values. New code must use `Theme.of(context).colorScheme` and
/// `context.money` instead of these; they remain only so unmigrated screens
/// keep compiling (see TD-010).
class WalletMeltColors {
  const WalletMeltColors._();

  static const background = Color(0xFFFCF8FF);
  static const backgroundGradientStart = background;
  static const backgroundGradientEnd = background;

  static const textPrimary = Color(0xFF1B1B21);
  static const textSecondary = Color(0xFF4A4A55);
  static const textMuted = Color(0xFF66636F);

  static const brand = Color(0xFF4B45C9);
  static const brandSoft = Color(0xFFE1E0FF);
  static const brandDeep = Color(0xFF16137A);

  static const positive = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF121118);
  static const darkBackgroundContainer = Color(0xFF1D1C26);
  static const darkBackgroundAlt = Color(0xFF0A0A10);
  static const darkTextPrimary = Color(0xFFE7E3EC);
  static const darkTextSecondary = Color(0xFFBDBAC8);

  static const darkBorder = Color(0xFF2E2D3A);
  static const lightBorder = Color(0xFFD8D4E3);

  static const darkHeroStart = darkSurface;
  static const darkHeroEnd = darkBackgroundContainer;
}

// ── Budget threshold color aliases ──────────────────────────────────────────
// Fill colours for budget bars. Prefer `context.money.budget(ratio)`.
const Color kBudgetSafe = WalletMeltColors.positive; // < 70 %
const Color kBudgetWarning = WalletMeltColors.warning; // 70–100 %
const Color kBudgetDanger = WalletMeltColors.warning; // 90–100 %
const Color kBudgetOverrun = WalletMeltColors.danger; // > 100 %

class WalletMeltTheme {
  const WalletMeltTheme._();

  static ThemeData light() => _build(WMPalette.light, WMMoneyColors.light);

  static ThemeData dark() => _build(WMPalette.dark, WMMoneyColors.dark);

  static ThemeData _build(ColorScheme scheme, WMMoneyColors money) {
    final textTheme = WMType.textTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;
    final hairline = BorderSide(color: scheme.outlineVariant, width: 1.0);
    final controlShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius));
    OutlineInputBorder inputBorder(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      fontFamily: WMType.family,
      textTheme: textTheme,
      extensions: [money],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.5),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.outline),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: hairline,
          minimumSize: const Size.fromHeight(52),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => textTheme.labelMedium!.copyWith(
                  color: states.contains(WidgetState.selected)
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w600,
                )),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle:
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
        checkmarkColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        modalBackgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
          side: hairline,
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        dragHandleSize: const Size(32, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: hairline,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: money.track,
        circularTrackColor: money.track,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(
          isDark ? scheme.outlineVariant : scheme.outline,
        ),
      ),
    );
  }
}

Color colorFromHex(String value, {Color fallback = const Color(0xFF66636F)}) {
  final clean = value.replaceAll('#', '').replaceAll(' ', '').trim();
  if (clean.length == 6) {
    final parsed = int.tryParse('FF$clean', radix: 16);
    if (parsed != null) return Color(parsed);
  } else if (clean.length == 8) {
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed != null) return Color(parsed);
  } else if (clean.length == 3) {
    final r = clean[0];
    final g = clean[1];
    final b = clean[2];
    final parsed = int.tryParse('FF$r$r$g$g$b$b', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return fallback;
}

String hexFromColor(Color color, {bool includeHash = true}) {
  final r =
      ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g =
      ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b =
      ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final prefix = includeHash ? '#' : '';
  return '$prefix$r$g$b'.toUpperCase();
}

/// Shared budget progress fill colour based on spend ratio thresholds.
/// Prefer `context.money.budget(ratio)` in new code.
Color budgetProgressColor(double ratio) {
  if (ratio < 0.70) return WalletMeltColors.positive;
  if (ratio < 0.90) return WalletMeltColors.warning;
  if (ratio <= 1.0) return WalletMeltColors.warning;
  return WalletMeltColors.danger;
}

enum WMRenderTier { tier1, tier2, tier3 }

// ── Legacy card wrappers ────────────────────────────────────────────────────
// All delegate to [WMCard]. Do not use in new code (ADR-0010).

/// Legacy alias for [WMCard]. Tiers map to tones; no blur or shadows.
class WMGlassSurface extends StatelessWidget {
  const WMGlassSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusLg,
    this.tier = WMRenderTier.tier2,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final WMRenderTier tier;
  final VoidCallback? onTap;

  factory WMGlassSurface.tier1({
    required Widget child,
    Key? key,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusLg,
    VoidCallback? onTap,
  }) =>
      WMGlassSurface(
        key: key,
        padding: padding,
        radius: radius,
        tier: WMRenderTier.tier1,
        onTap: onTap,
        child: child,
      );

  factory WMGlassSurface.tier2({
    required Widget child,
    Key? key,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusLg,
    VoidCallback? onTap,
  }) =>
      WMGlassSurface(
        key: key,
        padding: padding,
        radius: radius,
        tier: WMRenderTier.tier2,
        onTap: onTap,
        child: child,
      );

  factory WMGlassSurface.tier3({
    required Widget child,
    Key? key,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusLg,
    VoidCallback? onTap,
  }) =>
      WMGlassSurface(
        key: key,
        padding: padding,
        radius: radius,
        tier: WMRenderTier.tier3,
        onTap: onTap,
        child: child,
      );

  @override
  Widget build(BuildContext context) => WMCard(
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );
}

/// Legacy alias for [WMCard].
class FlatCard extends StatelessWidget {
  const FlatCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusLg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => WMCard(
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );
}

/// Legacy alias for [WMCard]. The `blur` argument is ignored.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusLg,
    this.blur = 0.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => WMCard(
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );
}

/// Legacy alias for `WMCard(tone: WMCardTone.brand)`.
class WMDarkHeroCard extends StatelessWidget {
  const WMDarkHeroCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppSpacing.radiusLg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => WMCard(
        tone: WMCardTone.brand,
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );
}

/// Compact quick-action tile. Filled when [isPrimary], tonal otherwise.
class WMQuickActionButton extends StatelessWidget {
  const WMQuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isPrimary ? scheme.primary : scheme.surfaceContainer;
    final fg = isPrimary ? scheme.onPrimary : scheme.onSurface;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              WMHaptics.selection();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: fg),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
