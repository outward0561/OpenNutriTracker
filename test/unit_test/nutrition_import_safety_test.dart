import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';

void main() {
  test('pasted serving sizes reject fractional and per-item quantities', () {
    for (final size in [
      '1/2 g',
      '2 x 50 g',
      '2×50 g',
      '2 pieces (50 g each)',
      '1..2 g',
    ]) {
      final entry = NutritionImportParser.parseText(
        'Food\nPer serving\nServing size: $size\nCalories: 100 kcal',
      );
      expect(entry.servingSize, isNull, reason: size);
      expect(entry.issues, isNotEmpty, reason: size);
      expect(() => entry.toPer100(), throwsFormatException, reason: size);
    }
    final equivalent = NutritionImportParser.parseText(
      'Milk\nPer serving\nServing size: 1/2 cup (120 ml)\nCalories: 60 kcal',
    );
    expect(equivalent.servingSize, 120);
    expect(equivalent.toPer100()['kcal'], 50);
  });

  test('nonfinite quantities and nutrients cannot be converted', () {
    for (final size in [double.nan, double.infinity, double.negativeInfinity]) {
      final entry = NutritionEntry(
        basis: NutritionBasis.serving,
        servingSize: size,
        servingUnit: 'g',
        values: {'kcal': 100},
      );
      expect(() => entry.toPer100(), throwsFormatException);
    }
    for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
      final entry = NutritionEntry(
        basis: NutritionBasis.per100g,
        values: {'kcal': value},
      );
      expect(() => entry.toPer100(), throwsFormatException);
    }
  });
}
