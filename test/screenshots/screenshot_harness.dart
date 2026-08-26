import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';

class ScreenshotHarness {
  static bool _fontsLoaded = false;

  /// Loads project declared fonts and Material icon fonts for publication rendering.
  static Future<void> loadFonts() async {
    if (_fontsLoaded) return;

    final fontFiles = [
      ('MaterialIcons', 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf'),
      ('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
      ('packages/cupertino_icons/CupertinoIcons', 'build/unit_test_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    ];

    for (final (family, path) in fontFiles) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final loader = FontLoader(family);
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
          await loader.load();
        }
      } catch (_) {}
    }

    _fontsLoaded = true;
  }

  /// Sets up test view for exact physical 1080 x 2400 viewport.
  static void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0; // Logical 360 x 800 -> Physical 1080 x 2400
  }

  /// Safely settles the widget tree without hanging on infinite repeating animations (e.g. blinking cursors)
  static Future<void> _safeSettle(WidgetTester tester, {bool settleGracefully = true}) async {
    if (settleGracefully) {
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Captures a target widget and immediately validates the generated PNG.
  static Future<File> captureAndValidate({
    required WidgetTester tester,
    required Widget widget,
    required String relativePath,
    required AppState appState,
    required PinLockController pinLockController,
    required bool isDark,
    Future<void> Function(WidgetTester tester)? interaction,
    bool settleGracefully = true,
  }) async {
    final boundaryKey = GlobalKey();

    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<PinLockController>.value(value: pinLockController),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: isDark ? WalletMeltTheme.dark() : WalletMeltTheme.light(),
            builder: (context, child) {
              return RepaintBoundary(
                key: boundaryKey,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: widget,
          ),
        ),
      );

      await _safeSettle(tester, settleGracefully: settleGracefully);

      if (interaction != null) {
        await interaction(tester);
        await _safeSettle(tester, settleGracefully: settleGracefully);
      }

      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Failed to find RenderRepaintBoundary for $relativePath');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode PNG ByteData for $relativePath');
      }
      final bytes = byteData.buffer.asUint8List();

      final outputFile = File('walletmelt_screenshots/$relativePath');
      outputFile.parent.createSync(recursive: true);
      outputFile.writeAsBytesSync(bytes, flush: true);

      // Immediate In-Line Validation
      validatePngFile(outputFile, relativePath, expectedWidth: 1080, expectedHeight: 2400);

      // Cleanly unmount and drain transient frame callbacks
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 500));

      // ignore: avoid_print
      print('  ✓ [Validated 1080x2400] $relativePath (${bytes.length} bytes)');
      return outputFile;
    } catch (e, stack) {
      // ignore: avoid_print
      print('''
================================================================================
SCREENSHOT GENERATION FAILED
Target Path: walletmelt_screenshots/$relativePath
Theme: ${isDark ? 'Dark' : 'Light'}
Error: $e
Stack Trace:
$stack
================================================================================
''');
      rethrow;
    }
  }

  /// Strictly validates file existence, PNG header magic bytes, resolution, and non-blank contents.
  static void validatePngFile(
    File file,
    String identifier, {
    int expectedWidth = 1080,
    int expectedHeight = 2400,
  }) {
    if (!file.existsSync()) {
      throw StateError('FAIL [$identifier]: Output file does not exist at ${file.path}');
    }

    final bytes = file.readAsBytesSync();
    if (bytes.length < 2048) {
      throw StateError('FAIL [$identifier]: File size too small (${bytes.length} bytes), image likely empty');
    }

    // Verify PNG signature: \x89PNG\r\n\x1a\n (8 bytes)
    const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (int i = 0; i < pngSignature.length; i++) {
      if (bytes[i] != pngSignature[i]) {
        throw StateError('FAIL [$identifier]: Invalid PNG magic bytes at byte $i');
      }
    }

    // Decode IHDR dimensions (starts at byte 16)
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];

    if (width != expectedWidth || height != expectedHeight) {
      throw StateError(
        'FAIL [$identifier]: PNG dimensions are ${width}x$height; expected ${expectedWidth}x$expectedHeight',
      );
    }
  }
}
