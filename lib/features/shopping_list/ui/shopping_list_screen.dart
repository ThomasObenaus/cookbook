import 'package:cookbook/features/recipe_catalog/logic/format_ingredient.dart';
import 'package:cookbook/features/shopping_list/logic/shopping_list_controller.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';
import 'package:cookbook/features/shopping_list/ui/shopping_list_item_editor_screen.dart';
import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({required this.controller, super.key});

  final ShoppingListController controller;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _expanded = false;
  bool _confirmingClear = false;
  ShoppingListController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_resetExpansion);
  }

  @override
  void didUpdateWidget(ShoppingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_resetExpansion);
      controller.addListener(_resetExpansion);
      _expanded = false;
    }
  }

  void _resetExpansion() {
    if (_expanded && !controller.items.any((item) => item.checked)) {
      setState(() => _expanded = false);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_resetExpansion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final error = controller.error;
        final active = controller.items.where((item) => !item.checked).toList();
        final completed = controller.items
            .where((item) => item.checked)
            .toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping list'),
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('shopping-clear'),
                tooltip: 'Clear shopping list',
                onPressed:
                    controller.loaded &&
                        controller.items.isNotEmpty &&
                        !controller.busy
                    ? _confirmClear
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
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
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('shopping-list-items'),
                    slivers: <Widget>[
                      _group(active, false),
                      if (completed.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Semantics(
                            expanded: _expanded,
                            child: ListTile(
                              key: const ValueKey<String>(
                                'shopping-completed-header',
                              ),
                              title: Text('Completed (${completed.length})'),
                              trailing: Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onTap: () =>
                                  setState(() => _expanded = !_expanded),
                            ),
                          ),
                        ),
                      if (_expanded) _group(completed, true),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _group(List<ShoppingListItem> items, bool checked) {
    return SliverReorderableList(
      key: ValueKey<String>('shopping-group-$checked'),
      itemCount: items.length,
      itemBuilder: (context, index) => _row(items[index], index, items),
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
      onReorderItem: (oldIndex, newIndex) => _move(items, oldIndex, newIndex),
    );
  }

  void _move(List<ShoppingListItem> items, int oldIndex, int newIndex) {
    if (controller.busy || oldIndex == newIndex) return;
    final ids = items.map((item) => item.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));
    controller.reorder(checked: items.first.checked, ids: ids);
  }

  Future<void> _edit(ShoppingListItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ShoppingListItemEditorScreen(
          item: item,
          onSave: (ingredient) => controller.update(item.id, ingredient),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    if (_confirmingClear ||
        !controller.loaded ||
        controller.items.isEmpty ||
        controller.busy) {
      return;
    }
    _confirmingClear = true;
    final count = controller.items.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear shopping list?'),
        content: Text(
          'Remove all $count ${count == 1 ? 'entry' : 'entries'}, '
          'including active and completed items?',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('shopping-clear-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>('shopping-clear-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    _confirmingClear = false;
    if (confirmed == true &&
        mounted &&
        controller.loaded &&
        controller.items.isNotEmpty &&
        !controller.busy) {
      await controller.clear();
    }
  }

  Widget _row(ShoppingListItem item, int index, List<ShoppingListItem> group) {
    final text = formatIngredient(item.ingredient);
    final VoidCallback? toggle = controller.busy
        ? null
        : () => controller.setChecked(item.id, !item.checked);
    return Padding(
      key: ValueKey<String>('shopping-item-${item.id}'),
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    key: ValueKey<String>('shopping-check-${item.id}'),
                    value: item.checked,
                    onChanged: toggle == null ? null : (_) => toggle(),
                  ),
                  Expanded(
                    child: InkWell(
                      key: ValueKey<String>('shopping-text-${item.id}'),
                      onTap: toggle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                key: ValueKey<String>('shopping-edit-${item.id}'),
                tooltip: 'Edit $text',
                onPressed: controller.busy ? null : () => _edit(item),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: ValueKey<String>('shopping-remove-${item.id}'),
                tooltip: 'Remove $text',
                onPressed: controller.busy
                    ? null
                    : () => controller.remove(item.id),
                icon: const Icon(Icons.delete_outline),
              ),
              ReorderableDragStartListener(
                key: ValueKey<String>('shopping-drag-${item.id}'),
                index: index,
                enabled: !controller.busy && group.length > 1,
                child: Tooltip(
                  message: 'Drag to reorder $text',
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: ValueKey<String>('shopping-move-${item.id}'),
                tooltip: 'Move $text',
                enabled: !controller.busy,
                icon: const Icon(Icons.swap_vert),
                onSelected: (direction) =>
                    _move(group, index, index + (direction == 'up' ? -1 : 1)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'up',
                    enabled: index > 0,
                    child: const Text('Move up'),
                  ),
                  PopupMenuItem(
                    value: 'down',
                    enabled: index < group.length - 1,
                    child: const Text('Move down'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
