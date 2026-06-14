/// Data class representing a Pack (trip/outing configuration).
///
/// A Pack is a collection of gear items organized for a specific trip.
/// It optionally references a Bag ([GearItem] where [GearItem.isPack] == true).
class Pack {
  final String id;
  final String name;
  final String? description;
  final String? bagId; // references a GearItem where isPack == true
  final DateTime createdAt;

  const Pack({
    required this.id,
    required this.name,
    this.description,
    this.bagId,
    required this.createdAt,
  });

  Pack copyWith({
    String? id,
    String? name,
    String? description,
    String? bagId,
    DateTime? createdAt,
  }) => Pack(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    bagId: bagId ?? this.bagId,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'bag_id': bagId,
    'created_at': createdAt.toIso8601String(),
  };

  factory Pack.fromMap(Map<String, dynamic> map) => Pack(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    bagId: map['bag_id'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  String toString() => 'Pack(id: $id, name: $name)';
}
