#!/usr/bin/env bash
# Regenerates lib/src/constants/app_version.dart from pubspec.yaml (single source of truth).
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW=$(grep -E '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$' "$ROOT/pubspec.yaml" | head -n 1 | awk '{print $2}' | tr -d '\r')
if [ -z "$RAW" ]; then
  echo "pubspec.yaml must declare 'version: MAJOR.MINOR.PATCH+BUILD'." >&2
  exit 1
fi
VERSION="${RAW%%+*}"
BUILD="${RAW##*+}"

cat > "$ROOT/lib/src/constants/app_version.dart" <<EOF
/// Central source of truth for the application version metadata.
///
/// GENERATED from pubspec.yaml by scripts/sync_version.ps1 (run by the build
/// scripts). Edit the version in pubspec.yaml, not here.
abstract final class AppVersion {
  /// The major.minor.patch version string.
  static const String version = '$VERSION';

  /// The build number / version code.
  static const int buildNumber = $BUILD;

  /// Full version with build number formatted for logs and backups.
  static const String fullVersion = '\$version+\$buildNumber';

  /// Display string prefixed with 'v' for badges and UI headers.
  static const String displayVersion = 'v\$version';
}
EOF
echo "  Synced app_version.dart -> $VERSION+$BUILD"
