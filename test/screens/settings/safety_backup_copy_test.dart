import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/screens/settings/backup_restore_dialog.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('wm_safety_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('copies a real safety backup', () async {
    final src = File(p.join(dir.path, 'src.json'))..writeAsStringSync('{"a":1}');
    final dest = File(p.join(dir.path, 'dest.json'))..writeAsStringSync('old');
    await copyVerifiedSafetyBackup(src, dest);
    expect(dest.readAsStringSync(), '{"a":1}');
  });

  test('stops the restore when the safety backup is missing', () async {
    final dest = File(p.join(dir.path, 'dest.json'));
    await expectLater(
      copyVerifiedSafetyBackup(File(p.join(dir.path, 'missing.json')), dest),
      throwsStateError,
    );
    expect(dest.existsSync(), isFalse,
        reason: 'no placeholder file may be written');
  });

  test('stops the restore when the safety backup is empty', () async {
    final src = File(p.join(dir.path, 'empty.json'))..writeAsStringSync('');
    await expectLater(
      copyVerifiedSafetyBackup(src, File(p.join(dir.path, 'dest.json'))),
      throwsStateError,
    );
  });
}
