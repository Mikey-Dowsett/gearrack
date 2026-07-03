/// Snapshot record of a gear item taken on a trip.
///
/// Unlike [PackItem] which references [GearItem] live, a [TripItem]
/// stores denormalized copies of name and weight so trip history
/// survives gear library edits or deletions.
class TripItem {
  final String id;
  final String tripId;
  final String?
  gearItemId; // nullable — survives gear deletion (ON DELETE SET NULL)
  final String itemName; // denormalized name captured at log time
  final double weightGrams; // denormalized weight captured at log time
  final int quantity;

  const TripItem({
    required this.id,
    required this.tripId,
    this.gearItemId,
    required this.itemName,
    required this.weightGrams,
    this.quantity = 1,
  });

  TripItem copyWith({
    String? id,
    String? tripId,
    String? gearItemId,
    String? itemName,
    double? weightGrams,
    int? quantity,
  }) => TripItem(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    gearItemId: gearItemId ?? this.gearItemId,
    itemName: itemName ?? this.itemName,
    weightGrams: weightGrams ?? this.weightGrams,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'gear_item_id': gearItemId,
    'item_name': itemName,
    'weight_grams': weightGrams,
    'quantity': quantity,
  };

  factory TripItem.fromMap(Map<String, dynamic> map) => TripItem(
    id: map['id'] as String,
    tripId: map['trip_id'] as String,
    gearItemId: map['gear_item_id'] as String?,
    itemName: map['item_name'] as String,
    weightGrams: (map['weight_grams'] as num).toDouble(),
    quantity: map['quantity'] as int? ?? 1,
  );

  @override
  String toString() => 'TripItem(itemName: $itemName, qty: $quantity)';
}
