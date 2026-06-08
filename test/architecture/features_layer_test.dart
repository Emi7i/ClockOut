import 'package:test/test.dart';
import 'helpers.dart' as helpers;

void main() {
  group('Features / Presentation Layer', () {
    // -------------------- LAYER ISOLATION ----------------------
    test('features do not import from data layer', () {
      helpers.assertNoImports('lib/features', forbidden: ['data/']);
    });

    // -------------------- FEATURE ISOLATION ----------------------
    test('features do not import from other features', () {
      final featureDirs = helpers.getSubdirectories('lib/features');
      for (final feature in featureDirs) {
        final otherFeatures = featureDirs
            .where((f) => f != feature)
            .map((f) => 'features/${f.split('/').last}/')
            .toList();
        helpers.assertNoImports(feature, forbidden: otherFeatures);
      }
    });

    // -------------------- WIDGET ISOLATION ----------------------
    test('widgets do not import blocs from other features', () {
      final featureDirs = helpers.getSubdirectories('lib/features');
      for (final feature in featureDirs) {
        final widgetFiles = helpers.getDartFiles('$feature/widgets');
        for (final file in widgetFiles) {
          final content = file.readAsStringSync();
          final otherFeatureBlocs = featureDirs
              .where((f) => f != feature)
              .map((f) => 'features/${f.split('/').last}/bloc/');

          for (final forbiddenBloc in otherFeatureBlocs) {
            expect(
              content,
              isNot(contains(forbiddenBloc)),
              reason: '${file.path} imports bloc from another feature',
            );
          }
        }
      }
    });

    // -------------------- SCREEN ISOLATION ----------------------
    test('screens and widgets do not directly import repositories', () {
      final featureDirs = helpers.getSubdirectories('lib/features');
      for (final feature in featureDirs) {
        // Restricted folders: screens and widgets
        final restrictedFolders = ['screens', 'widgets'];
        
        for (final folder in restrictedFolders) {
          helpers.assertNoImports('$feature/$folder', forbidden: [
            'domain/repositories/',
            'data/repositories/',
          ]);
        }
      }
    });
  });
}
