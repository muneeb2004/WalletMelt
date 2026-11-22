import 'dart:io';

/// Set with `flutter test --tags screenshot --dart-define=UPDATE_SCREENSHOTS=true`
/// (or the `UPDATE_SCREENSHOTS=true` environment variable) to refresh the
/// tracked publication screenshots.
const bool _updateScreenshotsDefine = bool.fromEnvironment('UPDATE_SCREENSHOTS');

bool get updateScreenshots =>
    _updateScreenshotsDefine ||
    Platform.environment['UPDATE_SCREENSHOTS'] == 'true';

/// Where screenshots are written. A routine `flutter test` renders and
/// validates every screenshot but writes them under `build/`, so it never
/// modifies the tracked files in `walletmelt_screenshots/`.
String get screenshotOutputDir =>
    updateScreenshots ? 'walletmelt_screenshots' : 'build/screenshot_check';
