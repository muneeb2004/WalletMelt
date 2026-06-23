import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/haptics.dart';

export 'app_spacing.dart';
export 'app_motion.dart';
export '../widgets/app_bottom_sheet.dart';
export '../widgets/confirm_dialog.dart';
export '../utils/haptics.dart';

class WalletMeltColors {
  const WalletMeltColors._();

  static const background = Color(0xFFFAF7EF);
  static const backgroundGradientStart = Color(0xFFFFF7E5);
  static const backgroundGradientEnd = Color(0xFFEAF4EF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF7A756B);
  static const textMuted = Color(0xFFA39D92);
  static const brand = Color(0xFFF4B740);
  static const brandSoft = Color(0xFFFFD98A);
  static const brandDeep = Color(0xFFB87912);
  static const positive = Color(0xFF8FD6B5);
  static const warning = Color(0xFFE8805D);
  static const danger = Color(0xFFD96B5F);
  static const darkBackground = Color(0xFF090909);
  static const darkTextPrimary = Color(0xFFFAF7EF);
  static const darkTextSecondary = Color(0xFFBEB7AA);

  // Semantic surfaces, containers, and borders
  static const darkSurface = Color(0xFF1E1E24);
  static const darkBackgroundContainer = Color(0xFF121218);
  static const darkBackgroundAlt = Color(0xFF0F0F0F);
  static const darkBorder = Color(0x1FFFFFFF);
  static const lightBorder = Color(0x1F000000);
}

// ── Budget threshold color aliases ──────────────────────────────────────────
// These are the ONLY raw Color literals permitted in budget-progress logic.
// All other budget-color code must reference these constants.
const Color kBudgetSafe = WalletMeltColors.positive; // < 70 %
const Color kBudgetWarning = WalletMeltColors.brand; // 70–90 %
const Color kBudgetDanger = WalletMeltColors.warning; // 90–100 %
const Color kBudgetOverrun = WalletMeltColors.danger; // > 100 %

class WalletMeltTheme {
  const WalletMeltTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: WalletMeltColors.brand,
      brightness: Brightness.light,
      primary: WalletMeltColors.brandDeep,
      surface: WalletMeltColors.background,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: WalletMeltColors.background,
      textTheme: _textTheme(Brightness.light),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: WalletMeltColors.brand,
      brightness: Brightness.dark,
      primary: WalletMeltColors.brand,
      surface: WalletMeltColors.darkBackground,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: WalletMeltColors.darkBackground,
      textTheme: _textTheme(Brightness.dark),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'System',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? const Color(0xFF16161C).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? const Color.fromRGBO(255, 255, 255, 0.08)
                : const Color.fromRGBO(0, 0, 0, 0.06),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? const Color.fromRGBO(255, 255, 255, 0.08)
                : const Color.fromRGBO(0, 0, 0, 0.06),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WalletMeltColors.brand,
          foregroundColor: WalletMeltColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.28), width: 1.4),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.brightness == Brightness.dark ? Colors.black : Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark
        ? WalletMeltColors.darkTextPrimary
        : WalletMeltColors.textPrimary;
    final secondary = brightness == Brightness.dark
        ? WalletMeltColors.darkTextSecondary
        : WalletMeltColors.textSecondary;
    return TextTheme(
      displaySmall: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: primary,
          height: 1.02),
      headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: primary,
          height: 1.08),
      titleLarge:
          TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: primary),
      titleMedium:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary),
      bodyLarge:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: secondary,
          height: 1.35),
      labelLarge:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primary),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: secondary),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondary,
          height: 1.4),
    );
  }
}

Color colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

/// Shared budget progress color based on spend ratio thresholds.
/// Used by DashboardScreen and BudgetScreen to stay consistent.
Color budgetProgressColor(double ratio) {
  if (ratio < 0.70) return WalletMeltColors.positive;
  if (ratio < 0.90) return WalletMeltColors.brand;
  if (ratio <= 1.0) return WalletMeltColors.warning;
  return WalletMeltColors.danger;
}

enum WMRenderTier { tier1, tier2, tier3 }

class WMGlassSurface extends StatelessWidget {
  const WMGlassSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
    VoidCallback? onTap,
  }) => WMGlassSurface(
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
    VoidCallback? onTap,
  }) => WMGlassSurface(
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
    VoidCallback? onTap,
  }) => WMGlassSurface(
    key: key,
    padding: padding,
    radius: radius,
    tier: WMRenderTier.tier3,
    onTap: onTap,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Auto-downgrade to Tier 1 when inside a Scrollable container to maintain smooth scrolling
    final isScrollable = Scrollable.maybeOf(context) != null;
    final activeTier = isScrollable ? WMRenderTier.tier1 : tier;

    if (activeTier == WMRenderTier.tier1) {
      // Tier 1: Flat, no shadows, no blur, solid border. GPU-friendly.
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161C) : const Color(0xFFF4F4F0),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.0,
          ),
        ),
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius - 1.0),
                  onTap: () {
                    WMHaptics.light();
                    onTap!();
                  },
                  child: Padding(padding: padding, child: child),
                ),
              ),
      );
    }

    if (activeTier == WMRenderTier.tier2) {
      // Tier 2: Solid background, single subtle shadow, solid border. GPU-efficient.
      return Container(
        decoration: BoxDecoration(
          color: isDark ? WalletMeltColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? const Color(0x28FFFFFF) : const Color(0x28000000),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius - 1.0),
                  onTap: () {
                    WMHaptics.light();
                    onTap!();
                  },
                  child: Padding(padding: padding, child: child),
                ),
              ),
      );
    }

    // Tier 3: Translucent surface, optional BackdropFilter blur, dual shadows. Used sparingly.
    final fillGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WalletMeltColors.darkSurface.withValues(alpha: 0.72),
              const Color(0xFF121216).withValues(alpha: 0.48),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Colors.white.withValues(alpha: 0.36),
            ],
          );

    final innerContainer = Container(
      decoration: BoxDecoration(
        gradient: fillGradient,
        borderRadius: BorderRadius.circular(radius - 1.0),
        border: Border.all(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
          width: 1.0,
        ),
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius - 1.0),
                onTap: () {
                  WMHaptics.light();
                  onTap!();
                },
                child: Padding(padding: padding, child: child),
              ),
            ),
    );

    // Apply BackdropFilter with moderate blur (sigma = 16)
    final Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16.0,
          sigmaY: 16.0,
          tileMode: TileMode.decal,
        ),
        child: innerContainer,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: glassContent,
    );
  }
}

class FlatCard extends StatelessWidget {
  const FlatCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WMGlassSurface.tier1(
      padding: padding,
      radius: radius,
      onTap: onTap,
      child: child,
    );
  }
}

class FlatNavBar extends StatelessWidget {
  const FlatNavBar({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.radius = 999,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WalletMeltColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.blur = 0.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WMGlassSurface(
      padding: padding,
      radius: radius,
      tier: blur > 0.0 ? WMRenderTier.tier3 : WMRenderTier.tier2,
      onTap: onTap,
      child: child,
    );
  }
}
