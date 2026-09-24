import 'package:cookbook/features/recipe_catalog/models/recipe.dart';

class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.ingredient,
    this.checked = false,
  });

  factory ShoppingListItem.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('ShoppingListItem must be a JSON object.');
    }
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
        'ShoppingListItem.id must be a non-empty string.',
      );
    }
    final checked = json['checked'];
    if (checked is! bool) {
      throw const FormatException(
        'ShoppingListItem.checked must be a boolean.',
      );
    }

    return ShoppingListItem(
      id: id.trim(),
      ingredient: Ingredient.fromJson(json['ingredient']),
      checked: checked,
    );
  }

  final String id;
  final Ingredient ingredient;
  final bool checked;

  ShoppingListItem copyWith({Ingredient? ingredient, bool? checked}) =>
      ShoppingListItem(
        id: id,
        ingredient: ingredient ?? this.ingredient,
        checked: checked ?? this.checked,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'ingredient': ingredient.toJson(),
    'checked': checked,
  };
}
