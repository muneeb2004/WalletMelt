import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_service.dart';
import 'package:wallet_melt/src/services/svg/svg_customization_service.dart';
import 'package:wallet_melt/src/types/settings.dart';

const _svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor"/></svg>';
const _evil = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<script>alert(1)</script></svg>';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory phoneA;
  late Directory phoneB;
  final service = SvgCustomizationService.instance;

  setUp(() async {
    phoneA = await Directory.systemTemp.createTemp('wm_icons_a_');
    phoneB = await Directory.systemTemp.createTemp('wm_icons_b_');
  });

  tearDown(() async {
    service.resetForTesting();
    for (final d in [phoneA, phoneB]) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  test('backup ZIP carries uploads and edits; restore puts them on a new phone',
      () async {
    // Phone A: one uploaded icon plus an edit to a built-in icon.
    service.setBaseDirForTesting(phoneA.path);
    final uploadId = await service.createCustomIcon(_svg);
    await service.saveOverride(rawId: 'electricity', svgContent: _svg);
    final files = await service.exportableFiles();
    final uploadName = uploadId.substring('custom:'.length);
    expect(files.keys, contains('icons/uploads/$uploadName'));
    expect(files.keys, contains('icons/overrides/electricity.svg'));

    const backupService = WalletMeltJsonBackupService();
    final result = await backupService.createBackup(
      expenses: const [],
      groceryItems: const [],
      categories: const [],
      budgets: const [],
      settings: WalletMeltSettings.defaults,
      directory: phoneA,
      iconFiles: files,
    );
    final zipBytes = await File(result.path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final names = archive.map((e) => e.name).toList();
    expect(names, containsAll(['backup.json', 'metadata.json']));
    expect(names, contains('icons/uploads/$uploadName'));
    final meta = jsonDecode(utf8.decode(
        archive.firstWhere((e) => e.name == 'metadata.json').content
            as List<int>)) as Map;
    expect(meta['icon_file_count'], 2);

    // Extract like the restore dialog does.
    final extract = Directory(p.join(phoneB.path, 'extract'))..createSync();
    for (final e in archive) {
      if (!e.isFile) continue;
      final f = File(p.join(extract.path, e.name))..createSync(recursive: true);
      f.writeAsBytesSync(e.content as List<int>);
    }

    // Phone B: fresh install.
    service.resetForTesting();
    service.setBaseDirForTesting(phoneB.path);
    expect(await service.importFiles(extract, replace: false), 2);
    expect(File(p.join(phoneB.path, 'custom_icons', uploadName)).existsSync(),
        isTrue);
    expect(service.getOverrideSync('electricity'), isNotNull);
    expect((await service.listCustomIcons()).map((i) => i.id),
        contains(uploadId));
  });

  test('older backups without icons restore fine', () async {
    service.setBaseDirForTesting(phoneA.path);
    final extract = Directory(p.join(phoneA.path, 'extract'))..createSync();
    expect(await service.importFiles(extract, replace: true), 0);
  });

  test('safe merge keeps local files; full replace uses the backup copy',
      () async {
    service.setBaseDirForTesting(phoneA.path);
    final extract = Directory(p.join(phoneB.path, 'x', 'icons', 'overrides'))
      ..createSync(recursive: true);
    File(p.join(extract.path, 'gas.svg')).writeAsStringSync(_svg);
    final root = Directory(p.join(phoneB.path, 'x'));

    await service.saveOverride(
        rawId: 'gas',
        svgContent: _svg.replaceAll('r="9"', 'r="5"'));
    expect(await service.importFiles(root, replace: false), 0);
    expect(service.getOverrideSync('gas'), contains('r="5"'));

    expect(await service.importFiles(root, replace: true), 1);
    expect(service.getOverrideSync('gas'), contains('r="9"'));
  });

  test('unsafe names and malicious SVGs in a backup are ignored', () async {
    service.setBaseDirForTesting(phoneA.path);
    final up = Directory(p.join(phoneB.path, 'x', 'icons', 'uploads'))
      ..createSync(recursive: true);
    File(p.join(up.path, 'bad name.svg')).writeAsStringSync(_svg);
    File(p.join(up.path, 'script.svg')).writeAsStringSync(_evil);
    File(p.join(up.path, 'notes.txt')).writeAsStringSync('hi');
    final root = Directory(p.join(phoneB.path, 'x'));

    expect(await service.importFiles(root, replace: true), 0);
    expect(await service.listCustomIcons(), isEmpty);
  });
}
