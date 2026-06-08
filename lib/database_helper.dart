import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef TableCreator = Future<void> Function(Database db);
typedef DataSeeder = Future<void> Function(Database db);

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  // This is where the magic happens. You can pass custom creation and seeding logic here.
  Future<void> _onCreate(Database db, int version) async {
    // In a real app, you might want to load these from a registry or configuration.
    // For now, I'll leave this empty and show you how to use the setup method below.
  }

  /// Call this method during app initialization to run your custom setup.
  /// This is the "easy way" you asked for.
  Future<void> setupDatabase({
    required List<TableCreator> tableCreators,
    required List<DataSeeder> seeders,
  }) async {
    final db = await instance.database;

    // 1. Run all table creators
    for (var creator in tableCreators) {
      await creator(db);
    }

    // 2. Run all seeders
    for (var seeder in seeders) {
      await seeder(db);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
