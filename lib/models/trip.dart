/// Data class representing a logged trip / outing.
///
/// A Trip records a real-world outing where a pack was taken.
/// Items taken are stored as a snapshot in [trip_items] so that
/// the historical record remains accurate even if gear or packs
/// change later.
class Trip {
  final String id;
  final String name;
  final String?
  packId; // soft link to originating pack (nullable, ON DELETE SET NULL)
  final String? activityType;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? conditions;
  final String? notes;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.name,
    this.packId,
    this.activityType,
    required this.startDate,
    this.endDate,
    this.location,
    this.conditions,
    this.notes,
    required this.createdAt,
  });

  Trip copyWith({
    String? id,
    String? name,
    String? packId,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? conditions,
    String? notes,
    DateTime? createdAt,
  }) => Trip(
    id: id ?? this.id,
    name: name ?? this.name,
    packId: packId ?? this.packId,
    activityType: activityType ?? this.activityType,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    location: location ?? this.location,
    conditions: conditions ?? this.conditions,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'pack_id': packId,
    'activity_type': activityType,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'location': location,
    'conditions': conditions,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
    id: map['id'] as String,
    name: map['name'] as String,
    packId: map['pack_id'] as String?,
    activityType: map['activity_type'] as String?,
    startDate: DateTime.parse(map['start_date'] as String),
    endDate: map['end_date'] != null
        ? DateTime.parse(map['end_date'] as String)
        : null,
    location: map['location'] as String?,
    conditions: map['conditions'] as String?,
    notes: map['notes'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  String toString() => 'Trip(id: $id, name: $name)';
}
