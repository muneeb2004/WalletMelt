import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class SvgValidationResult {
  const SvgValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.sanitizedContent,
  });

  const SvgValidationResult.success(String sanitizedContent)
      : this._(isValid: true, sanitizedContent: sanitizedContent);

  const SvgValidationResult.failure(String errorMessage)
      : this._(isValid: false, errorMessage: errorMessage);

  final bool isValid;
  final String? errorMessage;
  final String? sanitizedContent;
}

class SvgSafeguardService {
  const SvgSafeguardService();

  static const int maxSvgSizeBytes = 64 * 1024; // 64 KB limit

  static const Set<String> _disallowedTags = {
    'script',
    'foreignobject',
    'iframe',
    'object',
    'embed',
    'applet',
    'meta',
    'link',
    'style', // prevent CSS expression / injection
  };

  /// Validates and sanitizes raw SVG string content.
  SvgValidationResult validate(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return const SvgValidationResult.failure('SVG content is empty.');
    }

    if (rawContent.length > maxSvgSizeBytes) {
      return const SvgValidationResult.failure(
        'SVG file exceeds maximum allowed size (64 KB).',
      );
    }

    // 1. Check for XML External Entity (XXE) / DOCTYPE injection
    final upper = rawContent.toUpperCase();
    if (upper.contains('<!DOCTYPE') ||
        upper.contains('<!ENTITY') ||
        upper.contains('SYSTEM') && upper.contains('PUBLIC')) {
      return const SvgValidationResult.failure(
        'SVG contains disallowed DOCTYPE or entity declarations (security safeguard).',
      );
    }

    // 2. Check for script execution keywords before parsing
    if (rawContent.toLowerCase().contains('<script') ||
        rawContent.toLowerCase().contains('javascript:') ||
        rawContent.toLowerCase().contains('data:text/html')) {
      return const SvgValidationResult.failure(
        'SVG contains executable script code or script URLs.',
      );
    }

    // 3. Parse XML DOM
    XmlDocument document;
    try {
      document = XmlDocument.parse(rawContent);
    } catch (e) {
      return SvgValidationResult.failure('Malformed XML/SVG format: $e');
    }

    final rootElement = document.rootElement;
    if (rootElement.name.local.toLowerCase() != 'svg') {
      return const SvgValidationResult.failure(
        'Invalid SVG: Root element must be <svg>.',
      );
    }

    // 4. Inspect and sanitize DOM elements and attributes recursively
    final elementsToRemove = <XmlElement>[];

    for (final node in document.descendants) {
      if (node is XmlElement) {
        final tagName = node.name.local.toLowerCase();

        if (_disallowedTags.contains(tagName)) {
          elementsToRemove.add(node);
          continue;
        }

        // Check attributes for event handlers and dangerous URI schemes
        final attrsToRemove = <XmlAttribute>[];
        for (final attr in node.attributes) {
          final attrName = attr.name.local.toLowerCase();
          final attrVal = attr.value.toLowerCase().trim();

          // Reject inline event handlers (e.g. onload, onclick, onerror)
          if (attrName.startsWith('on')) {
            attrsToRemove.add(attr);
            continue;
          }

          // Check dangerous URL schemes or external remote links
          if (attrVal.startsWith('javascript:') ||
              attrVal.startsWith('data:text/html') ||
              attrVal.startsWith('http://') ||
              attrVal.startsWith('https://') ||
              attrVal.startsWith('//')) {
            attrsToRemove.add(attr);
          }
        }

        for (final attr in attrsToRemove) {
          node.attributes.remove(attr);
        }
      }
    }

    for (final elem in elementsToRemove) {
      elem.parent?.children.remove(elem);
    }

    // Ensure svg has viewBox or width/height
    final hasViewBox = rootElement.getAttribute('viewBox') != null;
    final hasWidth = rootElement.getAttribute('width') != null;
    final hasHeight = rootElement.getAttribute('height') != null;
    if (!hasViewBox && (!hasWidth || !hasHeight)) {
      rootElement.setAttribute('viewBox', '0 0 24 24');
    }

    return SvgValidationResult.success(document.toXmlString());
  }

  /// Saves a validated SVG file to the local documents custom_icons folder.
  /// Returns the relative identifier: `custom:<filename.svg>`.
  Future<String> saveCustomSvg({
    required String sanitizedSvg,
    required Directory baseDir,
  }) async {
    final iconsDir = Directory(p.join(baseDir.path, 'custom_icons'));
    if (!await iconsDir.exists()) {
      await iconsDir.create(recursive: true);
    }

    final filename = '${const Uuid().v4()}.svg';
    final file = File(p.join(iconsDir.path, filename));
    await file.writeAsString(sanitizedSvg, flush: true);

    return 'custom:$filename';
  }

  /// Resolves the file for a `custom:<filename>` icon identifier.
  File? resolveCustomFile(String iconId, Directory baseDir) {
    if (!iconId.startsWith('custom:')) return null;
    final filename = iconId.substring('custom:'.length);
    // Sanitize path against directory traversal
    final safeName = p.basename(filename);
    return File(p.join(baseDir.path, 'custom_icons', safeName));
  }
}
