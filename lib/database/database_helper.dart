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
      version: 4,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // --- Migration: v3 -> v4 (propagate seed-data icons & colors) ---
    if (oldVersion < 4) {
      await _migrateV3toV4(db);
    }

    // Previous development versions: destructive reset.
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS custom_list_items');
      await db.execute('DROP TABLE IF EXISTS custom_lists');
      await db.execute('DROP TABLE IF EXISTS pack_items');
      await db.execute('DROP TABLE IF EXISTS packs');
      await db.execute('DROP TABLE IF EXISTS gear_items');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS app_settings');
      await _onCreate(db, newVersion);
    }
  }

  /// Sync default category colors and icons with current seed data.
  Future<void> _migrateV3toV4(Database db) async {
    // Colors
    final colorUpdates = {
      'Shelter': '#7DAF85',
      'Sleep System': '#7AA8C8',
      'Clothing': '#D4A07A',
      'Footwear': '#B89878',
      'Navigation': '#A8BA8A',
      'Lighting': '#E0C080',
      'Cooking': '#D48A7A',
      'Food & Water': '#7AAD85',
      'First Aid': '#D48A8A',
      'Tools & Repair': '#A8A898',
      'Electronics': '#8AAAC8',
      'Packs & Bags': '#8ABA8A',
      'Climbing': '#B8A078',
      'Snow Sports': '#98BCC8',
      'Water Sports': '#78A8B8',
      'Hygiene': '#A0C8A0',
      'Safety': '#D4A878',
      'Miscellaneous': '#A0A0B0',
    };

    // Icons — kept here so any seed-data icon changes propagate on migrate
    final iconUpdates = {
      'Shelter': 'tent',
      'Sleep System': 'bed',
      'Clothing': 'shirt',
      'Footwear': 'shoe-prints',
      'Navigation': 'compass',
      'Lighting': 'lightbulb',
      'Cooking': 'fire',
      'Food & Water': 'utensils',
      'First Aid': 'first-aid',
      'Tools & Repair': 'wrench',
      'Electronics': 'plug',
      'Packs & Bags': 'person-hiking',
      'Climbing': 'mountain',
      'Snow Sports': 'snowflake',
      'Water Sports': 'water',
      'Hygiene': 'soap',
      'Safety': 'shield',
      'Miscellaneous': 'ellipsis',
    };

    final batch = db.batch();
    for (final entry in colorUpdates.entries) {
      batch.update(
        'categories',
        {'color': entry.value, 'icon': iconUpdates[entry.key], 'is_default': 1},
        where: 'name = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
