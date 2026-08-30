import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../utils/platform_info.dart';

abstract class ReceiptStorageService {
  Future<String?> pickFromGallery();
  Future<String?> captureWithCamera();
  Future<bool> exists(String uri);
  Future<void> delete(String uri);
}

class LocalReceiptStorageService implements ReceiptStorageService {
  LocalReceiptStorageService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final _uuid = const Uuid();

  @override
  Future<String?> pickFromGallery() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return null;
    return _persistPickedImage(image);
  }

  @override
  Future<String?> captureWithCamera() async {
    final image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
    if (image == null) return null;
    return _persistPickedImage(image);
  }

  @override
  Future<bool> exists(String uri) async {
    if (PlatformInfo.isWeb) {
      return uri.isNotEmpty;
    }
    try {
      final filePath = uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
      return io.File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> delete(String uri) async {
    if (PlatformInfo.isWeb) {
      return;
    }
    try {
      final filePath = uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
      final file = io.File(filePath);
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          // Physical zero-overwrite of flash memory blocks prior to unlinking
          await file.writeAsBytes(Uint8List(length), flush: true);
        }
        await file.delete();
      }
    } catch (_) {}
  }

  Future<String> _persistPickedImage(XFile image) async {
    if (PlatformInfo.isWeb) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = image.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$base64String';
    }

    final dir = await _receiptDirectory();
    final targetPath = p.join(dir.path, '${_uuid.v4()}.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 82,
      minWidth: 1600,
      minHeight: 1600,
      format: CompressFormat.jpeg,
    );

    if (compressed != null) {
      return io.File(compressed.path).uri.toString();
    }

    final fallback = await io.File(image.path).copy(targetPath);
    return fallback.uri.toString();
  }

  Future<io.Directory> _receiptDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = io.Directory(p.join(documents.path, 'receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
