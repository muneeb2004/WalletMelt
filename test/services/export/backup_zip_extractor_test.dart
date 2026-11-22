import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/services/export/backup_zip_extractor.dart';

List<int> _zip(Map<String, String> entries) {
  final archive = Archive();
  entries.forEach((name, text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

void main() {
  late Directory root;
  late Directory dest;

  setUp(() {
    root = Directory.systemTemp.createTempSync('wm_zip_test_');
    dest = Directory(p.join(root.path, 'extract'))..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('extracts normal entries inside the destination', () {
    extractBackupZip(BackupZipExtractArgs(
      _zip({'backup.json': '{}', 'receipts/a.jpg': 'img'}),
      dest.path,
    ));
    expect(File(p.join(dest.path, 'backup.json')).readAsStringSync(), '{}');
    expect(File(p.join(dest.path, 'receipts', 'a.jpg')).existsSync(), isTrue);
  });

  test('rejects parent-directory traversal and writes nothing', () {
    expect(
      () => extractBackupZip(BackupZipExtractArgs(
        _zip({'backup.json': '{}', '../escaped.txt': 'x'}),
        dest.path,
      )),
      throwsA(isA<UnsafeBackupArchiveException>()),
    );
    expect(File(p.join(root.path, 'escaped.txt')).existsSync(), isFalse);
    expect(File(p.join(dest.path, 'backup.json')).existsSync(), isFalse);
  });

  test('rejects nested traversal that resolves outside', () {
    expect(
      () => BackupZipExtractor.safeDestination(dest.path, 'receipts/../../x'),
      throwsA(isA<UnsafeBackupArchiveException>()),
    );
  });

  test('rejects absolute and drive-letter paths', () {
    for (final name in ['/etc/passwd', r'C:\evil.txt', 'C:/evil.txt', r'\evil']) {
      expect(
        () => BackupZipExtractor.safeDestination(dest.path, name),
        throwsA(isA<UnsafeBackupArchiveException>()),
        reason: name,
      );
    }
  });

  test('rejects archives over the size cap', () {
    expect(
      () => extractBackupZip(BackupZipExtractArgs(
        _zip({'big.bin': 'x' * 2048}),
        dest.path,
        maxTotalBytes: 1024,
      )),
      throwsA(isA<UnsafeBackupArchiveException>()),
    );
  });

  test('rejects archives with too many entries', () {
    expect(
      () => extractBackupZip(BackupZipExtractArgs(
        _zip({for (var i = 0; i < 5; i++) 'f$i.txt': 'x'}),
        dest.path,
        maxEntries: 3,
      )),
      throwsA(isA<UnsafeBackupArchiveException>()),
    );
  });
}
