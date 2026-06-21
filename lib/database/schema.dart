import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';

/// All DDL statements and seeder functions for the GearRack database.
class Schema {
  Schema._();

  static const String version = '1';

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------
  static const String createCategoriesTable = '''
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // ---------------------------------------------------------------------------
  // Gear Items
  // ---------------------------------------------------------------------------
  static const String createGearItemsTable = '''
    CREATE TABLE IF NOT EXISTS gear_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      brand TEXT,
      category_id TEXT NOT NULL REFERENCES categories(id),
      is_pack INTEGER NOT NULL DEFAULT 0,
      capacity_liters REAL,
      weight_grams REAL NOT NULL,
      price REAL,
      purchase_year INTEGER,
      quantity INTEGER NOT NULL DEFAULT 1,
      condition TEXT NOT NULL DEFAULT 'Good' CHECK(condition IN ('Good','Worn','Retired')),
      notes TEXT,
      image_url TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  // ---------------------------------------------------------------------------
  // Packs (trip / outing configurations)
  // ---------------------------------------------------------------------------
  static const String createPacksTable = '''
    CREATE TABLE IF NOT EXISTS packs (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      bag_id TEXT REFERENCES gear_items(id),
      created_at TEXT NOT NULL
    )
  ''';

  // ---------------------------------------------------------------------------
  // Pack Items (gear items packed inside a Pack)
  // ---------------------------------------------------------------------------
  static const String createPackItemsTable = '''
    CREATE TABLE IF NOT EXISTS pack_items (
      id TEXT PRIMARY KEY,
      pack_id TEXT NOT NULL REFERENCES packs(id),
      gear_item_id TEXT NOT NULL REFERENCES gear_items(id),
      quantity_in_pack INTEGER NOT NULL DEFAULT 1,
      is_checked INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // ---------------------------------------------------------------------------
  // Custom Lists
  // ---------------------------------------------------------------------------
  static const String createCustomListsTable = '''
    CREATE TABLE IF NOT EXISTS custom_lists (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      linked_pack_id TEXT REFERENCES packs(id),
      created_at TEXT NOT NULL
    )
  ''';

  // ---------------------------------------------------------------------------
  // Custom List Items
  // ---------------------------------------------------------------------------
  static const String createCustomListItemsTable = '''
    CREATE TABLE IF NOT EXISTS custom_list_items (
      id TEXT PRIMARY KEY,
      list_id TEXT NOT NULL REFERENCES custom_lists(id),
      type TEXT NOT NULL CHECK(type IN ('gear','custom')),
      gear_item_id TEXT REFERENCES gear_items(id),
      label TEXT,
      weight_grams REAL,
      quantity INTEGER NOT NULL DEFAULT 1,
      is_checked INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // ---------------------------------------------------------------------------
  // App Settings
  // ---------------------------------------------------------------------------
  static const String createAppSettingsTable = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      id INTEGER PRIMARY KEY DEFAULT 1,
      weight_unit TEXT NOT NULL DEFAULT 'grams',
      theme TEXT NOT NULL DEFAULT 'light',
      accent_color TEXT NOT NULL DEFAULT '#385A41',
      currency TEXT NOT NULL DEFAULT 'USD',
      last_export_at TEXT
    )
  ''';

  // ---------------------------------------------------------------------------
  // Indices
  // ---------------------------------------------------------------------------
  static const String createPacksIdx = '''
    CREATE INDEX IF NOT EXISTS idx_packs_created ON packs(created_at DESC)
  ''';

  static const String createGearItemsCategoryIdx = '''
    CREATE INDEX IF NOT EXISTS idx_gear_items_category ON gear_items(category_id)
  ''';

  static const String createPackItemsPackIdx = '''
    CREATE INDEX IF NOT EXISTS idx_pack_items_pack ON pack_items(pack_id)
  ''';

  static const String createPackItemsGearIdx = '''
    CREATE INDEX IF NOT EXISTS idx_pack_items_gear ON pack_items(gear_item_id)
  ''';

  static const String createCustomListItemsListIdx = '''
    CREATE INDEX IF NOT EXISTS idx_custom_list_items_list ON custom_list_items(list_id)
  ''';

  /// Run all DDL statements to create the schema.
  static Future<void> createAll(Database db) async {
    await db.execute(createCategoriesTable);
    await db.execute(createGearItemsTable);
    await db.execute(createPacksTable);
    await db.execute(createPackItemsTable);
    await db.execute(createCustomListsTable);
    await db.execute(createCustomListItemsTable);
    await db.execute(createAppSettingsTable);

    // Indices
    await db.execute(createPacksIdx);
    await db.execute(createGearItemsCategoryIdx);
    await db.execute(createPackItemsPackIdx);
    await db.execute(createPackItemsGearIdx);
    await db.execute(createCustomListItemsListIdx);
  }

  // ---------------------------------------------------------------------------
  // Seeders
  // ---------------------------------------------------------------------------

  /// Insert the 18 default categories.
  static Future<void> seedDefaultCategories(Database db) async {
    final uuid = Uuid();

    final defaultCategories = [
      Category(id: uuid.v4(), name: 'Shelter', icon: 'tent', color: '#385A41'),
      Category(
        id: uuid.v4(),
        name: 'Sleep System',
        icon: 'bed',
        color: '#2E5077',
      ),
      Category(
        id: uuid.v4(),
        name: 'Clothing',
        icon: 'shirt',
        color: '#AE6739',
      ),
      Category(
        id: uuid.v4(),
        name: 'Footwear',
        icon: 'shoe-prints',
        color: '#5C4A3E',
      ),
      Category(
        id: uuid.v4(),
        name: 'Navigation',
        icon: 'compass',
        color: '#4A7C59',
      ),
      Category(
        id: uuid.v4(),
        name: 'Lighting',
        icon: 'lightbulb',
        color: '#CA933E',
      ),
      Category(id: uuid.v4(), name: 'Cooking', icon: 'fire', color: '#B84A3F'),
      Category(
        id: uuid.v4(),
        name: 'Food & Water',
        icon: 'utensils',
        color: '#3A714B',
      ),
      Category(
        id: uuid.v4(),
        name: 'First Aid',
        icon: 'first-aid',
        color: '#B83A3A',
      ),
      Category(
        id: uuid.v4(),
        name: 'Tools & Repair',
        icon: 'wrench',
        color: '#6B6B6B',
      ),
      Category(
        id: uuid.v4(),
        name: 'Electronics',
        icon: 'plug',
        color: '#3A5A8C',
      ),
      Category(
        id: uuid.v4(),
        name: 'Packs & Bags',
        icon: 'person-hiking',
        color: '#4A6B4A',
      ),
      Category(
        id: uuid.v4(),
        name: 'Climbing',
        icon: 'mountain',
        color: '#8B6040',
      ),
      Category(
        id: uuid.v4(),
        name: 'Snow Sports',
        icon: 'snowflake',
        color: '#4A7B9C',
      ),
      Category(
        id: uuid.v4(),
        name: 'Water Sports',
        icon: 'water',
        color: '#2A6B8C',
      ),
      Category(id: uuid.v4(), name: 'Hygiene', icon: 'soap', color: '#7A9C7A'),
      Category(id: uuid.v4(), name: 'Safety', icon: 'shield', color: '#C84A3F'),
      Category(
        id: uuid.v4(),
        name: 'Miscellaneous',
        icon: 'ellipsis',
        color: '#6B7A8C',
      ),
    ];

    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert('categories', cat.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Insert the default app settings row.
  static Future<void> seedDefaultSettings(Database db) async {
    await db.insert('app_settings', {
      'id': 1,
      'weight_unit': 'grams',
      'theme': 'light',
      'accent_color': '#385A41',
      'currency': 'USD',
      'last_export_at': null,
    });
  }
}
