/// Data class representing a gear category loaded from the database.
///
/// Categories are user-configurable. [isDefault] indicates a built-in
/// category that cannot be deleted but can still be renamed/recustomized.
class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'is_default': isDefault ? 1 : 0,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    icon: map['icon'] as String,
    color: map['color'] as String,
    isDefault: map['is_default'] == 1,
  );

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, icon: $icon, color: $color, isDefault: $isDefault)';
}
