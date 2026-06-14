import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/services/export/export_file_writer.dart';

void main() {
  group('ExportFileWriter', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory =
          await Directory.systemTemp.createTemp('walletmelt_export_test_');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('writes UTF-8 CSV content', () async {
      const writer = ExportFileWriter();
      const csv = 'id,title\n1,"Café receipt"\n2,"کراچی grocery"';

      final result = await writer.writeCsv(
        csvText: csv,
        exportKind: 'expenses',
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final bytes = await File(result.path).readAsBytes();
      expect(utf8.decode(bytes), csv);
    });

    test('writes UTF-8 JSON content', () async {
      const writer = ExportFileWriter();
      const json = '{"title":"Café receipt","city":"کراچی"}';

      final result = await writer.writeJson(
        jsonText: json,
        exportKind: 'backup',
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final bytes = await File(result.path).readAsBytes();
      expect(utf8.decode(bytes), json);
      expect(result.fileName, 'walletmelt-backup-20260614-090807.json');
      expect(result.mimeType, ExportFileWriter.jsonMimeType);
      expect(result.byteCount, utf8.encode(json).length);
    });

    test('avoids overwriting same-second JSON backups', () async {
      const writer = ExportFileWriter();
      final createdAt = DateTime(2026, 6, 14, 9, 8, 7);

      final first = await writer.writeJson(
        jsonText: '{"id":1}',
        exportKind: 'backup',
        createdAt: createdAt,
        directory: tempDirectory,
      );
      final second = await writer.writeJson(
        jsonText: '{"id":2}',
        exportKind: 'backup',
        createdAt: createdAt,
        directory: tempDirectory,
      );

      expect(first.fileName, 'walletmelt-backup-20260614-090807.json');
      expect(second.fileName, 'walletmelt-backup-20260614-090807-2.json');
    });

    test('returns correct file name and path', () async {
      const writer = ExportFileWriter();

      final result = await writer.writeCsv(
        csvText: 'id,title\n1,Rent',
        exportKind: 'expenses',
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      expect(result.fileName, 'walletmelt-expenses-20260614-090807.csv');
      expect(result.path, p.join(tempDirectory.path, result.fileName));
      expect(await File(result.path).exists(), isTrue);
    });

    test('returns correct byte count and metadata', () async {
      const writer = ExportFileWriter();
      const csv = 'id,title\n1,Café';
      final createdAt = DateTime(2026, 6, 14, 9, 8, 7);

      final result = await writer.writeCsv(
        csvText: csv,
        exportKind: 'expenses',
        createdAt: createdAt,
        directory: tempDirectory,
      );

      expect(result.mimeType, ExportFileWriter.csvMimeType);
      expect(result.byteCount, utf8.encode(csv).length);
      expect(result.createdAt, createdAt);
    });

    test('uses directory override and creates it when missing', () async {
      const writer = ExportFileWriter();
      final nestedDirectory =
          Directory(p.join(tempDirectory.path, 'exports', 'csv'));

      final result = await writer.writeCsv(
        csvText: 'id,title\n1,Rent',
        exportKind: 'expenses',
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: nestedDirectory,
      );

      expect(await nestedDirectory.exists(), isTrue);
      expect(result.path, p.join(nestedDirectory.path, result.fileName));
      expect(await File(result.path).exists(), isTrue);
    });

    test('avoids overwriting same-second exports', () async {
      const writer = ExportFileWriter();
      final createdAt = DateTime(2026, 6, 14, 9, 8, 7);

      final first = await writer.writeCsv(
        csvText: 'id,title\n1,Rent',
        exportKind: 'expenses',
        createdAt: createdAt,
        directory: tempDirectory,
      );
      final second = await writer.writeCsv(
        csvText: 'id,title\n2,Groceries',
        exportKind: 'expenses',
        createdAt: createdAt,
        directory: tempDirectory,
      );

      expect(first.fileName, 'walletmelt-expenses-20260614-090807.csv');
      expect(second.fileName, 'walletmelt-expenses-20260614-090807-2.csv');
      expect(await File(first.path).readAsString(), 'id,title\n1,Rent');
      expect(await File(second.path).readAsString(), 'id,title\n2,Groceries');
    });
  });
}
