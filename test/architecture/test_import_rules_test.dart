import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Test Import Rules', () {
    test('unit tests do not import from data/datasources', () {
      // Unit tests should not directly import datasources
      // Datasources are implementation details that should be tested at integration level
      helpers.assertNoImports('test/unit', forbidden: ['package:nanasave/data/datasources/']);
    });
  });
}
