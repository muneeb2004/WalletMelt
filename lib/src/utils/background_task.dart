import 'package:flutter/foundation.dart';

import 'platform_info.dart';

/// Runs [callback] on a background isolate so CPU-heavy work (PBKDF2, AES)
/// does not freeze the UI.
///
/// Under `flutter test` and on web it runs inline: isolates inside
/// `testWidgets` hang on the fake clock, and web has no isolates.
Future<R> runInBackground<Q, R>(ComputeCallback<Q, R> callback, Q message) {
  if (PlatformInfo.isFlutterTest || PlatformInfo.isWeb) {
    try {
      return Future.value(callback(message));
    } catch (e, s) {
      return Future.error(e, s);
    }
  }
  return compute(callback, message);
}
