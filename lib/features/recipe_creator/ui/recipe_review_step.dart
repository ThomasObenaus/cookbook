import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter/material.dart';

class RecipeReviewStep extends StatelessWidget {
  const RecipeReviewStep({
    required this.title,
    required this.imagePath,
    required this.ingredients,
    required this.steps,
    required this.enabled,
    required this.onEditRecipe,
    required this.onEditIngredients,
    required this.onEditPreparation,
    super.key,
  });

  final String title;
  final String imagePath;
  final List<IngredientDraft> ingredients;
  final List<String> steps;
  final bool enabled;
  final VoidCallback onEditRecipe;
  final VoidCallback onEditIngredients;
  final VoidCallback onEditPreparation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: RecipeImageView(
              image: RecipeImage.file(imagePath),
              semanticLabel: 'Recipe image for ${title.trim()}',
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ReviewHeading(
          title: 'Recipe',
          editKey: 'edit-recipe-section',
          enabled: enabled,
          onEdit: onEditRecipe,
        ),
        Text(
          title.trim(),
          key: const ValueKey<String>('review-recipe-title'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 600
                ? (constraints.maxWidth - 40) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 20,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: const _Metadata(
                    icon: Icons.people_outline,
                    label: 'Serves 4',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _Metadata(
                    icon: Icons.schedule,
                    label: 'Preparation 0 min',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _Metadata(
                    icon: Icons.timer_outlined,
                    label: 'Cooking 0 min',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _ReviewHeading(
          title: 'Ingredients',
          editKey: 'edit-ingredients-section',
          enabled: enabled,
          onEdit: onEditIngredients,
        ),
        for (var index = 0; index < ingredients.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 28, child: Text('${index + 1}.')),
                Expanded(child: Text(_ingredientText(ingredients[index]))),
              ],
            ),
          ),
        const SizedBox(height: 18),
        _ReviewHeading(
          title: 'Preparation',
          editKey: 'edit-preparation-section',
          enabled: enabled,
          onEdit: onEditPreparation,
        ),
        for (var index = 0; index < steps.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 28, child: Text('${index + 1}.')),
                Expanded(child: Text(steps[index].trim())),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewHeading extends StatelessWidget {
  const _ReviewHeading({
    required this.title,
    required this.editKey,
    required this.enabled,
    required this.onEdit,
  });

  final String title;
  final String editKey;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton.icon(
          key: ValueKey<String>(editKey),
          onPressed: enabled ? onEdit : null,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
      ],
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Expanded(child: Text(label)),
      ],
    );
  }
}

String _ingredientText(IngredientDraft ingredient) {
  final amount = <String>[
    if (ingredient.quantity.isNotEmpty) ingredient.quantity,
    if (ingredient.unit != null) ingredient.unit!.storedValue,
  ].join(' ');
  final value = <String>[
    if (amount.isNotEmpty) amount,
    ingredient.name,
  ].join(' ');
  return ingredient.note.isEmpty ? value : '$value (${ingredient.note})';
}
