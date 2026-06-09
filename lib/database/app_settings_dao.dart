import 'package:sqflite/sqflite.dart';
import '../models/app_settings.dart';
import 'database_helper.dart';

class AppSettingsDao {
  final Database db;

  AppSettingsDao(this.db);

  static Future<AppSettingsDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return AppSettingsDao(db);
  }

  /// Get the singleton settings row (creates with defaults if it doesn't exist).
  Future<AppSettings> get() async {
    final maps = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isEmpty) {
      final defaults = AppSettings();
      await db.insert('app_settings', defaults.toMap());
      return defaults;
    }
    return AppSettings.fromMap(maps.first);
  }

  /// Update the singleton settings row.
  Future<void> update(AppSettings settings) async {
    await db.update(
      'app_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
