import 'package:flutter/services.dart';

class WindowSecurityChannel {
  static const MethodChannel _channel = MethodChannel(
    'app.walletmelt.wallet_melt/window_security',
  );

  static Future<void> setSecureScreenEnabled(bool enabled) async {
    await _channel.invokeMethod<void>(
      'setSecureScreenEnabled',
      <String, Object?>{'enabled': enabled},
    );
  }
}
