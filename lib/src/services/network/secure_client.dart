import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class SecureClient {
  static const String _pinnedHash = String.fromEnvironment('PINNED_SHA256', defaultValue: '');

  static HttpClient createPinnedClient() {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (_pinnedHash.isEmpty) {
        // Fallback: log to crash reporter under kDebugMode, close connection
        if (kDebugMode) {
          debugPrint('Pinning configuration missing. Terminating connection.');
        }
        return false; // Close connection
      }
      
      // Perform certificate pinning check
      final sha256Bytes = sha256.convert(cert.der).bytes;
      final sha256Hex = sha256Bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
      
      final expected = _pinnedHash.toLowerCase().replaceAll(':', '');
      if (sha256Hex == expected) {
        return true; // Pin match, allow connection
      }

      if (kDebugMode) {
        debugPrint('Certificate pinning mismatch for host $host! Expected: $expected, Got: $sha256Hex');
      }
      return false; // Close connection
    };
    return client;
  }
}
