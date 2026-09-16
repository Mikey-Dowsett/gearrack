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
      version: 10,
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
    // --- Migration: v9 -> v10 (orange is UI-only; move categories off it) ---
    if (oldVersion < 10) {
      await _migrateV9toV10(db);
    }

    // --- Migration: v8 -> v9 (remake light mode from warm analog palette) ---
    if (oldVersion < 9) {
      await _migrateV8toV9(db);
    }

    // --- Migration: v7 -> v8 (add show_lbs to app_settings) ---
    if (oldVersion < 8) {
      await _migrateV7toV8(db);
    }

    // --- Migration: v6 -> v7 (mark 5 permanent categories as default) ---
    if (oldVersion < 7) {
      await _migrateV6toV7(db);
    }

    // --- Migration: v5 -> v6 (add pro_mode to app_settings) ---
    if (oldVersion < 6) {
      await _migrateV5toV6(db);
    }

    // --- Migration: v4 -> v5 (add trip logging) ---
    if (oldVersion < 5) {
      await _migrateV4toV5(db);
    }

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

  /// Orange (#BE6B50) is UI-only; move any categories off it.
  Future<void> _migrateV9toV10(Database db) async {
    final batch = db.batch();
    batch.update(
      'categories',
      {'color': '#80696B'},
      where: 'name = ?',
      whereArgs: ['Clothing'],
    );
    batch.update(
      'categories',
      {'color': '#954F4D'},
      where: 'name = ?',
      whereArgs: ['Cooking'],
    );
    // Guard: any other category (custom or legacy) still on orange moves
    // to brick red so no category uses the UI accent.
    batch.update(
      'categories',
      {'color': '#954F4D'},
      where: "color = '#BE6B50'",
    );
    await batch.commit(noResult: true);
  }

  /// Sync default category colors and icons with current seed data.
  Future<void> _migrateV8toV9(Database db) async {
    const colorUpdates = {
      'Shelter': '#3D515B',
      'Sleep System': '#719193',
      'Clothing': '#80696B',
      'Footwear': '#954F4D',
      'Navigation': '#8F853C',
      'Lighting': '#D0A654',
      'Cooking': '#954F4D',
      'Food & Water': '#8F853C',
      'First Aid': '#954F4D',
      'Tools & Repair': '#5D523C',
      'Electronics': '#3D515B',
      'Packs & Bags': '#5D523C',
      'Climbing': '#D0A654',
      'Snow Sports': '#719193',
      'Water Sports': '#3D515B',
      'Hygiene': '#9DB3AC',
      'Safety': '#EFB571',
      'Miscellaneous': '#80696B',
    };
    final batch = db.batch();
    for (final entry in colorUpdates.entries) {
      batch.update(
        'categories',
        {'color': entry.value},
        where: 'name = ?',
        whereArgs: [entry.key],
      );
    }
    batch.update(
      'app_settings',
      {'accent_color': '#BE6B50'},
      where: "accent_color IN ('#385A41', '#3D515B')",
    );
    await batch.commit(noResult: true);
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
      'Packs & Bags': 'backpack',
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

  /// Create the trips and trip_items tables for v5.
  Future<void> _migrateV4toV5(Database db) async {
    await db.execute(Schema.createTripsTable);
    await db.execute(Schema.createTripItemsTable);
    await db.execute(Schema.createTripItemsTripIdx);
    await db.execute(Schema.createTripItemsGearIdx);
    await db.execute(Schema.createTripsStartDateIdx);
  }

  /// Add pro_mode column for v6.
  Future<void> _migrateV5toV6(Database db) async {
    await db.execute('''
      ALTER TABLE app_settings ADD COLUMN pro_mode INTEGER NOT NULL DEFAULT 0
    ''');
  }

  /// Add show_lbs column for v8 (replaces weight_unit g/lb toggle).
  /// Users who previously used pounds get show_lbs enabled.
  Future<void> _migrateV7toV8(Database db) async {
    await db.execute('''
      ALTER TABLE app_settings ADD COLUMN show_lbs INTEGER NOT NULL DEFAULT 0
    ''');
    await db.execute('''
      UPDATE app_settings SET show_lbs = 1 WHERE weight_unit = 'pounds'
    ''');
  }

  /// Mark only the 5 permanent categories as default; clear others.
  Future<void> _migrateV6toV7(Database db) async {
    // First set all categories to non-default
    await db.update('categories', {'is_default': 0});

    // Then mark the 5 permanent ones
    const protectedNames = [
      'Shelter',
      'Sleep System',
      'Clothing',
      'Food & Water',
      'First Aid',
    ];
    final batch = db.batch();
    for (final name in protectedNames) {
      batch.update(
        'categories',
        {'is_default': 1},
        where: 'name = ?',
        whereArgs: [name],
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
