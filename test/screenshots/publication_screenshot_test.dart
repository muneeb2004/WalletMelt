@Tags(['screenshot'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screenshot_demo_data.dart';
import 'screenshot_harness.dart';
import 'screenshot_manifest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ScreenshotHarness.loadFonts();
  });

  group('WalletMelt Publication Screenshots', () {
    tearDown(() {
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.clearAllTestValues();
    });
    for (int i = 0; i < screenshotTargets.length; i++) {
      final target = screenshotTargets[i];
      final label = '[${(i + 1).toString().padLeft(2, '0')}/${screenshotTargets.length}] ${target.id}';

      testWidgets(label, (tester) async {
        ScreenshotHarness.setupViewport(tester);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final bundle = createDemoDataBundle();
        addTearDown(() => bundle.pinLockController.dispose());

        final widget = target.builder(bundle);
        final appState = target.isDark ? bundle.darkAppState : bundle.lightAppState;

        await ScreenshotHarness.captureAndValidate(
          tester: tester,
          widget: widget,
          relativePath: target.relativePath,
          appState: appState,
          pinLockController: bundle.pinLockController,
          isDark: target.isDark,
          interaction: target.interaction != null
              ? (t) => target.interaction!(t, bundle)
              : null,
          settleGracefully: target.settleGracefully,
        );
      });
    }

    test('Generate and verify manifest.json', () async {
      final manifestFile = await writeManifestJson(screenshotTargets);
      expect(manifestFile.existsSync(), isTrue);
      // ignore: avoid_print
      print('✓ All ${screenshotTargets.length} screenshots verified in manifest.json');
    });
  });
}
