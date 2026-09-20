import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter/material.dart';

class IngredientFormControllers {
  IngredientFormControllers(this.id)
    : name = TextEditingController(),
      quantity = TextEditingController(),
      unit = TextEditingController(),
      note = TextEditingController(),
      nameFocusNode = FocusNode();

  final int id;
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController note;
  final FocusNode nameFocusNode;

  bool get isBlank =>
      name.text.trim().isEmpty &&
      quantity.text.trim().isEmpty &&
      unit.text.trim().isEmpty &&
      note.text.trim().isEmpty;

  IngredientDraft toDraft() => IngredientDraft(
    name: name.text,
    quantity: quantity.text,
    unit: unit.text,
    note: note.text,
  );

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    note.dispose();
    nameFocusNode.dispose();
  }
}

class IngredientFormRow extends StatelessWidget {
  const IngredientFormRow({
    required this.index,
    required this.controllers,
    required this.enabled,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final IngredientFormControllers controllers;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Ingredient ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: ValueKey<String>('remove-ingredient-${controllers.id}'),
                onPressed: enabled && canRemove ? onRemove : null,
                tooltip: 'Remove ingredient',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          TextFormField(
            key: ValueKey<String>('ingredient-name-${controllers.id}'),
            controller: controllers.name,
            focusNode: controllers.nameFocusNode,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Ingredient name'),
            validator: (_) {
              if (!controllers.isBlank &&
                  controllers.name.text.trim().isEmpty) {
                return 'Enter an ingredient name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>(
                    'ingredient-quantity-${controllers.id}',
                  ),
                  controller: controllers.quantity,
                  enabled: enabled,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('ingredient-unit-${controllers.id}'),
                  controller: controllers.unit,
                  enabled: enabled,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('ingredient-note-${controllers.id}'),
            controller: controllers.note,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
    );
  }
}
