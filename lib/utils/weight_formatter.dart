class WeightParts {
  final String value;
  final String unit;
  const WeightParts(this.value, this.unit);
}

/// Format weight given in grams. If < 1000g, show grams as an integer ("850 g").
/// If >= 1000g, show kilograms with 1 decimal when needed ("1.2 kg" or "2 kg").
String formatWeight(double grams) {
  final p = formatWeightParts(grams);
  return '${p.value} ${p.unit}';
}

WeightParts formatWeightParts(double grams) {
  if (grams >= 1000) {
    final kg = grams / 1000.0;
    // If kg is effectively an integer, don't show decimals.
    final rounded = kg.roundToDouble();
    final isInteger = (kg - rounded).abs() < 0.001;
    final value = isInteger ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    return WeightParts(value, 'kg');
  } else {
    return WeightParts(grams.toStringAsFixed(0), 'g');
  }
}
