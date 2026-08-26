import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'backup_encryption_service.dart';

class _ZipDecoderArgs {
  final List<int> bytes;
  const _ZipDecoderArgs(this.bytes);
}

class _ZipDecoderResult {
  final String jsonText;
  final Map<String, dynamic>? metadataJson;
  const _ZipDecoderResult(this.jsonText, this.metadataJson);
}

_ZipDecoderResult _decodeBackupZip(_ZipDecoderArgs args) {
  final archive = ZipDecoder().decodeBytes(args.bytes);
  final backupEntry = archive.findFile('backup.json');
  if (backupEntry == null) {
    throw const FormatException('ZIP backup is missing backup.json');
  }
  final jsonText = utf8.decode(backupEntry.content as List<int>);

  Map<String, dynamic>? metadataJson;
  final metadataEntry = archive.findFile('metadata.json');
  if (metadataEntry != null) {
    try {
      metadataJson = jsonDecode(utf8.decode(metadataEntry.content as List<int>))
          as Map<String, dynamic>;
    } catch (_) {}
  }
  return _ZipDecoderResult(jsonText, metadataJson);
}

Future<R> _runTask<Q, R>(ComputeCallback<Q, R> callback, Q message) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    try {
      return Future.value(callback(message));
    } catch (e, s) {
      return Future.error(e, s);
    }
  }
  return compute(callback, message);
}


/// Represents a parsed backup from either a legacy JSON file or a modern ZIP package.
class WalletMeltBackupFile {
  final String jsonText;
  final List<int>? zipBytes;
  final bool isZip;
  final bool isEncrypted;
  final List<int>? rawEncryptedBytes;
  final Map<String, dynamic>? metadataJson;

  const WalletMeltBackupFile({
    required this.jsonText,
    this.zipBytes,
    this.isZip = false,
    this.isEncrypted = false,
    this.rawEncryptedBytes,
    this.metadataJson,
  });

  /// Loads and detects the backup type from a file path, supporting optional passphrase decryption.
  static Future<WalletMeltBackupFile> fromPath(String filePath, {String? passphrase}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Backup file not found', filePath);
    }
    var bytes = await file.readAsBytes();

    const encryptionService = BackupEncryptionService();
    if (encryptionService.isEncrypted(bytes)) {
      if (passphrase == null || passphrase.isEmpty) {
        return WalletMeltBackupFile(
          jsonText: '',
          isEncrypted: true,
          rawEncryptedBytes: bytes,
        );
      }
      bytes = encryptionService.decrypt(
        encryptedBytes: bytes,
        passphrase: passphrase,
      );
    }

    // Check ZIP file signature: PK\x03\x04
    if (bytes.length > 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      final decoded = await _runTask(_decodeBackupZip, _ZipDecoderArgs(bytes));

      return WalletMeltBackupFile(
        jsonText: decoded.jsonText,
        zipBytes: bytes,
        isZip: true,
        isEncrypted: false,
        metadataJson: decoded.metadataJson,
      );
    } else {
      // Treat as raw JSON text
      final jsonText = utf8.decode(bytes);
      return WalletMeltBackupFile(
        jsonText: jsonText,
        isZip: false,
        isEncrypted: false,
      );
    }
  }

  /// Decrypts an encrypted backup file using [passphrase].
  Future<WalletMeltBackupFile> decryptWith(String passphrase) async {
    if (!isEncrypted || rawEncryptedBytes == null) return this;
    const encryptionService = BackupEncryptionService();
    final decryptedBytes = encryptionService.decrypt(
      encryptedBytes: rawEncryptedBytes!,
      passphrase: passphrase,
    );

    // Check ZIP file signature
    if (decryptedBytes.length > 4 &&
        decryptedBytes[0] == 0x50 &&
        decryptedBytes[1] == 0x4B &&
        decryptedBytes[2] == 0x03 &&
        decryptedBytes[3] == 0x04) {
      final decoded = await _runTask(_decodeBackupZip, _ZipDecoderArgs(decryptedBytes));

      return WalletMeltBackupFile(
        jsonText: decoded.jsonText,
        zipBytes: decryptedBytes,
        isZip: true,
        isEncrypted: false,
        metadataJson: decoded.metadataJson,
      );
    } else {
      final jsonText = utf8.decode(decryptedBytes);
      return WalletMeltBackupFile(
        jsonText: jsonText,
        isZip: false,
        isEncrypted: false,
      );
    }
  }
}


/// Result of backup JSON validation.
class WalletMeltJsonBackupValidationResult {
  final bool isValid;
  final String? error;

  const WalletMeltJsonBackupValidationResult.valid()
      : isValid = true,
        error = null;

  const WalletMeltJsonBackupValidationResult.invalid(this.error)
      : isValid = false;
}

/// A read-only validator for validating an already-generated JSON structure.
/// This validator does not mutate any data.
class WalletMeltJsonBackupValidator {
  const WalletMeltJsonBackupValidator();

  WalletMeltJsonBackupValidationResult validate(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Backup root is not a JSON object.');
      }

      final map = decoded.cast<String, Object?>();

      // Check required top-level keys
      final requiredKeys = [
        'metadata',
        'expenses',
        'grocery_items',
        'categories',
        'budgets',
        'settings'
      ];
      for (final key in requiredKeys) {
        if (!map.containsKey(key)) {
          return WalletMeltJsonBackupValidationResult.invalid(
              'Missing required top-level key: $key');
        }
      }

      // Validate metadata
      final metadata = map['metadata'];
      if (metadata is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Metadata is not a JSON object.');
      }
      final metadataMap = metadata.cast<String, Object?>();

      // Validate format
      final format = metadataMap['format'];
      if (format != 'walletmelt.local_json_backup') {
        return WalletMeltJsonBackupValidationResult.invalid(
            'Unsupported format: $format');
      }

      // Validate format_version and backupVersion (Phase 8 version checking)
      final formatVersion = metadataMap['format_version'];
      if (formatVersion is! int) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Format version is not an integer.');
      }
      if (formatVersion != 1) {
        return WalletMeltJsonBackupValidationResult.invalid(
            'Unsupported format version: $formatVersion');
      }

      final backupVersion = metadataMap['backupVersion'] ?? metadataMap['backup_version'] ?? 1;
      if (backupVersion is num) {
        if (backupVersion.toInt() > 1) {
          return WalletMeltJsonBackupValidationResult.invalid(
              'Backup version $backupVersion is from a newer, unsupported version of WalletMelt.');
        }
      }

      // Validate that arrays are indeed arrays
      if (map['expenses'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'expenses is not an array.');
      }
      if (map['grocery_items'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'grocery_items is not an array.');
      }
      if (map['categories'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'categories is not an array.');
      }
      if (map['budgets'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'budgets is not an array.');
      }

      // Validate settings is object or null
      final settings = map['settings'];
      if (settings != null && settings is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'settings is neither null nor a JSON object.');
      }

      return const WalletMeltJsonBackupValidationResult.valid();
    } on FormatException catch (e) {
      return WalletMeltJsonBackupValidationResult.invalid(
          'Malformed JSON: ${e.message}');
    } catch (e) {
      return WalletMeltJsonBackupValidationResult.invalid(
          'Unexpected parsing error: $e');
    }
  }
}

