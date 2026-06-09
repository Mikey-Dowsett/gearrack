import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final Database db;

  CategoryDao(this.db);

  static Future<CategoryDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return CategoryDao(db);
  }

  Future<List<Category>> getAll() async {
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getDefaults() async {
    final maps = await db.query(
      'categories',
      where: 'is_default = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getById(String id) async {
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<void> insert(Category category) async {
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Category category) async {
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM categories',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
