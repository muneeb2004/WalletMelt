#!/usr/bin/env bash
set -e

echo "======================================================="
echo "  WalletMelt Standardized APK Build Pipeline"
echo "======================================================="

OUTPUT_DIR="build/app/outputs/flutter-apk"

# 1. Production Universal Release APK
echo "[1/3] Building Production Universal Release APK..."
flutter build apk --flavor production --release

# 2. Production Split-per-ABI Release APKs
echo "[2/3] Building Production Split-per-ABI Release APKs..."
flutter build apk --flavor production --release --split-per-abi

# 3. Screenshots Release APK
echo "[3/3] Building Screenshots Release APK (SCREENSHOT_MODE=true)..."
flutter build apk --flavor screenshots --release --dart-define=SCREENSHOT_MODE=true

echo "======================================================="
echo "  Generated APK Artifacts in $OUTPUT_DIR:"
echo "======================================================="
ls -lh "$OUTPUT_DIR"/*.apk
