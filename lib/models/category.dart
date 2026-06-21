/// Data class representing a gear category loaded from the database.
///
/// Replaces the old [Category] enum — categories are now user-configurable.
class Category {
  final String id;
  final String name;
  final String icon;
  final String color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    icon: map['icon'] as String,
    color: map['color'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, icon: $icon, color: $color)';
}
