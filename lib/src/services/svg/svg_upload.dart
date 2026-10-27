import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'svg_customization_service.dart';

/// Outcome of asking the user for an SVG file.
class SvgUploadResult {
  const SvgUploadResult.cancelled()
      : iconId = null,
        error = null;
  const SvgUploadResult.saved(String this.iconId) : error = null;
  const SvgUploadResult.failed(String this.error) : iconId = null;

  /// `custom:<file>.svg` of the saved icon.
  final String? iconId;

  /// Plain-language reason the file was rejected.
  final String? error;

  bool get cancelled => iconId == null && error == null;
}

/// Lets the user pick an `.svg` file, checks it, and saves it as a new icon.
Future<SvgUploadResult> pickAndSaveSvg() async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );
    // ignore: unnecessary_null_comparison
    if (files == null || files.isEmpty) return const SvgUploadResult.cancelled();
    final file = files.first;
    String? content;
    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) {
      content = utf8.decode(bytes, allowMalformed: true);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    }
    if (content == null || content.trim().isEmpty) {
      return const SvgUploadResult.failed('That file is empty.');
    }
    final id = await SvgCustomizationService.instance.createCustomIcon(content);
    return SvgUploadResult.saved(id);
  } on FormatException catch (e) {
    return SvgUploadResult.failed(e.message);
  } catch (e) {
    return const SvgUploadResult.failed(
        'Could not add that file. Try a different SVG.');
  }
}
