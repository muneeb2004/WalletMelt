import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import 'export_file_writer.dart';

enum ExportShareStatus { success, dismissed, unavailable }

class ExportShareResult {
  const ExportShareResult({
    required this.status,
    required this.raw,
  });

  final ExportShareStatus status;
  final String raw;
}

abstract class ExportShareService {
  Future<ExportShareResult> shareFile(
    ExportFileResult file, {
    Rect? sharePositionOrigin,
    String? subject,
    String? title,
  });
}

class SharePlusExportShareService implements ExportShareService {
  const SharePlusExportShareService();

  @override
  Future<ExportShareResult> shareFile(
    ExportFileResult file, {
    Rect? sharePositionOrigin,
    String? subject,
    String? title,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: file.mimeType,
            name: file.fileName,
            length: file.byteCount,
          ),
        ],
        fileNameOverrides: [file.fileName],
        subject: subject ?? 'WalletMelt expenses CSV',
        title: title ?? 'Export expenses CSV',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return ExportShareResult(
      status: _mapStatus(result.status),
      raw: result.raw,
    );
  }

  ExportShareStatus _mapStatus(ShareResultStatus status) {
    return switch (status) {
      ShareResultStatus.success => ExportShareStatus.success,
      ShareResultStatus.dismissed => ExportShareStatus.dismissed,
      ShareResultStatus.unavailable => ExportShareStatus.unavailable,
    };
  }
}
