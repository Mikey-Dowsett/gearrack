class WeightParts {
  final String value;
  final String unit;
  const WeightParts(this.value, this.unit);
}

const double _gramsPerPound = 453.592;

/// Format weight given in grams, respecting the user's [weightUnit] preference.
///
/// When [weightUnit] is `'grams'` (default):
///   - < 1000g → "850 g"
///   - ≥ 1000g → "1.2 kg" or "2 kg"
///
/// When [weightUnit] is `'pounds'`:
///   - Always shows pounds with 1 decimal → "1.5 lb"
String formatWeight(double grams, {String weightUnit = 'grams'}) {
  final p = formatWeightParts(grams, weightUnit: weightUnit);
  return '${p.value} ${p.unit}';
}

WeightParts formatWeightParts(double grams, {String weightUnit = 'grams'}) {
  if (weightUnit == 'pounds') {
    final lbs = grams / _gramsPerPound;
    return WeightParts(lbs.toStringAsFixed(1), 'lb');
  }

  // Default: grams / kilograms
  if (grams >= 1000) {
    final kg = grams / 1000.0;
    final rounded = kg.roundToDouble();
    final isInteger = (kg - rounded).abs() < 0.001;
    final value = isInteger ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    return WeightParts(value, 'kg');
  } else {
    return WeightParts(grams.toStringAsFixed(0), 'g');
  }
}
