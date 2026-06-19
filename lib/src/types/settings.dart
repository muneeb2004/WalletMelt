enum ThemePreference { system, light, dark }

class WalletMeltSettings {
  const WalletMeltSettings({
    required this.currency,
    required this.themePreference,
    required this.hasCompletedOnboarding,
    this.lastExportedAt,
    this.monthlyBudgetAmount,
  });

  final String currency;
  final ThemePreference themePreference;
  final bool hasCompletedOnboarding;
  final String? lastExportedAt;
  final double? monthlyBudgetAmount;

  WalletMeltSettings copyWith({
    String? currency,
    ThemePreference? themePreference,
    bool? hasCompletedOnboarding,
    String? lastExportedAt,
    double? monthlyBudgetAmount,
    bool clearMonthlyBudget = false,
  }) {
    return WalletMeltSettings(
      currency: currency ?? this.currency,
      themePreference: themePreference ?? this.themePreference,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      monthlyBudgetAmount: clearMonthlyBudget
          ? null
          : (monthlyBudgetAmount ?? this.monthlyBudgetAmount),
    );
  }

  static const defaults = WalletMeltSettings(
    currency: 'PKR',
    themePreference: ThemePreference.system,
    hasCompletedOnboarding: false,
    monthlyBudgetAmount: null,
  );
}
