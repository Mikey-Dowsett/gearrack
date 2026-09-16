class WeightParts {
  final String value;
  final String unit;
  const WeightParts(this.value, this.unit);
}

const double gramsPerPound = 453.592;

/// Format weight given in grams. Always displays grams:
///   - < 1000g → "850 g"
///   - ≥ 1000g → "1.2 kg" or "2 kg"
///
/// The legacy [weightUnit] parameter is ignored and kept only for
/// backward compatibility with existing call sites.
String formatWeight(double grams, {String weightUnit = 'grams'}) {
  final p = formatWeightParts(grams);
  return '${p.value} ${p.unit}';
}

WeightParts formatWeightParts(double grams, {String weightUnit = 'grams'}) {
  // Always grams / kilograms regardless of legacy preference.
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

/// Format grams as pounds → "1.5 lb".
String formatLbs(double grams) {
  final lbs = grams / gramsPerPound;
  return '${lbs.toStringAsFixed(1)} lb';
}

/// Format a total weight in grams, optionally appending the lbs
/// equivalent when [showLbs] is true → "850 g (1.9 lb)".
String formatTotalWeight(double grams, {bool showLbs = false}) {
  final base = formatWeight(grams);
  if (!showLbs) return base;
  return '$base (${formatLbs(grams)})';
}
