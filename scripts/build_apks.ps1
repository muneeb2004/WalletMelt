<#
.SYNOPSIS
Standardized build script for WalletMelt APKs.

.DESCRIPTION
Builds all required WalletMelt Android APK targets:
1. Production Release (Universal Fat APK)
2. Production Release (Split-per-ABI APKs: arm64-v8a, armeabi-v7a, x86_64)
3. Screenshots Release (Screenshots Flavor with SCREENSHOT_MODE=true)

.EXAMPLE
.\scripts\build_apks.ps1
#>

[CmdletBinding()]
param(
    [switch]$SkipUniversal,
    [switch]$SkipSplit,
    [switch]$SkipScreenshots
)

$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "  WalletMelt Standardized APK Build Pipeline" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

$outputDir = "build/app/outputs/flutter-apk"

# Step 1: Production Universal Release APK
if (-not $SkipUniversal) {
    Write-Host "[1/3] Building Production Universal Release APK..." -ForegroundColor Yellow
    flutter build apk --flavor production --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed building Production Universal Release APK."
        exit $LASTEXITCODE
    }
    Write-Host "  -> Success: Production Universal APK created.`n" -ForegroundColor Green
}

# Step 2: Production Split-per-ABI Release APKs
if (-not $SkipSplit) {
    Write-Host "[2/3] Building Production Split-per-ABI Release APKs..." -ForegroundColor Yellow
    flutter build apk --flavor production --release --split-per-abi
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed building Production Split-per-ABI Release APKs."
        exit $LASTEXITCODE
    }
    Write-Host "  -> Success: Production Split-per-ABI APKs created.`n" -ForegroundColor Green
}

# Step 3: Screenshots Release APK
if (-not $SkipScreenshots) {
    Write-Host "[3/3] Building Screenshots Release APK (SCREENSHOT_MODE=true)..." -ForegroundColor Yellow
    flutter build apk --flavor screenshots --release --dart-define=SCREENSHOT_MODE=true
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed building Screenshots Release APK."
        exit $LASTEXITCODE
    }
    Write-Host "  -> Success: Screenshots Release APK created.`n" -ForegroundColor Green
}

$sw.Stop()

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Build Completed in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Generated APK Artifacts:" -ForegroundColor Yellow

$expectedApks = @(
    "app-production-release.apk",
    "app-arm64-v8a-production-release.apk",
    "app-armeabi-v7a-production-release.apk",
    "app-x86_64-production-release.apk",
    "app-screenshots-release.apk"
)

foreach ($apk in $expectedApks) {
    $filePath = Join-Path $outputDir $apk
    if (Test-Path $filePath) {
        $fileInfo = Get-Item $filePath
        $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        Write-Host ("  [OK] {0,-40} {1,7} MB  ({2})" -f $apk, $sizeMB, $filePath) -ForegroundColor Green
    } else {
        Write-Host ("  [MISSING] {0}" -f $apk) -ForegroundColor Red
    }
}
Write-Host ""
