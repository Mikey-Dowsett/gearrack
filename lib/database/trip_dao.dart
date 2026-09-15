import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../models/pack.dart';
import 'database_helper.dart';
import 'pack_item_dao.dart';

/// Result of joining trip_items with gear_items (when gear item still exists).
class TripItemWithDetails {
  final TripItem tripItem;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? brand;

  const TripItemWithDetails({
    required this.tripItem,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.brand,
  });
}

/// Aggregated category weight for a trip (mirrors [CategoryWeight]).
class TripCategoryWeight {
  final String? categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final double totalWeightGrams;

  const TripCategoryWeight({
    this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.totalWeightGrams,
  });
}

/// Usage statistics for a single gear item.
class GearUsageStats {
  final int timesUsed;
  final DateTime? lastUsedDate;

  const GearUsageStats({this.timesUsed = 0, this.lastUsedDate});
}

class TripDao {
  final Database db;

  TripDao(this.db);

  static Future<TripDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return TripDao(db);
  }

  // ---------------------------------------------------------------------------
  // Trip CRUD
  // ---------------------------------------------------------------------------

  Future<List<Trip>> getAll({String? orderBy}) async {
    final maps = await db.query('trips', orderBy: orderBy ?? 'start_date DESC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> getById(String id) async {
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<void> insert(Trip trip) async {
    await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Trip trip) async {
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> delete(String id) async {
    // trip_items cascade-delete via FK
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // Trip Items CRUD
  // ---------------------------------------------------------------------------

  Future<List<TripItem>> getItemsByTrip(String tripId) async {
    final maps = await db.query(
      'trip_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return maps.map((m) => TripItem.fromMap(m)).toList();
  }

  /// Returns trip items joined with gear_item and category details when
  /// the gear item still exists. Orphaned items (gear deleted) appear with
  /// null category fields.
  Future<List<TripItemWithDetails>> getItemsByTripWithDetails(
    String tripId,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT ti.*,
             gi.category_id AS gi_category_id,
             c.name AS c_name,
             c.icon AS c_icon,
             c.color AS c_color,
             gi.brand AS gi_brand
      FROM trip_items ti
      LEFT JOIN gear_items gi ON ti.gear_item_id = gi.id
      LEFT JOIN categories c ON gi.category_id = c.id
      WHERE ti.trip_id = ?
    ''',
      [tripId],
    );

    return result.map((row) {
      final tripItem = TripItem.fromMap(row);
      return TripItemWithDetails(
        tripItem: tripItem,
        categoryId: row['gi_category_id'] as String?,
        categoryName: row['c_name'] as String?,
        categoryIcon: row['c_icon'] as String?,
        categoryColor: row['c_color'] as String?,
        brand: row['gi_brand'] as String?,
      );
    }).toList();
  }

  /// Compute total weight of all items in a trip.
  Future<double> getTotalWeightByTrip(String tripId) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(ti.weight_grams * ti.quantity), 0) AS total
      FROM trip_items ti
      WHERE ti.trip_id = ?
    ''',
      [tripId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total number of distinct item entries in a trip.
  Future<int> getItemCountByTrip(String tripId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM trip_items WHERE trip_id = ?',
      [tripId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sum weight by category for a trip's items.
  Future<List<TripCategoryWeight>> getWeightByCategory(String tripId) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(gi.category_id, 'unknown') AS category_id,
             COALESCE(c.name, 'Other') AS category_name,
             COALESCE(c.icon, 'box') AS category_icon,
              COALESCE(c.color, '#80696B') AS category_color,
             SUM(ti.weight_grams * ti.quantity) AS total_weight
      FROM trip_items ti
      LEFT JOIN gear_items gi ON ti.gear_item_id = gi.id
      LEFT JOIN categories c ON gi.category_id = c.id
      WHERE ti.trip_id = ?
      GROUP BY category_id
      ORDER BY total_weight DESC
    ''',
      [tripId],
    );

    return result
        .map(
          (row) => TripCategoryWeight(
            categoryId: row['category_id'] as String,
            categoryName: row['category_name'] as String,
            icon: row['category_icon'] as String,
            color: row['category_color'] as String,
            totalWeightGrams: (row['total_weight'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> insertTripItem(TripItem item) async {
    await db.insert(
      'trip_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTripItem(String id) async {
    await db.delete('trip_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItemsByTrip(String tripId) async {
    await db.delete('trip_items', where: 'trip_id = ?', whereArgs: [tripId]);
  }

  // ---------------------------------------------------------------------------
  // Primary entry path: log a trip from a pack
  // ---------------------------------------------------------------------------

  /// Creates a trip and snapshots the given pack's current [pack_items]
  /// into [trip_items], capturing name + weight at this moment.
  ///
  /// Returns the newly created [Trip].
  Future<Trip> logTripFromPack({
    required Pack pack,
    required List<String> gearItemIdsToInclude,
    required DateTime startDate,
    DateTime? endDate,
    String? activityType,
    String? location,
    String? conditions,
    String? notes,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    // Load pack items with gear details to snapshot.
    final packItemDao = PackItemDao(db);
    final packItemsWithGear = await packItemDao.getByPackWithGear(pack.id);

    // Filter to only selected gear item ids (user can tick items off).
    final selectedItems = packItemsWithGear.where(
      (pi) => gearItemIdsToInclude.contains(pi.gearItem.id),
    );

    final trip = Trip(
      id: uuid.v4(),
      name: pack.name,
      packId: pack.id,
      activityType: activityType,
      startDate: startDate,
      endDate: endDate,
      location: location,
      conditions: conditions,
      notes: notes,
      createdAt: now,
    );

    await db.transaction((txn) async {
      // Insert the trip
      await txn.insert('trips', trip.toMap());

      // Snapshot each selected pack item into a trip_item
      for (final pwg in selectedItems) {
        final gear = pwg.gearItem;
        final packItem = pwg.packItem;
        final tripItem = TripItem(
          id: uuid.v4(),
          tripId: trip.id,
          gearItemId: gear.id,
          itemName: gear.name,
          weightGrams: gear.weightGrams,
          quantity: packItem.quantityInPack,
        );
        await txn.insert('trip_items', tripItem.toMap());
      }
    });

    return trip;
  }

  /// Create a from-scratch trip with manually specified items.
  Future<Trip> logTripFromScratch({
    required String name,
    required List<TripItem> items,
    String? packId,
    DateTime? startDate,
    DateTime? endDate,
    String? activityType,
    String? location,
    String? conditions,
    String? notes,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    final trip = Trip(
      id: uuid.v4(),
      name: name,
      packId: packId,
      activityType: activityType,
      startDate: startDate ?? now,
      endDate: endDate,
      location: location,
      conditions: conditions,
      notes: notes,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('trips', trip.toMap());
      for (final item in items) {
        await txn.insert(
          'trip_items',
          TripItem(
            id: item.id.isNotEmpty ? item.id : uuid.v4(),
            tripId: trip.id,
            gearItemId: item.gearItemId,
            itemName: item.itemName,
            weightGrams: item.weightGrams,
            quantity: item.quantity,
          ).toMap(),
        );
      }
    });

    return trip;
  }

  /// Update an existing trip, replacing its items with the given list.
  Future<void> updateTripWithItems({
    required Trip trip,
    required List<TripItem> items,
  }) async {
    await db.transaction((txn) async {
      await txn.update(
        'trips',
        trip.toMap(),
        where: 'id = ?',
        whereArgs: [trip.id],
      );
      // Delete existing items and re-insert
      await txn.delete(
        'trip_items',
        where: 'trip_id = ?',
        whereArgs: [trip.id],
      );
      for (final item in items) {
        await txn.insert(
          'trip_items',
          TripItem(
            id: item.id.isNotEmpty ? item.id : const Uuid().v4(),
            tripId: trip.id,
            gearItemId: item.gearItemId,
            itemName: item.itemName,
            weightGrams: item.weightGrams,
            quantity: item.quantity,
          ).toMap(),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Usage-stat queries (for gear item detail)
  // ---------------------------------------------------------------------------

  /// How many times a gear item has been taken on trips.
  Future<int> getTimesUsed(String gearItemId) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT ti.trip_id) AS count
      FROM trip_items ti
      WHERE ti.gear_item_id = ?
    ''',
      [gearItemId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// The most recent trip date for a gear item, or null if never used.
  Future<DateTime?> getLastUsedDate(String gearItemId) async {
    final result = await db.rawQuery(
      '''
      SELECT MAX(t.start_date) AS last_date
      FROM trip_items ti
      JOIN trips t ON ti.trip_id = t.id
      WHERE ti.gear_item_id = ?
    ''',
      [gearItemId],
    );
    final lastDate = result.first['last_date'] as String?;
    return lastDate != null ? DateTime.parse(lastDate) : null;
  }

  /// Convenience: aggregate usage stats for a gear item.
  Future<GearUsageStats> getUsageStats(String gearItemId) async {
    final timesUsed = await getTimesUsed(gearItemId);
    final lastUsed = await getLastUsedDate(gearItemId);
    return GearUsageStats(timesUsed: timesUsed, lastUsedDate: lastUsed);
  }

  /// Trips that include a specific gear item.
  Future<List<Trip>> getTripsForGearItem(String gearItemId) async {
    final result = await db.rawQuery(
      '''
      SELECT t.*
      FROM trips t
      JOIN trip_items ti ON t.id = ti.trip_id
      WHERE ti.gear_item_id = ?
      ORDER BY t.start_date DESC
    ''',
      [gearItemId],
    );
    return result.map((m) => Trip.fromMap(m)).toList();
  }

  /// Gear items owned but absent from any trip in the last [months] months.
  Future<List<String>> getUnusedGearItemIds({int months = 6}) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 30));
    final result = await db.rawQuery(
      '''
      SELECT gi.id
      FROM gear_items gi
      WHERE gi.id NOT IN (
        SELECT DISTINCT ti.gear_item_id
        FROM trip_items ti
        JOIN trips t ON ti.trip_id = t.id
        WHERE ti.gear_item_id IS NOT NULL
          AND t.start_date >= ?
      )
    ''',
      [cutoff.toIso8601String()],
    );
    return result.map((row) => row['id'] as String).toList();
  }
}
