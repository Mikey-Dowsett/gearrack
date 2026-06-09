/// An item within a [CustomList].
///
/// Can reference an existing [GearItem] (type = 'gear') or be a free-form
/// custom entry (type = 'custom') with its own label and weight.
class CustomListItem {
  final String id;
  final String listId;
  final String type; // 'gear' or 'custom'
  final String? gearItemId;
  final String? label;
  final double? weightGrams;
  final int quantity;
  final bool isChecked;
  final int sortOrder;

  const CustomListItem({
    required this.id,
    required this.listId,
    required this.type,
    this.gearItemId,
    this.label,
    this.weightGrams,
    this.quantity = 1,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  CustomListItem copyWith({
    String? id,
    String? listId,
    String? type,
    String? gearItemId,
    String? label,
    double? weightGrams,
    int? quantity,
    bool? isChecked,
    int? sortOrder,
  }) => CustomListItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    type: type ?? this.type,
    gearItemId: gearItemId ?? this.gearItemId,
    label: label ?? this.label,
    weightGrams: weightGrams ?? this.weightGrams,
    quantity: quantity ?? this.quantity,
    isChecked: isChecked ?? this.isChecked,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'list_id': listId,
    'type': type,
    'gear_item_id': gearItemId,
    'label': label,
    'weight_grams': weightGrams,
    'quantity': quantity,
    'is_checked': isChecked ? 1 : 0,
    'sort_order': sortOrder,
  };

  factory CustomListItem.fromMap(Map<String, dynamic> map) => CustomListItem(
    id: map['id'] as String,
    listId: map['list_id'] as String,
    type: map['type'] as String,
    gearItemId: map['gear_item_id'] as String?,
    label: map['label'] as String?,
    weightGrams: (map['weight_grams'] as num?)?.toDouble(),
    quantity: map['quantity'] as int? ?? 1,
    isChecked: (map['is_checked'] as int?) == 1,
    sortOrder: map['sort_order'] as int? ?? 0,
  );

  @override
  String toString() => 'CustomListItem(type: $type, label: $label)';
}
