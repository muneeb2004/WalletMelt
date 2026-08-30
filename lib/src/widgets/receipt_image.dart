import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cross-platform widget to display receipt images safely on both Native (Android, iOS, Desktop)
/// and Flutter Web platforms.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage({
    required this.receiptUri,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.errorBuilder,
    super.key,
  });

  final String? receiptUri;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final uriStr = receiptUri;
    if (uriStr == null || uriStr.isEmpty) {
      return _buildFallback(context);
    }

    if (kIsWeb) {
      if (uriStr.startsWith('data:image')) {
        try {
          final base64Content = uriStr.split(',').last;
          final bytes = base64Decode(base64Content);
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: errorBuilder ?? (c, e, s) => _buildFallback(c),
          );
        } catch (_) {
          return _buildFallback(context);
        }
      }
      return Image.network(
        uriStr,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildFallback(c),
      );
    }

    // Native platform (Android, iOS, Desktop)
    if (uriStr.startsWith('http://') || uriStr.startsWith('https://')) {
      return Image.network(
        uriStr,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildFallback(c),
      );
    }

    if (uriStr.startsWith('data:image')) {
      try {
        final base64Content = uriStr.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? (c, e, s) => _buildFallback(c),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    }

    try {
      final filePath = uriStr.startsWith('file://')
          ? Uri.parse(uriStr).toFilePath()
          : uriStr;
      final file = io.File(filePath);
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildFallback(c),
      );
    } catch (_) {
      return _buildFallback(context);
    }
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(
        Icons.receipt_long_rounded,
        color: Colors.white38,
        size: 32,
      ),
    );
  }
}
