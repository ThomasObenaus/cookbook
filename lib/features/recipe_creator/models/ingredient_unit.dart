enum IngredientUnit {
  milliliter(label: 'Milliliter', storedValue: 'ml'),
  liter(label: 'Liter', storedValue: 'l'),
  teaspoon(label: 'Teaspoon', storedValue: 'tsp'),
  tablespoon(label: 'Tablespoon', storedValue: 'tbsp'),
  cup(label: 'Cup', storedValue: 'cup'),
  gram(label: 'Gram', storedValue: 'g'),
  kilogram(label: 'Kilogram', storedValue: 'kg'),
  piece(label: 'Piece', storedValue: 'piece'),
  pinch(label: 'Pinch', storedValue: 'pinch'),
  handful(label: 'Handful', storedValue: 'handful'),
  clove(label: 'Clove', storedValue: 'clove'),
  slice(label: 'Slice', storedValue: 'slice'),
  can(label: 'Can', storedValue: 'can'),
  package(label: 'Package', storedValue: 'package');

  const IngredientUnit({required this.label, required this.storedValue});

  final String label;
  final String storedValue;
}
