import 'package:cookbook/features/recipe_catalog/logic/format_ingredient.dart';
import 'package:cookbook/features/shopping_list/logic/shopping_list_controller.dart';
import 'package:flutter/material.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({required this.controller, super.key});

  final ShoppingListController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final error = controller.error;
        return Scaffold(
          appBar: AppBar(title: const Text('Shopping list')),
          body: Column(
            children: <Widget>[
              SizedBox(
                height: 4,
                child: controller.busy ? const LinearProgressIndicator() : null,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Semantics(liveRegion: true, child: Text(error)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: controller.busy ? null : controller.load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (controller.loaded && controller.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Your shopping list is empty.'),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    key: const PageStorageKey<String>('shopping-list-items'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      final text = formatIngredient(item.ingredient);
                      return Padding(
                        key: ValueKey<String>('shopping-item-${item.id}'),
                        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Checkbox(
                              key: ValueKey<String>(
                                'shopping-check-${item.id}',
                              ),
                              value: item.checked,
                              semanticLabel: text,
                              onChanged: controller.busy
                                  ? null
                                  : (checked) {
                                      if (checked != null) {
                                        controller.setChecked(item.id, checked);
                                      }
                                    },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  text,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        decoration: item.checked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ),
                            ),
                            IconButton(
                              key: ValueKey<String>(
                                'shopping-remove-${item.id}',
                              ),
                              tooltip: 'Remove $text',
                              onPressed: controller.busy
                                  ? null
                                  : () => controller.remove(item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
