import 'dart:ui';

import 'package:flutter/material.dart';

export 'app_spacing.dart';

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
            ? const Color(0xFF232323)
            : Colors.white.withValues(alpha: 0.76),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
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

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.blur = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium translucent glass gradient fill simulating light refractions
    final fillGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E24).withValues(alpha: 0.72),
              const Color(0xFF121216).withValues(alpha: 0.48),
            ],
            stops: const [0.0, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Colors.white.withValues(alpha: 0.36),
            ],
            stops: const [0.0, 1.0],
          );

    // Light-reflecting thin highlight edge
    final borderColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.16)
        : const Color.fromRGBO(255, 255, 255, 0.64);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: fillGradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              // Broad soft ambient occlusion shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              // Crisp contact shadow for depth separation
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
