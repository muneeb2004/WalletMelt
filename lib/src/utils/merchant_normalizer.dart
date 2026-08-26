import '../types/expense.dart';

/// Centralized normalizer for merchant / store names across WalletMelt.
///
/// Ensures consistent lowercase, trimmed, whitespace-collapsed string matching
/// for database lookups, autocomplete search, and mutation change checks.
String normalizeMerchantName(String input) {
  return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Constructs a canonical, collision-proof merchant grouping key for an expense.
///
/// Returns `'store:{storeId}'` if linked, `'vendor:{normalized}'` if vendor is present,
/// or `null` if the expense has no merchant identity.
String? merchantKeyForExpense(Expense expense, [String? preTrimmedVendor]) {
  if (expense.storeId != null && expense.storeId!.trim().isNotEmpty) {
    return 'store:${expense.storeId!.trim()}';
  }
  final raw = preTrimmedVendor ?? expense.vendor?.trim();
  if (raw == null || raw.isEmpty) return null;
  final normalized = normalizeMerchantName(raw);
  if (normalized.isEmpty) return null;
  return 'vendor:$normalized';
}

