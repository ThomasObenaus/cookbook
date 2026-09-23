import 'package:cookbook/features/recipe_catalog/logic/format_ingredient.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:flutter/material.dart';

typedef AddIngredients = Future<bool> Function(List<Ingredient> ingredients);

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    required this.recipe,
    this.onAddIngredients,
    super.key,
  });

  final Recipe recipe;
  final AddIngredients? onAddIngredients;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe details')),
      body: SingleChildScrollView(
        key: const ValueKey<String>('recipe-detail-scroll-view'),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: RecipeImageView(
                    key: const ValueKey<String>('recipe-detail-image'),
                    image: recipe.image,
                    fit: BoxFit.cover,
                    fallbackIconSize: 64,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      _RecipeMetadata(recipe: recipe),
                      const SizedBox(height: 32),
                      Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _AddIngredientsButton(
                        ingredients: recipe.ingredients,
                        onAdd: onAddIngredients,
                      ),
                      const SizedBox(height: 12),
                      for (
                        var index = 0;
                        index < recipe.ingredients.length;
                        index++
                      )
                        _IngredientRow(
                          key: ValueKey<String>('ingredient-$index'),
                          ingredient: recipe.ingredients[index],
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Method',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < recipe.steps.length; index++)
                        _StepRow(
                          key: ValueKey<String>('recipe-step-${index + 1}'),
                          number: index + 1,
                          instruction: recipe.steps[index],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddIngredientsButton extends StatefulWidget {
  const _AddIngredientsButton({required this.ingredients, required this.onAdd});

  final List<Ingredient> ingredients;
  final AddIngredients? onAdd;

  @override
  State<_AddIngredientsButton> createState() => _AddIngredientsButtonState();
}

class _AddIngredientsButtonState extends State<_AddIngredientsButton> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _add() async {
    final onAdd = widget.onAdd;
    if (_saving || onAdd == null) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    var saved = false;
    try {
      saved = await onAdd(List<Ingredient>.unmodifiable(widget.ingredients));
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failed = !saved;
    });
    if (saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Ingredients added to shopping list.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          key: const ValueKey<String>('add-to-shopping-list'),
          onPressed: _saving || widget.onAdd == null ? null : _add,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_shopping_cart),
          label: const Text(
            'Add to shopping list',
            textAlign: TextAlign.center,
          ),
        ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: const Text(
                'Ingredients could not be added. Please try again.',
              ),
            ),
          ),
      ],
    );
  }
}

class _RecipeMetadata extends StatelessWidget {
  const _RecipeMetadata({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            _MetadataItem(
              width: itemWidth,
              icon: Icons.people_outline,
              label: 'Serves ${recipe.servings}',
            ),
            _MetadataItem(
              width: itemWidth,
              icon: Icons.timer_outlined,
              label: 'Preparation ${recipe.prepMinutes} min',
            ),
            _MetadataItem(
              width: itemWidth,
              icon: Icons.local_fire_department_outlined,
              label: 'Cooking ${recipe.cookMinutes} min',
            ),
          ],
        );
      },
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({
    required this.width,
    required this.icon,
    required this.label,
  });

  final double width;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, super.key});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(formatIngredient(ingredient))),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.instruction, super.key});

  final int number;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction)),
        ],
      ),
    );
  }
}
