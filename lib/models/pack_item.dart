/// Join record linking a Pack ([GearItem] where [GearItem.isPack] == true)
/// to the gear items packed inside it.
class PackItem {
  final String id;
  final String packId;
  final String gearItemId;
  final int quantityInPack;
  final bool isChecked;
  final int sortOrder;

  const PackItem({
    required this.id,
    required this.packId,
    required this.gearItemId,
    this.quantityInPack = 1,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  PackItem copyWith({
    String? id,
    String? packId,
    String? gearItemId,
    int? quantityInPack,
    bool? isChecked,
    int? sortOrder,
  }) => PackItem(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    gearItemId: gearItemId ?? this.gearItemId,
    quantityInPack: quantityInPack ?? this.quantityInPack,
    isChecked: isChecked ?? this.isChecked,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'pack_id': packId,
    'gear_item_id': gearItemId,
    'quantity_in_pack': quantityInPack,
    'is_checked': isChecked ? 1 : 0,
    'sort_order': sortOrder,
  };

  factory PackItem.fromMap(Map<String, dynamic> map) => PackItem(
    id: map['id'] as String,
    packId: map['pack_id'] as String,
    gearItemId: map['gear_item_id'] as String,
    quantityInPack: map['quantity_in_pack'] as int? ?? 1,
    isChecked: (map['is_checked'] as int?) == 1,
    sortOrder: map['sort_order'] as int? ?? 0,
  );

  @override
  String toString() =>
      'PackItem(gearItemId: $gearItemId, qty: $quantityInPack)';
}
