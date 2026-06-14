import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

abstract class ReceiptStorageService {
  Future<String?> pickFromGallery();
  Future<String?> captureWithCamera();
  Future<bool> exists(String uri);
  Future<void> delete(String uri);
}

class LocalReceiptStorageService implements ReceiptStorageService {
  LocalReceiptStorageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final _uuid = const Uuid();

  @override
  Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return null;
    return _persistPickedImage(image);
  }

  @override
  Future<String?> captureWithCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
    if (image == null) return null;
    return _persistPickedImage(image);
  }

  @override
  Future<bool> exists(String uri) async {
    return File(Uri.parse(uri).toFilePath()).exists();
  }

  @override
  Future<void> delete(String uri) async {
    final file = File(Uri.parse(uri).toFilePath());
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _persistPickedImage(XFile image) async {
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
      return File(compressed.path).uri.toString();
    }

    final fallback = await File(image.path).copy(targetPath);
    return fallback.uri.toString();
  }

  Future<Directory> _receiptDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, 'receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
