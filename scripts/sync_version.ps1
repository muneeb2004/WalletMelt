<#
.SYNOPSIS
Regenerates lib/src/constants/app_version.dart from the `version:` line in pubspec.yaml.

.DESCRIPTION
pubspec.yaml is the single source of truth for the app version. Run before every
build so the in-app version, What's New trigger and backup metadata match the APK.
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root "pubspec.yaml"
$target = Join-Path $root "lib/src/constants/app_version.dart"

$m = Select-String -Path $pubspec -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$'
if (-not $m) { throw "pubspec.yaml must declare 'version: MAJOR.MINOR.PATCH+BUILD'." }
$version = $m.Matches[0].Groups[1].Value
$build = $m.Matches[0].Groups[2].Value

$content = @"
/// Central source of truth for the application version metadata.
///
/// GENERATED from pubspec.yaml by scripts/sync_version.ps1 (run by the build
/// scripts). Edit the version in pubspec.yaml, not here.
abstract final class AppVersion {
  /// The major.minor.patch version string.
  static const String version = '$version';

  /// The build number / version code.
  static const int buildNumber = $build;

  /// Full version with build number formatted for logs and backups.
  static const String fullVersion = '`$version+`$buildNumber';

  /// Display string prefixed with 'v' for badges and UI headers.
  static const String displayVersion = 'v`$version';
}
"@

$text = ($content -replace "`r`n", "`n") + "`n"
[System.IO.File]::WriteAllText($target, $text, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "  Synced app_version.dart -> $version+$build" -ForegroundColor Magenta
