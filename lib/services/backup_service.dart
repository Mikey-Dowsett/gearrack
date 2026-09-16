import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Tables included in a backup, ordered for export. Import runs in
/// reverse-dependency order (children first on delete, parents first
/// on insert) inside a single transaction.
const _backupTables = [
  'categories',
  'gear_items',
  'packs',
  'pack_items',
  'custom_lists',
  'custom_list_items',
  'trips',
  'trip_items',
  'app_settings',
];

/// Exports all user data to a versioned JSON map and restores it.
class BackupService {
  BackupService._();

  /// Read every backup table into `{table: [rows]}` with metadata.
  static Future<Map<String, dynamic>> exportAll() async {
    final db = await DatabaseHelper.instance.database;
    final data = <String, dynamic>{};
    for (final table in _backupTables) {
      data[table] = await db.query(table);
    }
    return {
      'format': 'gearrack-backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': data,
    };
  }

  static String encode(Map<String, dynamic> backup) => jsonEncode(backup);

  static Map<String, dynamic> decode(String json) {
    final parsed = jsonDecode(json);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Backup is not a JSON object');
    }
    if (parsed['format'] != 'gearrack-backup' || parsed['tables'] is! Map) {
      throw const FormatException('Not a GearRack backup file');
    }
    return parsed;
  }

  /// Replace all backup-table contents with [backup] rows atomically.
  /// Throws [FormatException] when the payload is invalid.
  static Future<void> importAll(Map<String, dynamic> backup) async {
    final tables = (backup['tables'] as Map).cast<String, dynamic>();
    for (final table in _backupTables) {
      final rows = tables[table];
      if (rows != null && rows is! List) {
        throw FormatException('Invalid rows for table $table');
      }
    }

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Delete children before parents to satisfy FK constraints.
      for (final table in _backupTables.reversed) {
        await txn.delete(table);
      }
      for (final table in _backupTables) {
        final rows = tables[table] as List? ?? [];
        for (final row in rows) {
          final map = (row as Map).cast<String, dynamic>();
          // Skip the singleton settings' last_export_at so an import
          // doesn't clobber the fresh import timestamp set by the caller.
          if (table == 'app_settings') {
            map.remove('last_export_at');
          }
          await txn.insert(table, Map<String, dynamic>.from(map));
        }
      }
      // Ensure exactly one settings row exists even if the backup
      // predates settings or shipped an empty table.
      final settings = await txn.query('app_settings', where: 'id = ?', whereArgs: [1]);
      if (settings.isEmpty) {
        await txn.insert('app_settings', {'id': 1});
      }
      await txn.update('app_settings', {
        'last_export_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [1]);
    });
  }

  /// Stamp the singleton settings row after a successful export.
  static Future<void> stampExport() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'app_settings',
      {'last_export_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
