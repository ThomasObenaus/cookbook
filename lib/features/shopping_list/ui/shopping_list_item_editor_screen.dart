import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';
import 'package:flutter/material.dart';

typedef SaveShoppingListIngredient = Future<bool> Function(
  Ingredient ingredient,
);

class ShoppingListItemEditorScreen extends StatefulWidget {
  const ShoppingListItemEditorScreen({
    required this.item,
    required this.onSave,
    super.key,
  });

  final ShoppingListItem item;
  final SaveShoppingListIngredient onSave;

  @override
  State<ShoppingListItemEditorScreen> createState() =>
      _ShoppingListItemEditorScreenState();
}

class _ShoppingListItemEditorScreenState
    extends State<ShoppingListItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _note;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.item.ingredient;
    _name = TextEditingController(text: ingredient.name);
    _quantity = TextEditingController(text: ingredient.quantity);
    _unit = TextEditingController(text: ingredient.unit);
    _note = TextEditingController(text: ingredient.note);
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final ingredient = Ingredient(
      name: _name.text.trim(),
      quantity: _optionalValue(_quantity),
      unit: _optionalValue(_unit),
      note: _optionalValue(_note),
    );
    var saved = false;
    try {
      saved = await widget.onSave(ingredient);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit shopping item')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                TextFormField(
                  key: const ValueKey<String>('shopping-edit-name'),
                  controller: _name,
                  enabled: !_saving,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an ingredient name.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('shopping-edit-quantity'),
                  controller: _quantity,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('shopping-edit-unit'),
                  controller: _unit,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('shopping-edit-note'),
                  controller: _note,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                if (_failed)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'The shopping item could not be saved. Please try again.',
                      key: ValueKey<String>('shopping-edit-error'),
                    ),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    TextButton(
                      key: const ValueKey<String>('shopping-edit-cancel'),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey<String>('shopping-edit-save'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
