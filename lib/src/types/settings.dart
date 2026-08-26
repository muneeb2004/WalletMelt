enum ThemePreference { system, light, dark }

class WalletMeltSettings {
  const WalletMeltSettings({
    required this.currency,
    required this.themePreference,
    required this.hasCompletedOnboarding,
    this.hasAcceptedPrivacyPolicy = false,
    this.lastExportedAt,
    this.monthlyBudgetAmount,
  });

  final String currency;
  final ThemePreference themePreference;
  final bool hasCompletedOnboarding;
  final bool hasAcceptedPrivacyPolicy;
  final String? lastExportedAt;
  final double? monthlyBudgetAmount;

  WalletMeltSettings copyWith({
    String? currency,
    ThemePreference? themePreference,
    bool? hasCompletedOnboarding,
    bool? hasAcceptedPrivacyPolicy,
    String? lastExportedAt,
    double? monthlyBudgetAmount,
    bool clearMonthlyBudget = false,
  }) {
    return WalletMeltSettings(
      currency: currency ?? this.currency,
      themePreference: themePreference ?? this.themePreference,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasAcceptedPrivacyPolicy:
          hasAcceptedPrivacyPolicy ?? this.hasAcceptedPrivacyPolicy,
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
    hasAcceptedPrivacyPolicy: false,
    monthlyBudgetAmount: null,
  );
}

