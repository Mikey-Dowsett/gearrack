import 'condition.dart';

/// Data class representing a single gear item stored in the database.
///
/// Weight is always stored in grams. Display formatting (kg, oz, etc.)
/// is handled by the UI layer based on user preferences.
class GearItem {
  final String id;
  final String name;
  final String? brand;
  final String categoryId;
  final bool isPack;
  final double? capacityLiters;
  final double weightGrams;
  final double? price;
  final int? purchaseYear;
  final int quantity;
  final String condition;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GearItem({
    required this.id,
    required this.name,
    this.brand,
    required this.categoryId,
    this.isPack = false,
    this.capacityLiters,
    required this.weightGrams,
    this.price,
    this.purchaseYear,
    this.quantity = 1,
    this.condition = 'Good',
    this.notes,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Resolve the [Condition] enum from the stored string.
  Condition get conditionEnum => Condition.values.firstWhere(
    (c) => c.name == condition,
    orElse: () => Condition.Good,
  );

  /// Create a copy with optional field overrides.
  GearItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? categoryId,
    bool? isPack,
    double? capacityLiters,
    double? weightGrams,
    double? price,
    int? purchaseYear,
    int? quantity,
    String? condition,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GearItem(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    categoryId: categoryId ?? this.categoryId,
    isPack: isPack ?? this.isPack,
    capacityLiters: capacityLiters ?? this.capacityLiters,
    weightGrams: weightGrams ?? this.weightGrams,
    price: price ?? this.price,
    purchaseYear: purchaseYear ?? this.purchaseYear,
    quantity: quantity ?? this.quantity,
    condition: condition ?? this.condition,
    notes: notes ?? this.notes,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category_id': categoryId,
    'is_pack': isPack ? 1 : 0,
    'capacity_liters': capacityLiters,
    'weight_grams': weightGrams,
    'price': price,
    'purchase_year': purchaseYear,
    'quantity': quantity,
    'condition': condition,
    'notes': notes,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GearItem.fromMap(Map<String, dynamic> map) => GearItem(
    id: map['id'] as String,
    name: map['name'] as String,
    brand: map['brand'] as String?,
    categoryId: map['category_id'] as String,
    isPack: (map['is_pack'] as int) == 1,
    capacityLiters: (map['capacity_liters'] as num?)?.toDouble(),
    weightGrams: (map['weight_grams'] as num).toDouble(),
    price: (map['price'] as num?)?.toDouble(),
    purchaseYear: map['purchase_year'] as int?,
    quantity: map['quantity'] as int? ?? 1,
    condition: map['condition'] as String? ?? 'Good',
    notes: map['notes'] as String?,
    imageUrl: map['image_url'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  String toString() => 'GearItem(id: $id, name: $name)';
}
