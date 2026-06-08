import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Circular Dependencies', () {
    test('no file imports itself', () {
      final allFiles = helpers.getDartFiles('lib');
      for (final file in allFiles) {
        final content = file.readAsStringSync();
        final fileName = file.uri.pathSegments.last.replaceAll('.dart', '');
        // A file importing its own generated part is fine, skip those
        if (content.contains("part '")) continue;
        expect(
          content,
          isNot(contains("import '$fileName.dart'")),
          reason: '${file.path} imports itself',
        );
      }
    });
  });
}
