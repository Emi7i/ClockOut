import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Data Layer', () {
    // -------------------- LAYER ISOLATION ----------------------
    test('data layer does not import from features layer', () {
      helpers.assertNoImports('lib/data', forbidden: ['features/']);
    });

    // -------------------- REPOSITORIES ----------------------
    test('repositories impl only implement domain repository interfaces', () {
      final repoFiles = helpers.getDartFiles('lib/data/repositories');
      for (final file in repoFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          contains('implements'),
          reason: '${file.path} should implement a domain repository interface',
        );
      }
    });

    // -------------------- DTOS ----------------------
    test('data layer does not import from core/error without reason', () {
      // datasources and repos can use errors, but DTOs should not
      helpers.assertNoImports('lib/data/dtos', forbidden: ['core/error/']);
    });

    // -------------------- DATASOURCES ----------------------
    test('remote datasources do not import local datasources', () {
      helpers.assertNoImports('lib/data/datasources/remote',
          forbidden: ['datasources/local/']);
    });

    test('local datasources do not import remote datasources', () {
      helpers.assertNoImports('lib/data/datasources/local',
          forbidden: ['datasources/remote/']);
    });
  });
}
