import 'dart:ui';
import '../components/glass/app_background.dart';

/// Pre-warms custom painter shaders (RadialGradient and Blur pipelines under Impeller/Skia)
/// at startup to prevent frame drop or jank on first launch.
Future<void> prewarmAppShaders() async {
  try {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 800);

    // Warm up dark mode gradient shader
    final darkPainter = BackgroundOrbsPainter(isDark: true);
    darkPainter.paint(canvas, size);

    // Warm up light mode gradient shader
    final lightPainter = BackgroundOrbsPainter(isDark: false);
    lightPainter.paint(canvas, size);

    final picture = recorder.endRecording();
    await picture.toImage(1, 1);
    picture.dispose();
  } catch (_) {
    // Ignore warmup exceptions gracefully on unsupported headless environments
  }
}
