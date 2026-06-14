enum ThemePreference { system, light, dark }

class WalletMeltSettings {
  const WalletMeltSettings({
    required this.currency,
    required this.themePreference,
    required this.hasCompletedOnboarding,
    this.lastExportedAt,
  });

  final String currency;
  final ThemePreference themePreference;
  final bool hasCompletedOnboarding;
  final String? lastExportedAt;

  WalletMeltSettings copyWith({
    String? currency,
    ThemePreference? themePreference,
    bool? hasCompletedOnboarding,
    String? lastExportedAt,
  }) {
    return WalletMeltSettings(
      currency: currency ?? this.currency,
      themePreference: themePreference ?? this.themePreference,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
    );
  }

  static const defaults = WalletMeltSettings(
    currency: 'PKR',
    themePreference: ThemePreference.system,
    hasCompletedOnboarding: false,
  );
}
