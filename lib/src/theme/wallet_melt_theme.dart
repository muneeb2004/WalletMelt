import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_motion.dart';
import '../utils/haptics.dart';

export 'app_spacing.dart';
export 'app_motion.dart';
export '../widgets/app_bottom_sheet.dart';
export '../widgets/confirm_dialog.dart';
export '../utils/haptics.dart';

class WalletMeltColors {
  const WalletMeltColors._();

  // Primary backgrounds (warm calm off-white in light mode, true-black OLED in dark mode)
  static const background = Color(0xFFF7F8FA);
  static const backgroundGradientStart = Color(0xFFFAFBFD);
  static const backgroundGradientEnd = Color(0xFFF0F2F6);

  // Text hierarchy
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Brand Accent (Refined Electric Indigo)
  static const brand = Color(0xFF6366F1);
  static const brandSoft = Color(0xFFEEF2FF);
  static const brandDeep = Color(0xFF4338CA);

  // Semantic Status Colors (WCAG AA compliant)
  static const positive = Color(0xFF10B981); // Emerald Green
  static const warning = Color(0xFFF59E0B);  // Warm Amber / Gold
  static const danger = Color(0xFFEF4444);   // Modern Crimson Red

  // Dark Mode Surfaces (True-black OLED foundation)
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0C0E14);
  static const darkBackgroundContainer = Color(0xFF141722);
  static const darkBackgroundAlt = Color(0xFF08090D);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);

  // 1px Hairline Borders & Dividers
  static const darkBorder = Color(0x1FFFFFFF);
  static const lightBorder = Color(0x0F000000);

  // Premium Hero Card Gradients (for FinSight-style Dark Financial Cards)
  static const darkHeroStart = Color(0xFF0C0E14);
  static const darkHeroEnd = Color(0xFF181C28);
}

// ── Budget threshold color aliases ──────────────────────────────────────────
// These are the ONLY raw Color literals permitted in budget-progress logic.
// All other budget-color code must reference these constants.
const Color kBudgetSafe = WalletMeltColors.positive; // < 70 %
const Color kBudgetWarning = WalletMeltColors.warning; // 70–90 %
const Color kBudgetDanger = WalletMeltColors.warning; // 90–100 %
const Color kBudgetOverrun = WalletMeltColors.danger; // > 100 %

class WalletMeltTheme {
  const WalletMeltTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: WalletMeltColors.brand,
      brightness: Brightness.light,
      primary: WalletMeltColors.textPrimary,
      surface: WalletMeltColors.background,
      error: WalletMeltColors.danger,
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
      surface: WalletMeltColors.darkSurface,
      error: WalletMeltColors.danger,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: WalletMeltColors.darkBackground,
      textTheme: _textTheme(Brightness.dark),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF10131B)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.2,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
        modalBackgroundColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
          side: BorderSide(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: isDark
            ? Colors.white.withValues(alpha: 0.20)
            : Colors.black.withValues(alpha: 0.20),
        dragHandleSize: const Size(32, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
            width: 1.0,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
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
    const tabular = [FontFeature.tabularFigures()];

    return TextTheme(
      displaySmall: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 38,
          fontWeight: FontWeight.w900,
          fontVariations: const [FontVariation('wght', 900)],
          color: primary,
          letterSpacing: -0.6,
          height: 1.05,
          fontFeatures: tabular),
      headlineMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: primary,
          letterSpacing: -0.4,
          height: 1.1,
          fontFeatures: tabular),
      titleLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: primary,
          letterSpacing: -0.3,
          fontFeatures: tabular),
      titleMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: primary,
          fontFeatures: tabular),
      bodyLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          fontVariations: const [FontVariation('wght', 500)],
          color: primary,
          fontFeatures: tabular),
      bodyMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13.0,
          fontWeight: FontWeight.w500,
          fontVariations: const [FontVariation('wght', 500)],
          color: secondary,
          height: 1.35,
          fontFeatures: tabular),
      labelLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: primary,
          letterSpacing: 0.2,
          fontFeatures: tabular),
      labelMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: secondary,
          letterSpacing: 0.4,
          fontFeatures: tabular),
      bodySmall: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          fontVariations: const [FontVariation('wght', 400)],
          color: secondary,
          height: 1.4,
          fontFeatures: tabular),
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
  if (ratio < 0.90) return WalletMeltColors.warning;
  if (ratio <= 1.0) return WalletMeltColors.warning;
  return WalletMeltColors.danger;
}

enum WMRenderTier { tier1, tier2, tier3 }

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
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusLg,
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusLg,
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
    
    // Auto-downgrade to Tier 1 when inside a Scrollable container to maintain smooth scrolling (Directive 2)
    final isScrollable = Scrollable.maybeOf(context) != null;
    final activeTier = isScrollable ? WMRenderTier.tier1 : tier;

    if (activeTier == WMRenderTier.tier1) {
      // Tier 1: Flat translucent fill, no shadows, no blur, 1px hairline border. 120fps GPU friendly.
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFF4F5F8),
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
      // Tier 2: Solid carbon surface, subtle soft shadow, 1px hairline border.
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
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 12,
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

    // Tier 3: Translucent surface, optional BackdropFilter blur, dual shadows. Used only on static non-scrollable surfaces.
    final fillGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WalletMeltColors.darkSurface.withValues(alpha: 0.85),
              const Color(0xFF06070A).withValues(alpha: 0.65),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.50),
            ],
          );

    final innerContainer = Container(
      decoration: BoxDecoration(
        gradient: fillGradient,
        borderRadius: BorderRadius.circular(radius - 1.0),
        border: Border.all(
          color: isDark ? const Color(0x28FFFFFF) : const Color(0x18000000),
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

    // Apply BackdropFilter blur (sigma = 16) only on static surfaces
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
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusLg,
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
    this.radius = AppSpacing.radiusPill,
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
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
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

/// Premium Dark Hero Financial Card (FinSight inspired)
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WalletMeltColors.darkSurface,
            WalletMeltColors.darkBackgroundContainer,
          ],
        ),
        border: Border.all(
          color: const Color(0x28FFFFFF),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: WalletMeltColors.brand.withValues(alpha: 0.05),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap != null
              ? () {
                  WMHaptics.light();
                  onTap!();
                }
              : null,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return cardContent;
  }
}

/// Compact circular / pill action button with micro scale on press
class WMQuickActionButton extends StatefulWidget {
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
  State<WMQuickActionButton> createState() => _WMQuickActionButtonState();
}

class _WMQuickActionButtonState extends State<WMQuickActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = AppMotion.buttonPressScale),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          WMHaptics.selection();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: AppMotion.fast,
          curve: AppMotion.entrance,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? (isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary)
                  : (isDark ? WalletMeltColors.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.transparent
                    : (isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? (isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15))
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F172A).withValues(alpha: 0.06)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isPrimary
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : WalletMeltColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isPrimary
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary),
                      ),
                      maxLines: 1,
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
