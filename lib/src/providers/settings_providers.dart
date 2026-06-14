import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/receipt_storage/receipt_storage_service.dart';
import '../services/settings/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return LocalReceiptStorageService();
});
