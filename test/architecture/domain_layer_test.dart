import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Domain Layer', () {
    // -------------------- ENTITIES ----------------------
    test('entities do not import from data layer', () {
      helpers.assertNoImports('lib/domain/entities', forbidden: ['data/']);
    });

    test('entities do not import from features layer', () {
      helpers.assertNoImports('lib/domain/entities', forbidden: ['features/']);
    });

    // -------------------- USE CASES ----------------------
    test('use cases do not import from data layer', () {
      helpers.assertNoImports('lib/domain/use_cases', forbidden: ['data/']);
    });

    test('use cases do not import from features layer', () {
      helpers.assertNoImports('lib/domain/use_cases', forbidden: ['features/']);
    });

    // -------------------- REPOSITORIES ----------------------
    test('repository interfaces do not import from data layer', () {
      helpers.assertNoImports('lib/domain/repositories', forbidden: ['data/']);
    });

    test('repository interfaces do not import from features layer', () {
      helpers.assertNoImports('lib/domain/repositories', forbidden: ['features/']);
    });

    // -------------------- DEPENDENCIES ----------------------
    test('domain does not depend on Flutter UI packages', () {
      helpers.assertNoImports('lib/domain', forbidden: [
        'package:flutter/',
        'package:flutter_bloc/',
      ]);
    });
  });
}
