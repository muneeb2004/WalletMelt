import 'dart:io';
import 'package:flutter/foundation.dart';

/// Result of offline heuristic root and platform compromise checks.
class RootDetectionResult {
  final bool isCompromised;
  final List<String> detectedIndicators;

  const RootDetectionResult({
    required this.isCompromised,
    required this.detectedIndicators,
  });

  const RootDetectionResult.clean()
      : isCompromised = false,
        detectedIndicators = const [];
}

/// Service providing heuristic offline root and jailbreak indicators detection.
///
/// Note on Threat Model: Client-side binary path and process checks cannot cryptographically
/// block modern stealth root solutions (e.g. Magisk, Zygisk, KernelSU). These checks serve
/// as an informational non-blocking security advisory. Cryptographic attestation is scheduled
/// for V3 via Google Play Integrity API.
class RootDetectionService {
  const RootDetectionService();

  static const List<String> _knownSuPaths = [
    '/system/bin/su',
    '/system/xbin/su',
    '/sbin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/data/local/su',
    '/system/app/Superuser.apk',
    '/system/app/SuperSU.apk',
  ];

  /// Executes multi-vector heuristic compromise checks.
  Future<RootDetectionResult> checkDeviceIntegrity() async {
    if (kIsWeb || !Platform.isAndroid || Platform.environment.containsKey('FLUTTER_TEST')) {
      return const RootDetectionResult.clean();
    }

    final indicators = <String>[];

    // Vector 1: Check known su binary and superuser package paths
    for (final path in _knownSuPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          indicators.add('Su binary detected at $path');
        }
      } catch (_) {}
    }

    // Vector 2: Check for test-keys build tags in build properties
    try {
      final buildProp = File('/system/build.prop');
      if (await buildProp.exists()) {
        final content = await buildProp.readAsString();
        if (content.contains('test-keys') || content.contains('ro.build.tags=test-keys')) {
          indicators.add('Test-keys custom build tags detected');
        }
      }
    } catch (_) {}

    // Vector 3: Process execution probe
    try {
      final result = await Process.run('which', ['su']).timeout(
        const Duration(milliseconds: 500),
      );
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        indicators.add('Executable su binary reachable via PATH');
      }
    } catch (_) {}

    return RootDetectionResult(
      isCompromised: indicators.isNotEmpty,
      detectedIndicators: indicators,
    );
  }
}
