import 'package:sqflite/sqflite.dart';
import '../models/gear_item.dart';
import 'database_helper.dart';

class GearItemDao {
  final Database db;

  GearItemDao(this.db);

  static Future<GearItemDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return GearItemDao(db);
  }

  Future<List<GearItem>> getAll({String? orderBy}) async {
    final maps = await db.query(
      'gear_items',
      orderBy: orderBy ?? 'updated_at DESC',
    );
    return maps.map((m) => GearItem.fromMap(m)).toList();
  }

  Future<List<GearItem>> getByCategory(String categoryId) async {
    final maps = await db.query(
      'gear_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map((m) => GearItem.fromMap(m)).toList();
  }

  Future<List<GearItem>> getPacks() async {
    final maps = await db.query(
      'gear_items',
      where: 'is_pack = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => GearItem.fromMap(m)).toList();
  }

  Future<GearItem?> getById(String id) async {
    final maps = await db.query('gear_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return GearItem.fromMap(maps.first);
  }

  Future<void> insert(GearItem item) async {
    await db.insert(
      'gear_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(GearItem item) async {
    await db.update(
      'gear_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('gear_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM gear_items',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
