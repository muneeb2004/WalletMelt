import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Service abstraction for picking files from the system.
class FilePickerService {
  const FilePickerService();

  /// Prompts the user to pick a JSON file and returns its content as a String.
  /// Returns null if the user cancels or the file cannot be read.
  Future<String?> pickJsonFileContent() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }
      final file = result.files.first;

      final path = file.path;
      if (path != null) {
        return File(path).readAsString();
      }

      final chunks = await file.readAsByteStream().toList();
      return utf8.decode(chunks.expand((chunk) => chunk).toList());
    } catch (_) {
      // Return null on failure or user cancellation.
    }
    return null;
  }
}
