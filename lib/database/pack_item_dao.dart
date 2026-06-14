import 'package:sqflite/sqflite.dart';
import '../models/pack_item.dart';
import '../models/gear_item.dart';
import 'database_helper.dart';

/// Result of joining pack_items with gear_items.
class PackItemWithGear {
  final PackItem packItem;
  final GearItem gearItem;

  const PackItemWithGear({required this.packItem, required this.gearItem});
}

/// Result of summing weight by category within a pack.
class CategoryWeight {
  final String categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final double totalWeightGrams;

  const CategoryWeight({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.totalWeightGrams,
  });
}

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

  /// Returns all pack items with their joined gear item details.
  Future<List<PackItemWithGear>> getByPackWithGear(String packId) async {
    final result = await db.rawQuery(
      '''
      SELECT pi.*, gi.id AS gi_id, gi.name AS gi_name, gi.brand AS gi_brand,
             gi.category_id AS gi_category_id, gi.is_pack AS gi_is_pack,
             gi.capacity_liters AS gi_capacity_liters,
             gi.weight_grams AS gi_weight_grams, gi.price AS gi_price,
             gi.purchase_year AS gi_purchase_year, gi.quantity AS gi_quantity,
             gi.condition AS gi_condition, gi.notes AS gi_notes,
             gi.image_url AS gi_image_url, gi.created_at AS gi_created_at,
             gi.updated_at AS gi_updated_at
      FROM pack_items pi
      JOIN gear_items gi ON pi.gear_item_id = gi.id
      WHERE pi.pack_id = ?
      ORDER BY pi.sort_order ASC
    ''',
      [packId],
    );

    return result.map((row) {
      final packItem = PackItem.fromMap(row);
      final gearItem = GearItem.fromMap({
        'id': row['gi_id'],
        'name': row['gi_name'],
        'brand': row['gi_brand'],
        'category_id': row['gi_category_id'],
        'is_pack': row['gi_is_pack'],
        'capacity_liters': row['gi_capacity_liters'],
        'weight_grams': row['gi_weight_grams'],
        'price': row['gi_price'],
        'purchase_year': row['gi_purchase_year'],
        'quantity': row['gi_quantity'],
        'condition': row['gi_condition'],
        'notes': row['gi_notes'],
        'image_url': row['gi_image_url'],
        'created_at': row['gi_created_at'],
        'updated_at': row['gi_updated_at'],
      });
      return PackItemWithGear(packItem: packItem, gearItem: gearItem);
    }).toList();
  }

  /// Compute the total weight (grams) of all gear items in a pack.
  Future<double> getTotalWeightByPack(String packId) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(gi.weight_grams * pi.quantity_in_pack), 0) AS total
      FROM pack_items pi
      JOIN gear_items gi ON pi.gear_item_id = gi.id
      WHERE pi.pack_id = ?
    ''',
      [packId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total number of distinct item entries in a pack.
  Future<int> getItemCountByPack(String packId) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count FROM pack_items WHERE pack_id = ?
    ''',
      [packId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sum weight by category for the progress bar breakdown.
  Future<List<CategoryWeight>> getWeightByCategory(String packId) async {
    final result = await db.rawQuery(
      '''
      SELECT gi.category_id,
             c.name AS category_name,
             c.icon AS category_icon,
             c.color AS category_color,
             SUM(gi.weight_grams * pi.quantity_in_pack) AS total_weight
      FROM pack_items pi
      JOIN gear_items gi ON pi.gear_item_id = gi.id
      JOIN categories c ON gi.category_id = c.id
      WHERE pi.pack_id = ?
      GROUP BY gi.category_id
      ORDER BY total_weight DESC
    ''',
      [packId],
    );

    return result
        .map(
          (row) => CategoryWeight(
            categoryId: row['category_id'] as String,
            categoryName: row['category_name'] as String,
            icon: row['category_icon'] as String,
            color: row['category_color'] as String,
            totalWeightGrams: (row['total_weight'] as num).toDouble(),
          ),
        )
        .toList();
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
