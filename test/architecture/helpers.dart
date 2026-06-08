import 'dart:io';
import 'package:test/test.dart';

void assertNoImports(String directory, {required List<String> forbidden}) {
  final files = getDartFiles(directory);
  for (final file in files) {
    final content = file.readAsStringSync();
    for (final pattern in forbidden) {
      expect(
        content,
        isNot(contains(pattern)),
        reason: '${file.path} contains forbidden import: $pattern',
      );
    }
  }
}

List<File> getDartFiles(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart')) // skip generated files
      .where((f) => !f.path.endsWith('.g.dart')) // skip generated files
      .toList();
}

List<String> getSubdirectories(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.replaceAll('\\', '/'))
      .toList();
}
