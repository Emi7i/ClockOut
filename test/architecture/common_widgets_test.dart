import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Common Widgets', () {
    // -------------------- LAYER ISOLATION ----------------------
    test('common_widgets do not import from features', () {
      helpers.assertNoImports('lib/common_widgets', forbidden: ['features/']);
    });

    test('common_widgets do not import from data layer', () {
      helpers.assertNoImports('lib/common_widgets', forbidden: ['data/']);
    });

    test('common_widgets do not import from domain layer', () {
      helpers.assertNoImports('lib/common_widgets', forbidden: ['domain/']);
    });
  });
}
