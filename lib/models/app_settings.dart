/// Singleton user preferences stored in the database.
///
/// Only one row exists (id = 1). Defaults are set on first creation
/// and can be updated via the settings UI.
class AppSettings {
  final int id;
  final String weightUnit;
  final String theme;
  final String accentColor;
  final String currency;
  final DateTime? lastExportAt;

  const AppSettings({
    this.id = 1,
    this.weightUnit = 'grams',
    this.theme = 'light',
    this.accentColor = '#385A41',
    this.currency = 'USD',
    this.lastExportAt,
  });

  AppSettings copyWith({
    int? id,
    String? weightUnit,
    String? theme,
    String? accentColor,
    String? currency,
    DateTime? lastExportAt,
  }) => AppSettings(
    id: id ?? this.id,
    weightUnit: weightUnit ?? this.weightUnit,
    theme: theme ?? this.theme,
    accentColor: accentColor ?? this.accentColor,
    currency: currency ?? this.currency,
    lastExportAt: lastExportAt ?? this.lastExportAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'weight_unit': weightUnit,
    'theme': theme,
    'accent_color': accentColor,
    'currency': currency,
    'last_export_at': lastExportAt?.toIso8601String(),
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    id: map['id'] as int? ?? 1,
    weightUnit: map['weight_unit'] as String? ?? 'grams',
    theme: map['theme'] as String? ?? 'light',
    accentColor: map['accent_color'] as String? ?? '#385A41',
    currency: map['currency'] as String? ?? 'USD',
    lastExportAt: map['last_export_at'] != null
        ? DateTime.parse(map['last_export_at'] as String)
        : null,
  );

  @override
  String toString() => 'AppSettings(weightUnit: $weightUnit, theme: $theme)';
}
