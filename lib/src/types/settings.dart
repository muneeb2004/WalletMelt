enum ThemePreference { system, light, dark }

class WalletMeltSettings {
  const WalletMeltSettings({
    required this.currency,
    required this.themePreference,
    required this.hasCompletedOnboarding,
    this.hasAcceptedPrivacyPolicy = false,
    this.lastExportedAt,
    this.monthlyBudgetAmount,
    this.lastSeenWhatsNewVersion = '',
    this.budgetPeriodStartDay = 1,
  });

  final String currency;
  final ThemePreference themePreference;
  final bool hasCompletedOnboarding;
  final bool hasAcceptedPrivacyPolicy;
  final String? lastExportedAt;
  final double? monthlyBudgetAmount;
  final String lastSeenWhatsNewVersion;

  /// Day of month (1 to 28) on which a budget period starts (ADR-0013).
  final int budgetPeriodStartDay;

  WalletMeltSettings copyWith({
    String? currency,
    ThemePreference? themePreference,
    bool? hasCompletedOnboarding,
    bool? hasAcceptedPrivacyPolicy,
    String? lastExportedAt,
    double? monthlyBudgetAmount,
    bool clearMonthlyBudget = false,
    String? lastSeenWhatsNewVersion,
    int? budgetPeriodStartDay,
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
      lastSeenWhatsNewVersion:
          lastSeenWhatsNewVersion ?? this.lastSeenWhatsNewVersion,
      budgetPeriodStartDay: budgetPeriodStartDay ?? this.budgetPeriodStartDay,
    );
  }

  static const defaults = WalletMeltSettings(
    currency: 'PKR',
    themePreference: ThemePreference.system,
    hasCompletedOnboarding: false,
    hasAcceptedPrivacyPolicy: false,
    monthlyBudgetAmount: null,
    lastSeenWhatsNewVersion: '',
  );
}

