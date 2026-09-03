# WalletMelt Agent Directives

## Standardized APK Build Rule

Whenever the user states **"I need apks"** (or requests building/generating APKs without qualification), the agent must build all three targets:

1. **Production Universal Release APK** (universal fat APK containing all ABIs):
   ```powershell
   flutter build apk --flavor production --release
   ```
   *Output:* `build/app/outputs/flutter-apk/app-production-release.apk`

2. **Production Split-per-ABI Release APKs** (optimized per-architecture binaries):
   ```powershell
   flutter build apk --flavor production --release --split-per-abi
   ```
   *Outputs:*
   - `build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk`
   - `build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk`
   - `build/app/outputs/flutter-apk/app-x86_64-production-release.apk`

3. **Screenshots Release APK** (screenshots flavor pre-seeded with mock data):
   ```powershell
   flutter build apk --flavor screenshots --release --dart-define=SCREENSHOT_MODE=true
   ```
   *Output:* `build/app/outputs/flutter-apk/app-screenshots-release.apk`

Alternatively, execute the standardized script:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_apks.ps1
```
or in Bash:
```bash
./scripts/build_apks.sh
```

Always report the status, paths, and file sizes (in MB) for all 5 generated APK artifacts upon completion.
