import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';

void main() {
  test('a nutrient cell must contain exactly one value and optional unit', () {
    expect(NutritionImportParser.parseNutrientCell('protein', ' 12,5 g '),
        ('protein', 12.5));
    expect(NutritionImportParser.parseNutrientCell('kcal', '1,200 kcal'),
        ('kcal', 1200));
    expect(NutritionImportParser.parseNutrientCell('sodium', '0.5g'),
        ('sodium', 500));

    for (final text in [
      '100 / 200 kcal',
      '1/2 g',
      '12 g / 100 g',
      '1.2.3 g',
      '12g3',
      '<1 g',
      '1 g or 2 g',
    ]) {
      expect(NutritionImportParser.parseNutrientCell('protein', text), isNull,
          reason: text);
    }
  });

  test('CSV reports ambiguous nutrient cells while retaining valid rows', () {
    final result = NutritionImportParser.parseCsv(
      'Name,Energy per 100 g,Protein per 100 g\n'
      'Good,250 kcal,12 g\n'
      'Ambiguous energy,100 / 200 kcal,10 g\n'
      'Fractional protein,250 kcal,1/2 g\n',
    );

    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Good');
    expect(result.entries.single.values['kcal'], 250);
    expect(result.entries.single.values['protein'], 12);
    expect(result.errors.join(' '), contains('invalid kcal'));
    expect(result.errors.join(' '), contains('invalid protein'));
  });

  test('JSON reports ambiguous nutrient cells while retaining valid entries', () {
    final result = NutritionImportParser.parseJson('''
      {"foods": [
        {"name": "Good", "calories_per_100g": 250, "protein_per_100g": 12},
        {"name": "Ambiguous energy", "calories_per_100g": "100 / 200 kcal"},
        {"name": "Fractional protein", "protein_per_100g": "1/2 g"}
      ]}
    ''');

    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Good');
    expect(result.entries.single.values['kcal'], 250);
    expect(result.entries.single.values['protein'], 12);
    expect(result.errors.join(' '), contains('invalid kcal'));
    expect(result.errors.join(' '), contains('invalid protein'));
  });
}
