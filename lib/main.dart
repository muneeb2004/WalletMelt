import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app/wallet_melt_app.dart';
import 'src/utils/shader_warmup.dart';

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], license);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  GoogleFonts.config.allowRuntimeFetching = false;
  await prewarmAppShaders();
  runApp(const WalletMeltBootstrap());
}
