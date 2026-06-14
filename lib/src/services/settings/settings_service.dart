import 'package:shared_preferences/shared_preferences.dart';

import '../../types/settings.dart';

class SettingsService {
  static const _currencyKey = 'settings.currency';
  static const _themeKey = 'settings.themePreference';
  static const _onboardingKey = 'settings.hasCompletedOnboarding';
  static const _lastExportKey = 'settings.lastExportedAt';

  Future<WalletMeltSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WalletMeltSettings(
      currency:
          prefs.getString(_currencyKey) ?? WalletMeltSettings.defaults.currency,
      themePreference: _themeFromName(prefs.getString(_themeKey)),
      hasCompletedOnboarding: prefs.getBool(_onboardingKey) ?? false,
      lastExportedAt: prefs.getString(_lastExportKey),
    );
  }

  Future<void> save(WalletMeltSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, settings.currency);
    await prefs.setString(_themeKey, settings.themePreference.name);
    await prefs.setBool(_onboardingKey, settings.hasCompletedOnboarding);
    final lastExportedAt = settings.lastExportedAt;
    if (lastExportedAt != null) {
      await prefs.setString(_lastExportKey, lastExportedAt);
    }
  }

  ThemePreference _themeFromName(String? name) {
    for (final value in ThemePreference.values) {
      if (value.name == name) return value;
    }
    return ThemePreference.system;
  }
}
