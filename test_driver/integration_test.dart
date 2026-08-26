import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> imageBytes, [Map<String, dynamic>? args]) async {
      final file = File('walletmelt_screenshots/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(imageBytes, flush: true);
      // ignore: avoid_print
      print('✓ [Driver Captured] ${file.path} (${imageBytes.length} bytes)');
      return true;
    },
  );
}
