import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/logic/recipe_search.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_card.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_detail_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_creator_screen.dart';
import 'package:flutter/material.dart';

class RecipeCatalogScreen extends StatefulWidget {
  const RecipeCatalogScreen({
    required this.repository,
    required this.imagePicker,
    this.onAddIngredients,
    super.key,
  });

  final MutableRecipeRepository repository;
  final RecipeImagePicker imagePicker;
  final AddIngredients? onAddIngredients;

  @override
  State<RecipeCatalogScreen> createState() => _RecipeCatalogScreenState();
}

enum _CatalogStatus { loading, success, failure }

class _RecipeCatalogScreenState extends State<RecipeCatalogScreen> {
  late final TextEditingController _searchController;
  _CatalogStatus _status = _CatalogStatus.loading;
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
        _status = _CatalogStatus.success;
        _errorMessage = '';
      });
    } on RecipeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _CatalogStatus.failure;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _CatalogStatus.failure;
        _errorMessage = 'Recipes could not be loaded. Please try again.';
      });
    }
  }

  void _retry() {
    setState(() {
      _status = _CatalogStatus.loading;
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

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RecipeDetailScreen(
          recipe: recipe,
          onAddIngredients: widget.onAddIngredients,
        ),
      ),
    );
  }

  Future<void> _openCreator() async {
    final recipe = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute<Recipe>(
        builder: (context) => RecipeCreatorScreen(
          repository: widget.repository,
          imagePicker: widget.imagePicker,
        ),
      ),
    );
    if (!mounted || recipe == null) {
      return;
    }

    _searchController.clear();
    setState(() {
      _query = '';
      _status = _CatalogStatus.loading;
      _errorMessage = '';
    });
    await _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('create-recipe-action'),
            onPressed: _openCreator,
            tooltip: 'Create recipe',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: switch (_status) {
        _CatalogStatus.loading => const _LoadingState(),
        _CatalogStatus.failure => _FailureState(
          message: _errorMessage,
          onRetry: _retry,
        ),
        _CatalogStatus.success => _buildSuccess(),
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
            key: const ValueKey<String>('recipe-search-field'),
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
              ? const _EmptyCatalogState()
              : displayedRecipes.isEmpty
              ? _NoResultsState(query: _query.trim())
              : _RecipeGrid(
                  recipes: displayedRecipes,
                  onRecipeTap: _openRecipe,
                ),
        ),
      ],
    );
  }
}

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes, required this.onRecipeTap});

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
          key: const ValueKey<String>('recipe-grid'),
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
              key: ValueKey<String>('recipe-card-${recipe.id}'),
              recipe: recipe,
              onTap: () => onRecipeTap(recipe),
            );
          },
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        key: ValueKey<String>('recipe-loading-indicator'),
      ),
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
      key: const ValueKey<String>('recipe-error-state'),
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

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    return const _MessageState(
      key: ValueKey<String>('recipe-empty-state'),
      icon: Icons.menu_book_outlined,
      title: 'No recipes yet',
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      key: const ValueKey<String>('recipe-no-results-state'),
      icon: Icons.search_off,
      title: 'No recipes found',
      message: 'No recipe names match "$query".',
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
