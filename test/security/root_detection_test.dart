import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/root_detection_service.dart';

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
}
