import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gearrance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all tables and seeds default data on first launch.
  Future<void> _onCreate(Database db, int version) async {
    await Schema.createAll(db);
    await Schema.seedDefaultCategories(db);
    await Schema.seedDefaultSettings(db);
  }

  /// Destructive migration: drop all tables and recreate.
  /// Safe during development — no production data exists.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS custom_list_items');
    await db.execute('DROP TABLE IF EXISTS custom_lists');
    await db.execute('DROP TABLE IF EXISTS pack_items');
    await db.execute('DROP TABLE IF EXISTS packs');
    await db.execute('DROP TABLE IF EXISTS gear_items');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS app_settings');
    await _onCreate(db, newVersion);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
