import 'category.dart';
import 'condition.dart';

class Gear {
  final String name;
  final String brand;
  final Category category;
  final bool isPack;
  final int capacity;
  final double weight;
  final double price;
  final int purchaseYear;
  final int quantity;
  final Condition condition;
  final String notes;
  // icon can be a Material IconData or a FontAwesome FaIconData
  final Object icon;

  const Gear(
    this.name,
    this.brand,
    this.category,
    this.isPack,
    this.capacity,
    this.weight,
    this.price,
    this.purchaseYear,
    this.quantity,
    this.condition,
    this.notes,
    this.icon,
  );
}
