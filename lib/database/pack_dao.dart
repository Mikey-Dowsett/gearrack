import 'package:sqflite/sqflite.dart';
import '../models/pack.dart';
import 'database_helper.dart';

class PackDao {
  final Database db;

  PackDao(this.db);

  static Future<PackDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return PackDao(db);
  }

  Future<List<Pack>> getAll() async {
    final maps = await db.query('packs', orderBy: 'created_at DESC');
    return maps.map((m) => Pack.fromMap(m)).toList();
  }

  Future<Pack?> getById(String id) async {
    final maps = await db.query('packs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Pack.fromMap(maps.first);
  }

  Future<void> insert(Pack pack) async {
    await db.insert(
      'packs',
      pack.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Pack pack) async {
    await db.update(
      'packs',
      pack.toMap(),
      where: 'id = ?',
      whereArgs: [pack.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('packs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM packs');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
