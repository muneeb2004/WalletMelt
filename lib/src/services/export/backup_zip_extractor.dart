import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Thrown when a backup ZIP contains an entry that must not be written to
/// disk (path traversal, absolute path, symbolic link) or is too large.
class UnsafeBackupArchiveException implements Exception {
  const UnsafeBackupArchiveException(this.message);

  final String message;

  @override
  String toString() => 'UnsafeBackupArchiveException: $message';
}

/// Arguments for [extractBackupZip], so it can run in a background isolate.
class BackupZipExtractArgs {
  const BackupZipExtractArgs(
    this.zipBytes,
    this.extractPath, {
    this.maxTotalBytes = BackupZipExtractor.defaultMaxTotalBytes,
    this.maxEntries = BackupZipExtractor.defaultMaxEntries,
  });

  final List<int> zipBytes;
  final String extractPath;
  final int maxTotalBytes;
  final int maxEntries;
}

class BackupZipExtractor {
  const BackupZipExtractor._();

  /// Upper bound on the uncompressed size of all entries (512 MB).
  static const int defaultMaxTotalBytes = 512 * 1024 * 1024;

  /// Upper bound on the number of entries in one backup archive.
  static const int defaultMaxEntries = 20000;

  /// Returns the absolute destination for [entryName] inside [extractPath],
  /// or throws if the entry would land outside it.
  static String safeDestination(String extractPath, String entryName) {
    final normalizedName = entryName.replaceAll('\\', '/');
    if (normalizedName.isEmpty ||
        normalizedName.startsWith('/') ||
        p.posix.isAbsolute(normalizedName) ||
        p.windows.isAbsolute(normalizedName) ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalizedName)) {
      throw UnsafeBackupArchiveException(
          'Backup contains an absolute path: $entryName');
    }
    final root = p.normalize(p.absolute(extractPath));
    final dest = p.normalize(p.join(root, normalizedName));
    if (!p.isWithin(root, dest)) {
      throw UnsafeBackupArchiveException(
          'Backup entry escapes the restore folder: $entryName');
    }
    return dest;
  }
}

/// Extracts a backup ZIP into [BackupZipExtractArgs.extractPath].
///
/// Every entry is validated before anything is written, so an unsafe archive
/// leaves the destination untouched.
void extractBackupZip(BackupZipExtractArgs args) {
  final archive = ZipDecoder().decodeBytes(args.zipBytes);

  final planned = <(String, ArchiveFile)>[];
  var totalBytes = 0;
  var entries = 0;
  for (final entry in archive) {
    entries++;
    if (entries > args.maxEntries) {
      throw UnsafeBackupArchiveException(
          'Backup has more than ${args.maxEntries} entries.');
    }
    if (entry.isSymbolicLink) {
      throw UnsafeBackupArchiveException(
          'Backup contains a symbolic link: ${entry.name}');
    }
    final dest = BackupZipExtractor.safeDestination(args.extractPath, entry.name);
    if (!entry.isFile) continue;
    totalBytes += entry.size;
    if (entry.size < 0 || totalBytes > args.maxTotalBytes) {
      throw const UnsafeBackupArchiveException('Backup is too large to restore.');
    }
    planned.add((dest, entry));
  }

  var writtenBytes = 0;
  for (final (dest, entry) in planned) {
    final data = entry.content;
    // The declared size can lie; count what was actually decompressed.
    writtenBytes += data.length;
    if (writtenBytes > args.maxTotalBytes) {
      throw const UnsafeBackupArchiveException('Backup is too large to restore.');
    }
    final file = File(dest);
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
  }
}
