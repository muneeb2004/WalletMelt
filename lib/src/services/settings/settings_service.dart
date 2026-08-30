import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../types/settings.dart';
import '../../utils/platform_info.dart';

class SettingsService {
  static const _currencyKey = 'settings.currency';
  static const _themeKey = 'settings.themePreference';
  static const _onboardingKey = 'settings.hasCompletedOnboarding';
  static const _privacyPolicyKey = 'settings.hasAcceptedPrivacyPolicy';
  static const _lastExportKey = 'settings.lastExportedAt';
  static const _monthlyBudgetAmountKey = 'settings.monthlyBudgetAmount';

  final _secureStorage = const FlutterSecureStorage();

  // In-memory fallback for testing/web
  static final Map<String, String> _testStorage = {};

  Future<void> _writeSecure(String key, String value) async {
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      _testStorage[key] = value;
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> _readSecure(String key) async {
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      return _testStorage[key];
    }
    return await _secureStorage.read(key: key);
  }

  Future<void> _deleteSecure(String key) async {
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      _testStorage.remove(key);
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Future<WalletMeltSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // One-time data migration from insecure store
    double? monthlyBudget;
    if (prefs.containsKey(_monthlyBudgetAmountKey)) {
      final value = prefs.getDouble(_monthlyBudgetAmountKey);
      if (value != null) {
        monthlyBudget = value;
        await _writeSecure(_monthlyBudgetAmountKey, value.toString());
      }
      await prefs.remove(_monthlyBudgetAmountKey);
    } else {
      final secureVal = await _readSecure(_monthlyBudgetAmountKey);
      if (secureVal != null) {
        monthlyBudget = double.tryParse(secureVal);
      }
    }

    return WalletMeltSettings(
      currency:
          prefs.getString(_currencyKey) ?? WalletMeltSettings.defaults.currency,
      themePreference: _themeFromName(prefs.getString(_themeKey)),
      hasCompletedOnboarding: prefs.getBool(_onboardingKey) ?? false,
      hasAcceptedPrivacyPolicy: prefs.getBool(_privacyPolicyKey) ?? false,
      lastExportedAt: prefs.getString(_lastExportKey),
      monthlyBudgetAmount: monthlyBudget,
    );
  }

  Future<void> save(WalletMeltSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, settings.currency);
    await prefs.setString(_themeKey, settings.themePreference.name);
    await prefs.setBool(_onboardingKey, settings.hasCompletedOnboarding);
    await prefs.setBool(_privacyPolicyKey, settings.hasAcceptedPrivacyPolicy);
    
    final lastExportedAt = settings.lastExportedAt;
    if (lastExportedAt != null) {
      await prefs.setString(_lastExportKey, lastExportedAt);
    }

    
    final monthlyBudget = settings.monthlyBudgetAmount;
    if (monthlyBudget != null) {
      await _writeSecure(_monthlyBudgetAmountKey, monthlyBudget.toString());
      // Ensure we clear the insecure pref
      await prefs.remove(_monthlyBudgetAmountKey);
    } else {
      await _deleteSecure(_monthlyBudgetAmountKey);
      await prefs.remove(_monthlyBudgetAmountKey);
    }
  }

  ThemePreference _themeFromName(String? name) {
    for (final value in ThemePreference.values) {
      if (value.name == name) return value;
    }
    return ThemePreference.system;
  }
}
