#!/usr/bin/env bash
set -e

echo "======================================================="
echo "  WalletMelt Standardized APK Build Pipeline"
echo "======================================================="

OUTPUT_DIR="build/app/outputs/flutter-apk"

# Ensure stripped native libraries are always freshly generated
rm -rf build/app/intermediates/stripped_native_libs 2>/dev/null || true

# 1. Production Universal Release APK
echo "[1/3] Building Production Universal Release APK..."
flutter build apk --flavor production --release

# 2. Production Split-per-ABI Release APKs
echo "[2/3] Building Production Split-per-ABI Release APKs..."
flutter build apk --flavor production --release --split-per-abi

# 3. Screenshots Release APK
echo "[3/3] Building Screenshots Release APK (SCREENSHOT_MODE=true)..."
flutter build apk --flavor screenshots --release --dart-define=SCREENSHOT_MODE=true

# Mirror production binaries to legacy non-flavor paths for backwards compatibility
cp "$OUTPUT_DIR/app-production-release.apk" "$OUTPUT_DIR/app-release.apk" 2>/dev/null || true
cp "$OUTPUT_DIR/app-arm64-v8a-production-release.apk" "$OUTPUT_DIR/app-arm64-v8a-release.apk" 2>/dev/null || true
cp "$OUTPUT_DIR/app-armeabi-v7a-production-release.apk" "$OUTPUT_DIR/app-armeabi-v7a-release.apk" 2>/dev/null || true
cp "$OUTPUT_DIR/app-x86_64-production-release.apk" "$OUTPUT_DIR/app-x86_64-release.apk" 2>/dev/null || true

echo "======================================================="
echo "  Generated APK Artifacts in $OUTPUT_DIR:"
echo "======================================================="
ls -lh "$OUTPUT_DIR"/*.apk
