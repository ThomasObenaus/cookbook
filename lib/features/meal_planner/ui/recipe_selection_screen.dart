import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/logic/recipe_search.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_card.dart';
import 'package:flutter/material.dart';

class RecipeSelectionScreen extends StatefulWidget {
  const RecipeSelectionScreen({required this.repository, super.key});

  final RecipeRepository repository;

  @override
  State<RecipeSelectionScreen> createState() => _RecipeSelectionScreenState();
}

enum _SelectionStatus { loading, success, failure }

class _RecipeSelectionScreenState extends State<RecipeSelectionScreen> {
  late final TextEditingController _searchController;
  _SelectionStatus _status = _SelectionStatus.loading;
  List<Recipe> _recipes = const <Recipe>[];
  String _query = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await widget.repository.getAllRecipes();
      if (!mounted) {
        return;
      }
      setState(() {
        _recipes = List<Recipe>.unmodifiable(recipes);
        _status = _SelectionStatus.success;
        _errorMessage = '';
      });
    } on RecipeRepositoryException catch (error) {
      _showFailure(error.message);
    } catch (_) {
      _showFailure('Recipes could not be loaded. Please try again.');
    }
  }

  void _showFailure(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _status = _SelectionStatus.failure;
      _errorMessage = message;
    });
  }

  void _retry() {
    setState(() {
      _status = _SelectionStatus.loading;
      _errorMessage = '';
    });
    _loadRecipes();
  }

  void _updateQuery(String query) {
    setState(() {
      _query = query;
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _updateQuery('');
  }

  void _selectRecipe(Recipe recipe) {
    Navigator.of(context).pop(recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select recipe')),
      body: switch (_status) {
        _SelectionStatus.loading => const Center(
          child: CircularProgressIndicator(
            key: ValueKey<String>('recipe-selection-loading-indicator'),
          ),
        ),
        _SelectionStatus.failure => _FailureState(
          message: _errorMessage,
          onRetry: _retry,
        ),
        _SelectionStatus.success => _buildSuccess(),
      },
    );
  }

  Widget _buildSuccess() {
    final displayedRecipes = searchRecipesByName(_recipes, _query);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            key: const ValueKey<String>('recipe-selection-search-field'),
            controller: _searchController,
            onChanged: _updateQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search recipes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clearQuery,
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: _recipes.isEmpty
              ? const _MessageState(
                  key: ValueKey<String>('recipe-selection-empty-state'),
                  icon: Icons.menu_book_outlined,
                  title: 'No recipes yet',
                )
              : displayedRecipes.isEmpty
              ? _MessageState(
                  key: const ValueKey<String>(
                    'recipe-selection-no-results-state',
                  ),
                  icon: Icons.search_off,
                  title: 'No recipes found',
                  message: 'No recipe names match "${_query.trim()}".',
                )
              : _RecipeSelectionGrid(
                  recipes: displayedRecipes,
                  onRecipeTap: _selectRecipe,
                ),
        ),
      ],
    );
  }
}

class _RecipeSelectionGrid extends StatelessWidget {
  const _RecipeSelectionGrid({
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final extraHeight = 88.0 * (textScale - 1).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          key: const ValueKey<String>('recipe-selection-grid'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 272 + extraHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return RecipeCard(
              key: ValueKey<String>('select-recipe-card-${recipe.id}'),
              recipe: recipe,
              semanticLabel:
                  'Select ${recipe.name}, ${recipe.totalMinutes} minutes, '
                  'serves ${recipe.servings}',
              onTap: () => onRecipeTap(recipe),
            );
          },
        );
      },
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('recipe-selection-error-state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
