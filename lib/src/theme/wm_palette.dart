/// WalletMelt colour roles (ADR-0010, "Tonal").
///
/// This file is the ONLY place raw hex values for the brand palette live.
/// Everywhere else consume `Theme.of(context).colorScheme` and
/// `context.money`.
library;

import 'package:flutter/material.dart';

/// Brand + neutral roles for light and dark. Dark uses true black as canvas.
abstract final class WMPalette {
  WMPalette._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4B45C9),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE1E0FF),
    onPrimaryContainer: Color(0xFF16137A),
    secondary: Color(0xFF5C5B7A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E0FF),
    onSecondaryContainer: Color(0xFF191834),
    tertiary: Color(0xFF7A4A6B),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFCF8FF),
    onSurface: Color(0xFF1B1B21),
    onSurfaceVariant: Color(0xFF4A4A55),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F2FC),
    surfaceContainer: Color(0xFFF3EFFA),
    surfaceContainerHigh: Color(0xFFE8E3F3),
    surfaceContainerHighest: Color(0xFFE0DBEB),
    outline: Color(0xFF7A7985),
    outlineVariant: Color(0xFFD8D4E3),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF303036),
    onInverseSurface: Color(0xFFF3EFF7),
    inversePrimary: Color(0xFFBFC2FF),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFBFC2FF),
    onPrimary: Color(0xFF1A1C70),
    primaryContainer: Color(0xFF24235E),
    onPrimaryContainer: Color(0xFFE1E0FF),
    secondary: Color(0xFFC4C3E5),
    onSecondary: Color(0xFF2D2D4A),
    secondaryContainer: Color(0xFF1D1C26),
    onSecondaryContainer: Color(0xFFE2E0FF),
    tertiary: Color(0xFFEBB8DA),
    onTertiary: Color(0xFF4A2040),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFE7E3EC),
    onSurfaceVariant: Color(0xFFBDBAC8),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0A0A10),
    surfaceContainer: Color(0xFF121118),
    surfaceContainerHigh: Color(0xFF1D1C26),
    surfaceContainerHighest: Color(0xFF282732),
    outline: Color(0xFF8E8C9A),
    outlineVariant: Color(0xFF2E2D3A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE7E3EC),
    onInverseSurface: Color(0xFF303036),
    inversePrimary: Color(0xFF4B45C9),
  );
}

/// Money semantics. Each status has a *fill* (bars, icons, chips) and a
/// *text* variant that meets 4.5:1 on the surfaces it is used on.
@immutable
class WMMoneyColors extends ThemeExtension<WMMoneyColors> {
  const WMMoneyColors({
    required this.income,
    required this.incomeText,
    required this.incomeContainer,
    required this.caution,
    required this.cautionText,
    required this.cautionContainer,
    required this.over,
    required this.overText,
    required this.overContainer,
    required this.track,
  });

  /// Fill colours are mode-stable and match the legacy status constants.
  final Color income;
  final Color incomeText;
  final Color incomeContainer;
  final Color caution;
  final Color cautionText;
  final Color cautionContainer;
  final Color over;
  final Color overText;
  final Color overContainer;

  /// Unfilled part of progress bars.
  final Color track;

  static const light = WMMoneyColors(
    income: Color(0xFF10B981),
    incomeText: Color(0xFF09694A),
    incomeContainer: Color(0xFFD3F2E3),
    caution: Color(0xFFF59E0B),
    cautionText: Color(0xFF7A4F00),
    cautionContainer: Color(0xFFFFEFD0),
    over: Color(0xFFEF4444),
    overText: Color(0xFFBA1A1A),
    overContainer: Color(0xFFFFDAD6),
    track: Color(0xFFE8E3F3),
  );

  static const dark = WMMoneyColors(
    income: Color(0xFF10B981),
    incomeText: Color(0xFF5FD8A4),
    incomeContainer: Color(0xFF0F3A2B),
    caution: Color(0xFFF59E0B),
    cautionText: Color(0xFFF5B335),
    cautionContainer: Color(0xFF3B2A05),
    over: Color(0xFFEF4444),
    overText: Color(0xFFFFB4AB),
    overContainer: Color(0xFF4A1512),
    track: Color(0xFF282732),
  );

  /// Fill colour for a spend/budget ratio. Thresholds: <70% income,
  /// 70–100% caution, >100% over.
  Color budget(double ratio) {
    if (ratio < 0.70) return income;
    if (ratio <= 1.0) return caution;
    return over;
  }

  /// Text colour matching [budget].
  Color budgetText(double ratio) {
    if (ratio < 0.70) return incomeText;
    if (ratio <= 1.0) return cautionText;
    return overText;
  }

  @override
  WMMoneyColors copyWith({
    Color? income,
    Color? incomeText,
    Color? incomeContainer,
    Color? caution,
    Color? cautionText,
    Color? cautionContainer,
    Color? over,
    Color? overText,
    Color? overContainer,
    Color? track,
  }) =>
      WMMoneyColors(
        income: income ?? this.income,
        incomeText: incomeText ?? this.incomeText,
        incomeContainer: incomeContainer ?? this.incomeContainer,
        caution: caution ?? this.caution,
        cautionText: cautionText ?? this.cautionText,
        cautionContainer: cautionContainer ?? this.cautionContainer,
        over: over ?? this.over,
        overText: overText ?? this.overText,
        overContainer: overContainer ?? this.overContainer,
        track: track ?? this.track,
      );

  @override
  WMMoneyColors lerp(ThemeExtension<WMMoneyColors>? other, double t) {
    if (other is! WMMoneyColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return WMMoneyColors(
      income: l(income, other.income),
      incomeText: l(incomeText, other.incomeText),
      incomeContainer: l(incomeContainer, other.incomeContainer),
      caution: l(caution, other.caution),
      cautionText: l(cautionText, other.cautionText),
      cautionContainer: l(cautionContainer, other.cautionContainer),
      over: l(over, other.over),
      overText: l(overText, other.overText),
      overContainer: l(overContainer, other.overContainer),
      track: l(track, other.track),
    );
  }
}

extension WMThemeContext on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// Money colours; falls back to the light set when a bare `ThemeData`
  /// (for example in a test) has no extension registered.
  WMMoneyColors get money =>
      Theme.of(this).extension<WMMoneyColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? WMMoneyColors.dark
          : WMMoneyColors.light);
}
