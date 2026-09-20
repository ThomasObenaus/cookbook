import 'package:flutter/material.dart';

class PreparationWizardStep extends StatelessWidget {
  const PreparationWizardStep({
    required this.steps,
    required this.controller,
    required this.focusNode,
    required this.editorVisible,
    required this.editingIndex,
    required this.stepError,
    required this.enabled,
    required this.onChanged,
    required this.onSave,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final List<String> steps;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editorVisible;
  final int? editingIndex;
  final String? stepError;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final visibleSummaryIndexes = <int>[
      for (var index = 0; index < steps.length; index++)
        if (!editorVisible || editingIndex != index) index,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (editorVisible) ...<Widget>[
          Text(
            'Step ${(editingIndex ?? steps.length) + 1}',
            key: const ValueKey<String>('active-preparation-label'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey<String>('preparation-step-field'),
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Instruction',
              alignLabelWithHint: true,
              errorText: stepError,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey<String>('save-preparation-step'),
              onPressed: enabled ? onSave : null,
              icon: const Icon(Icons.check),
              label: const Text('Save step'),
            ),
          ),
        ],
        if (editorVisible && visibleSummaryIndexes.isNotEmpty)
          const SizedBox(height: 24),
        for (final index in visibleSummaryIndexes) ...<Widget>[
          _PreparationSummary(
            index: index,
            instruction: steps[index],
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
              key: const ValueKey<String>('add-preparation-step'),
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add),
              label: const Text('Add another step'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreparationSummary extends StatelessWidget {
  const _PreparationSummary({
    required this.index,
    required this.instruction,
    required this.enabled,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final String instruction;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Step ${index + 1}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                instruction,
                key: ValueKey<String>('preparation-summary-$index'),
              ),
            ],
          ),
        ),
        IconButton(
          key: ValueKey<String>('edit-preparation-step-$index'),
          onPressed: enabled ? onEdit : null,
          tooltip: 'Edit preparation step ${index + 1}',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          key: ValueKey<String>('remove-preparation-step-$index'),
          onPressed: enabled ? onRemove : null,
          tooltip: 'Remove preparation step ${index + 1}',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
