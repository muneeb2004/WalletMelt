import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../types/budget.dart';
import '../types/debt.dart';
import '../types/expense.dart';
import '../types/subscription.dart';
import '../utils/platform_info.dart';

/// Represents a cryptographic ledger anchor $(N, \text{Block}_N)$.
class LedgerAnchor {
  final int recordCount;
  final String blockHashHex;

  const LedgerAnchor({
    required this.recordCount,
    required this.blockHashHex,
  });

  Map<String, dynamic> toJson() => {
        'recordCount': recordCount,
        'blockHashHex': blockHashHex,
      };

  factory LedgerAnchor.fromJson(Map<String, dynamic> json) => LedgerAnchor(
        recordCount: json['recordCount'] as int,
        blockHashHex: json['blockHashHex'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerAnchor &&
          runtimeType == other.runtimeType &&
          recordCount == other.recordCount &&
          blockHashHex == other.blockHashHex;

  @override
  int get hashCode => recordCount.hashCode ^ blockHashHex.hashCode;

  @override
  String toString() => 'LedgerAnchor(N: $recordCount, Block_N: $blockHashHex)';
}

/// Abstract interface for signing payloads with the hardware Keystore HMAC key.
abstract class KeystoreMacProvider {
  Future<Uint8List> sign(Uint8List payload);
}

/// Hardware-backed Android Keystore HMAC provider using MethodChannel.
class AndroidKeystoreMacProvider implements KeystoreMacProvider {
  static const _channel = MethodChannel('app.walletmelt.wallet_melt/keystore_mac');

  @override
  Future<Uint8List> sign(Uint8List payload) async {
    final result = await _channel.invokeMethod<Uint8List>('sign', {'payload': payload});
    if (result == null) {
      throw StateError('Keystore MAC signing returned null.');
    }
    return result;
  }
}

/// In-memory HMAC signer used strictly during testing or on non-Android platforms.
class FallbackSoftwareMacProvider implements KeystoreMacProvider {
  final List<int> _keyBytes;

  FallbackSoftwareMacProvider([List<int>? key])
      : _keyBytes = key ?? utf8.encode('walletmelt_software_fallback_hmac_key');

  @override
  Future<Uint8List> sign(Uint8List payload) async {
    final hmac = Hmac(sha256, _keyBytes);
    final digest = hmac.convert(payload);
    return Uint8List.fromList(digest.bytes);
  }
}

/// Service that maintains a Hardware-Backed Keystore HMAC Hash-Chain Ledger
/// over all financial records to detect unauthorized modifications, insertions,
/// or silent row deletions.
class LedgerIntegrityService {
  final KeystoreMacProvider _macProvider;
  final FlutterSecureStorage _storage;

  static const _anchorKey = 'security.ledger_anchor';
  static final Map<String, String> _testStorage = {};

  LedgerIntegrityService({
    KeystoreMacProvider? macProvider,
    FlutterSecureStorage? storage,
  })  : _macProvider = macProvider ??
            (PlatformInfo.isAndroid && !PlatformInfo.isFlutterTest
                ? AndroidKeystoreMacProvider()
                : FallbackSoftwareMacProvider()),
        _storage = storage ?? const FlutterSecureStorage();

  /// Canonical serialization of [Expense].
  String serializeExpense(Expense e) {
    return 'EXPENSE:${e.id}|${e.title}|${e.amount}|${e.currency}|${e.categoryId}|'
        '${e.vendor ?? ''}|${e.storeId ?? ''}|${e.date}|${e.notes ?? ''}|'
        '${e.receiptImageUri ?? ''}|${e.isRecurring ? 1 : 0}|'
        '${e.recurrenceFrequency?.name ?? ''}|${e.subtotalAmount ?? ''}|'
        '${e.taxAmount ?? ''}|${e.createdAt}|${e.updatedAt}|${e.deletedAt ?? ''}';
  }

  /// Canonical serialization of [CategoryBudget].
  String serializeBudget(CategoryBudget b) {
    return 'BUDGET:${b.id}|${b.categoryId}|${b.amount}|${b.currency}|${b.month}|${b.createdAt}|${b.updatedAt}';
  }

  /// Canonical serialization of [DebtRecord].
  String serializeDebt(DebtRecord d) {
    return 'DEBT:${d.id}|${d.personName}|${d.payeeId ?? ''}|${d.type.name}|'
        '${d.principalAmount}|${d.remainingAmount}|${d.currency}|'
        '${d.description ?? ''}|${d.dueDate ?? ''}|${d.settledAt ?? ''}|'
        '${d.status.name}|${d.createdAt}';
  }

  /// Canonical serialization of [Subscription].
  String serializeSubscription(Subscription s) {
    return 'SUB:${s.id}|${s.name}|${s.categoryId}|${s.amount}|'
        '${s.taxAmount ?? ''}|${s.currency}|${s.startDate}|'
        '${s.nextOccurrenceDate}|${s.billingCycle}|${s.status.name}|'
        '${s.createdAt}|${s.updatedAt}|${s.cancelledAt ?? ''}|${s.deletedAt ?? ''}';
  }

  /// Computes the cryptographic hash chain over an ordered list of [serializedEntries].
  ///
  /// Block_0 = HMAC("GENESIS" || Entry_0)
  /// Block_i = HMAC(Block_{i-1} || Entry_i)
  Future<LedgerAnchor> computeAnchor(List<String> serializedEntries) async {
    if (serializedEntries.isEmpty) {
      return const LedgerAnchor(
        recordCount: 0,
        blockHashHex: '0000000000000000000000000000000000000000000000000000000000000000',
      );
    }

    var prevBlockBytes = utf8.encode('GENESIS');

    for (final entry in serializedEntries) {
      final entryBytes = utf8.encode(entry);
      final payload = Uint8List.fromList([...prevBlockBytes, ...entryBytes]);
      final blockBytes = await _macProvider.sign(payload);
      prevBlockBytes = blockBytes;
    }

    final blockHex = prevBlockBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return LedgerAnchor(
      recordCount: serializedEntries.length,
      blockHashHex: blockHex,
    );
  }

  /// Verifies that [serializedEntries] matches [expectedAnchor].
  Future<bool> verifyChain({
    required List<String> serializedEntries,
    required LedgerAnchor expectedAnchor,
  }) async {
    if (serializedEntries.length != expectedAnchor.recordCount) {
      return false;
    }
    final computed = await computeAnchor(serializedEntries);
    return computed == expectedAnchor;
  }

  /// Atomically saves the ledger anchor in secure storage.
  Future<void> persistAnchor(LedgerAnchor anchor) async {
    final jsonStr = jsonEncode(anchor.toJson());
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      _testStorage[_anchorKey] = jsonStr;
      return;
    }
    await _storage.write(key: _anchorKey, value: jsonStr);
  }

  /// Retrieves the saved ledger anchor from secure storage.
  Future<LedgerAnchor?> getPersistedAnchor() async {
    String? raw;
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      raw = _testStorage[_anchorKey];
    } else {
      raw = await _storage.read(key: _anchorKey);
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LedgerAnchor.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears stored anchor (for test reset).
  Future<void> clearAnchor() async {
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      _testStorage.remove(_anchorKey);
      return;
    }
    await _storage.delete(key: _anchorKey);
  }
}
