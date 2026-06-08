import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Core Layer', () {
    // -------------------- LAYER ISOLATION ----------------------
    test('core does not import from data layer', () {
      helpers.assertNoImports('lib/core', forbidden: ['data/']);
    });

    test('core does not import from features layer', () {
      helpers.assertNoImports('lib/core', forbidden: ['features/']);
    });

    test('core does not import from domain layer', () {
      helpers.assertNoImports('lib/core', forbidden: [
        'domain/entities/',
        'domain/repositories/',
        'domain/use_cases/',
        // enums allowed - domain/enums/ not forbidden
      ]);
    });
  });
}
