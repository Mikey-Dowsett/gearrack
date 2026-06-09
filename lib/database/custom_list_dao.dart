import 'package:sqflite/sqflite.dart';
import '../models/custom_list.dart';
import 'database_helper.dart';

class CustomListDao {
  final Database db;

  CustomListDao(this.db);

  static Future<CustomListDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return CustomListDao(db);
  }

  Future<List<CustomList>> getAll() async {
    final maps = await db.query('custom_lists', orderBy: 'created_at DESC');
    return maps.map((m) => CustomList.fromMap(m)).toList();
  }

  Future<List<CustomList>> getByPack(String packId) async {
    final maps = await db.query(
      'custom_lists',
      where: 'linked_pack_id = ?',
      whereArgs: [packId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => CustomList.fromMap(m)).toList();
  }

  Future<CustomList?> getById(String id) async {
    final maps = await db.query(
      'custom_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CustomList.fromMap(maps.first);
  }

  Future<void> insert(CustomList list) async {
    await db.insert(
      'custom_lists',
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(CustomList list) async {
    await db.update(
      'custom_lists',
      list.toMap(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('custom_lists', where: 'id = ?', whereArgs: [id]);
  }
}
