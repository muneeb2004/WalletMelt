import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'export_file_names.dart';

class ExportFileResult {
  const ExportFileResult({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.byteCount,
    required this.createdAt,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final int byteCount;
  final DateTime createdAt;
}

class ExportFileWriter {
  const ExportFileWriter();

  static const String csvMimeType = 'text/csv';
  static const String jsonMimeType = 'application/json';

  Future<ExportFileResult> writeCsv({
    required String csvText,
    required String exportKind,
    DateTime? createdAt,
    Directory? directory,
  }) async {
    final timestamp = createdAt ?? DateTime.now();
    final targetDirectory = directory ?? await getTemporaryDirectory();
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final baseFileName = buildWalletMeltExportFileName(
      exportKind: exportKind,
      createdAt: timestamp,
    );
    final bytes = utf8.encode(csvText);
    final file = await _unusedFile(targetDirectory, baseFileName);

    await file.writeAsBytes(bytes, flush: true);

    return ExportFileResult(
      path: file.path,
      fileName: p.basename(file.path),
      mimeType: csvMimeType,
      byteCount: bytes.length,
      createdAt: timestamp,
    );
  }

  Future<ExportFileResult> writeJson({
    required String jsonText,
    required String exportKind,
    DateTime? createdAt,
    Directory? directory,
  }) async {
    final timestamp = createdAt ?? DateTime.now();
    final targetDirectory = directory ?? await getTemporaryDirectory();
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final baseFileName = buildWalletMeltExportFileName(
      exportKind: exportKind,
      createdAt: timestamp,
      extension: 'json',
    );
    final bytes = utf8.encode(jsonText);
    final file = await _unusedFile(targetDirectory, baseFileName);

    await file.writeAsBytes(bytes, flush: true);

    return ExportFileResult(
      path: file.path,
      fileName: p.basename(file.path),
      mimeType: jsonMimeType,
      byteCount: bytes.length,
      createdAt: timestamp,
    );
  }

  static const String zipMimeType = 'application/zip';

  Future<ExportFileResult> writeZip({
    required List<int> zipBytes,
    required String exportKind,
    DateTime? createdAt,
    Directory? directory,
  }) async {
    final timestamp = createdAt ?? DateTime.now();
    final targetDirectory = directory ?? await getTemporaryDirectory();
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final baseFileName = buildWalletMeltExportFileName(
      exportKind: exportKind,
      createdAt: timestamp,
      extension: 'zip',
    );
    final file = await _unusedFile(targetDirectory, baseFileName);

    await file.writeAsBytes(zipBytes, flush: true);

    return ExportFileResult(
      path: file.path,
      fileName: p.basename(file.path),
      mimeType: zipMimeType,
      byteCount: zipBytes.length,
      createdAt: timestamp,
    );
  }

  Future<File> _unusedFile(Directory directory, String fileName) async {
    final firstFile = File(p.join(directory.path, fileName));
    if (!await firstFile.exists()) return firstFile;

    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    var counter = 2;
    while (true) {
      final candidate =
          File(p.join(directory.path, '$baseName-$counter$extension'));
      if (!await candidate.exists()) return candidate;
      counter += 1;
    }
  }
}

