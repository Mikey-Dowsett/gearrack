/// Singleton user preferences stored in the database.
///
/// Only one row exists (id = 1). Defaults are set on first creation
/// and can be updated via the settings UI.
class AppSettings {
  final int id;
  final String weightUnit;
  final bool showLbs;
  final String theme;
  final String accentColor;
  final String currency;
  final DateTime? lastExportAt;
  final bool proMode;

  AppSettings({
    this.id = 1,
    this.weightUnit = 'grams',
    this.showLbs = false,
    this.theme = 'light',
    this.accentColor = '#BE6B50',
    this.currency = 'USD',
    this.lastExportAt,
    this.proMode = false,
  });

  AppSettings copyWith({
    int? id,
    String? weightUnit,
    bool? showLbs,
    String? theme,
    String? accentColor,
    String? currency,
    DateTime? lastExportAt,
    bool? proMode,
  }) => AppSettings(
    id: id ?? this.id,
    weightUnit: weightUnit ?? this.weightUnit,
    showLbs: showLbs ?? this.showLbs,
    theme: theme ?? this.theme,
    accentColor: accentColor ?? this.accentColor,
    currency: currency ?? this.currency,
    lastExportAt: lastExportAt ?? this.lastExportAt,
    proMode: proMode ?? this.proMode,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'weight_unit': weightUnit,
    'show_lbs': showLbs ? 1 : 0,
    'theme': theme,
    'accent_color': accentColor,
    'currency': currency,
    'last_export_at': lastExportAt?.toIso8601String(),
    'pro_mode': proMode ? 1 : 0,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    id: map['id'] as int? ?? 1,
    weightUnit: map['weight_unit'] as String? ?? 'grams',
    showLbs: map['show_lbs'] == 1 ||
        map['show_lbs'] == true ||
        (map['show_lbs'] == null && map['weight_unit'] == 'pounds'),
    theme: map['theme'] as String? ?? 'light',
    accentColor: map['accent_color'] as String? ?? '#BE6B50',
    currency: map['currency'] as String? ?? 'USD',
    lastExportAt: map['last_export_at'] != null
        ? DateTime.parse(map['last_export_at'] as String)
        : null,
    proMode: map['pro_mode'] == 1,
  );

  @override
  String toString() => 'AppSettings(showLbs: $showLbs, theme: $theme)';
}
