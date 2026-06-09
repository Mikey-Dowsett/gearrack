/// A user-created packing list (e.g. "Food — 3 Day Trip").
///
/// Can optionally be linked to a specific Pack ([GearItem] with [GearItem.isPack] == true).
class CustomList {
  final String id;
  final String name;
  final String? linkedPackId;
  final DateTime createdAt;

  const CustomList({
    required this.id,
    required this.name,
    this.linkedPackId,
    required this.createdAt,
  });

  CustomList copyWith({
    String? id,
    String? name,
    String? linkedPackId,
    DateTime? createdAt,
  }) => CustomList(
    id: id ?? this.id,
    name: name ?? this.name,
    linkedPackId: linkedPackId ?? this.linkedPackId,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'linked_pack_id': linkedPackId,
    'created_at': createdAt.toIso8601String(),
  };

  factory CustomList.fromMap(Map<String, dynamic> map) => CustomList(
    id: map['id'] as String,
    name: map['name'] as String,
    linkedPackId: map['linked_pack_id'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  String toString() => 'CustomList(id: $id, name: $name)';
}
