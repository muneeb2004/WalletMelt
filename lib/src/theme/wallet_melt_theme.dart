import 'dart:ui';

import 'package:flutter/material.dart';

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
        fillColor: scheme.brightness == Brightness.dark ? const Color(0xFF232323) : Colors.white.withValues(alpha: 0.76),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WalletMeltColors.brand,
          foregroundColor: WalletMeltColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary;
    final secondary = brightness == Brightness.dark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary;
    return TextTheme(
      displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: primary, height: 1.02),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: primary, height: 1.08),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: primary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: secondary, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secondary),
    );
  }
}

Color colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
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
    final fill = isDark ? const Color.fromRGBO(28, 28, 28, 0.72) : const Color.fromRGBO(255, 255, 255, 0.68);
    final border = isDark ? const Color.fromRGBO(255, 255, 255, 0.12) : const Color.fromRGBO(255, 255, 255, 0.55);
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: content);
  }
}
