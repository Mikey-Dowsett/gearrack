import 'package:sqflite/sqflite.dart';
import '../models/custom_list_item.dart';
import 'database_helper.dart';

class CustomListItemDao {
  final Database db;

  CustomListItemDao(this.db);

  static Future<CustomListItemDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return CustomListItemDao(db);
  }

  Future<List<CustomListItem>> getByList(String listId) async {
    final maps = await db.query(
      'custom_list_items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => CustomListItem.fromMap(m)).toList();
  }

  Future<CustomListItem?> getById(String id) async {
    final maps = await db.query(
      'custom_list_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CustomListItem.fromMap(maps.first);
  }

  Future<void> insert(CustomListItem item) async {
    await db.insert(
      'custom_list_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(CustomListItem item) async {
    await db.update(
      'custom_list_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('custom_list_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByList(String listId) async {
    await db.delete(
      'custom_list_items',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }
}
