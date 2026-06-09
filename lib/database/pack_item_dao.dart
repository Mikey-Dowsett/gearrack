import 'package:sqflite/sqflite.dart';
import '../models/pack_item.dart';
import 'database_helper.dart';

class PackItemDao {
  final Database db;

  PackItemDao(this.db);

  static Future<PackItemDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return PackItemDao(db);
  }

  Future<List<PackItem>> getByPack(String packId) async {
    final maps = await db.query(
      'pack_items',
      where: 'pack_id = ?',
      whereArgs: [packId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => PackItem.fromMap(m)).toList();
  }

  Future<PackItem?> getById(String id) async {
    final maps = await db.query('pack_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return PackItem.fromMap(maps.first);
  }

  Future<void> insert(PackItem item) async {
    await db.insert(
      'pack_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(PackItem item) async {
    await db.update(
      'pack_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('pack_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByPack(String packId) async {
    await db.delete('pack_items', where: 'pack_id = ?', whereArgs: [packId]);
  }
}
