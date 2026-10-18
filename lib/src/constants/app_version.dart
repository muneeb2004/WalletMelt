/// Central source of truth for the application version metadata.
///
/// GENERATED from pubspec.yaml by scripts/sync_version.ps1 (run by the build
/// scripts). Edit the version in pubspec.yaml, not here.
abstract final class AppVersion {
  /// The major.minor.patch version string.
  static const String version = '1.6.0';

  /// The build number / version code.
  static const int buildNumber = 13;

  /// Full version with build number formatted for logs and backups.
  static const String fullVersion = '$version+$buildNumber';

  /// Display string prefixed with 'v' for badges and UI headers.
  static const String displayVersion = 'v$version';
}
