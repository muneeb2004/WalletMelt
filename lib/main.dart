import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app/wallet_melt_app.dart';
import 'src/utils/shader_warmup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await prewarmAppShaders();
  runApp(const WalletMeltBootstrap());
}
