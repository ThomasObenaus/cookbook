import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter/material.dart';

class IngredientEditorControllers {
  IngredientEditorControllers()
    : name = TextEditingController(),
      quantity = TextEditingController(),
      note = TextEditingController(),
      nameFocusNode = FocusNode();

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController note;
  final FocusNode nameFocusNode;
  IngredientUnit? unit;

  bool get isBlank =>
      name.text.trim().isEmpty &&
      quantity.text.trim().isEmpty &&
      unit == null &&
      note.text.trim().isEmpty;

  IngredientDraft toDraft() => IngredientDraft(
    name: name.text.trim(),
    quantity: quantity.text.trim(),
    unit: unit,
    note: note.text.trim(),
  );

  void load(IngredientDraft ingredient) {
    name.text = ingredient.name;
    quantity.text = ingredient.quantity;
    unit = ingredient.unit;
    note.text = ingredient.note;
  }

  void clear() {
    name.clear();
    quantity.clear();
    unit = null;
    note.clear();
  }

  void dispose() {
    name.dispose();
    quantity.dispose();
    note.dispose();
    nameFocusNode.dispose();
  }
}

class IngredientWizardStep extends StatelessWidget {
  const IngredientWizardStep({
    required this.ingredients,
    required this.controllers,
    required this.editorVisible,
    required this.editingIndex,
    required this.nameError,
    required this.enabled,
    required this.onChanged,
    required this.onSave,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final List<IngredientDraft> ingredients;
  final IngredientEditorControllers controllers;
  final bool editorVisible;
  final int? editingIndex;
  final String? nameError;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final visibleSummaryIndexes = <int>[
      for (var index = 0; index < ingredients.length; index++)
        if (!editorVisible || editingIndex != index) index,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (editorVisible) ...<Widget>[
          Text(
            'Ingredient ${(editingIndex ?? ingredients.length) + 1}',
            key: const ValueKey<String>('active-ingredient-label'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey<String>('ingredient-name-field'),
            controller: controllers.name,
            focusNode: controllers.nameFocusNode,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Ingredient name',
              errorText: nameError,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey<String>('ingredient-quantity-field'),
            controller: controllers.quantity,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<IngredientUnit>(
            key: const ValueKey<String>('ingredient-unit-field'),
            initialValue: controllers.unit,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unit'),
            hint: const Text('No unit'),
            items: <DropdownMenuItem<IngredientUnit>>[
              const DropdownMenuItem<IngredientUnit>(child: Text('No unit')),
              for (final unit in IngredientUnit.values)
                DropdownMenuItem<IngredientUnit>(
                  value: unit,
                  child: Text(unit.label),
                ),
            ],
            onChanged: enabled
                ? (unit) {
                    controllers.unit = unit;
                    onChanged();
                  }
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey<String>('ingredient-note-field'),
            controller: controllers.note,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey<String>('save-ingredient'),
              onPressed: enabled ? onSave : null,
              icon: const Icon(Icons.check),
              label: const Text('Save ingredient'),
            ),
          ),
        ],
        if (editorVisible && visibleSummaryIndexes.isNotEmpty)
          const SizedBox(height: 24),
        for (final index in visibleSummaryIndexes) ...<Widget>[
          _IngredientSummary(
            index: index,
            ingredient: ingredients[index],
            enabled: enabled && !editorVisible,
            onEdit: () => onEdit(index),
            onRemove: () => onRemove(index),
          ),
          if (index != visibleSummaryIndexes.last) const Divider(height: 24),
        ],
        if (!editorVisible) ...<Widget>[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('add-ingredient'),
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add),
              label: const Text('Add another ingredient'),
            ),
          ),
        ],
      ],
    );
  }
}

class _IngredientSummary extends StatelessWidget {
  const _IngredientSummary({
    required this.index,
    required this.ingredient,
    required this.enabled,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final IngredientDraft ingredient;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final amount = <String>[
      if (ingredient.quantity.isNotEmpty) ingredient.quantity,
      if (ingredient.unit != null) ingredient.unit!.storedValue,
    ].join(' ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ingredient ${index + 1}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                <String>[
                  if (amount.isNotEmpty) amount,
                  ingredient.name,
                ].join(' '),
                key: ValueKey<String>('ingredient-summary-$index'),
              ),
              if (ingredient.note.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  ingredient.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          key: ValueKey<String>('edit-ingredient-$index'),
          onPressed: enabled ? onEdit : null,
          tooltip: 'Edit ingredient ${index + 1}',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          key: ValueKey<String>('remove-ingredient-$index'),
          onPressed: enabled ? onRemove : null,
          tooltip: 'Remove ingredient ${index + 1}',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
