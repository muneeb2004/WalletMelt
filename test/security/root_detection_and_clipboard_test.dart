import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/root_detection_service.dart';
import 'package:wallet_melt/src/security/secure_clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RootDetectionService Tests', () {
    const service = RootDetectionService();

    test('clean result returned in non-rooted test environment', () async {
      final result = await service.checkDeviceIntegrity();
      expect(result.isCompromised, isFalse);
      expect(result.detectedIndicators, isEmpty);
    });
  });

  group('SecureClipboardService Tests', () {
    test('copyWithTtl writes data and clears after expiration', () async {
      const secret = 'sensitive_card_or_amount_data';

      await SecureClipboardService.copyWithTtl(
        secret,
        ttl: const Duration(milliseconds: 50),
      );

      final dataBefore = await SecureClipboardService.getText();
      expect(dataBefore, secret);

      // Wait for TTL expiration
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final dataAfter = await SecureClipboardService.getText();
      expect(dataAfter, '');
    });
  });
}
