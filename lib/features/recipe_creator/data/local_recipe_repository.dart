import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';

class LocalRecipeRepository implements MutableRecipeRepository {
  LocalRecipeRepository({
    required this.seedRepository,
    required Directory applicationSupportDirectory,
    required this.createId,
  }) : _dataDirectory = Directory.fromUri(
         applicationSupportDirectory.uri.resolve('cookbook/'),
       );

  static const _loadErrorMessage =
      'Recipes could not be loaded. Please try again.';
  static const _saveErrorMessage =
      'The recipe could not be saved. Please try again.';

  final RecipeRepository seedRepository;
  final String Function() createId;
  final Directory _dataDirectory;

  Directory get _imageDirectory =>
      Directory.fromUri(_dataDirectory.uri.resolve('recipe_images/'));
  File get _recipesFile =>
      File.fromUri(_dataDirectory.uri.resolve('user_recipes.json'));

  @override
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final bundledRecipes = await seedRepository.getAllRecipes();
      final userRecipes = await _readUserRecipes();
      _ensureUniqueIds(<Recipe>[...userRecipes, ...bundledRecipes]);
      return List<Recipe>.unmodifiable(<Recipe>[
        ...userRecipes,
        ...bundledRecipes,
      ]);
    } on RecipeRepositoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw RecipeRepositoryException(
        message: _loadErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Recipe> createRecipe(NewRecipe newRecipe) async {
    File? copiedImage;
    try {
      final userRecipes = await _readUserRecipes();
      final bundledRecipes = await seedRepository.getAllRecipes();
      final existingIds = <String>{
        for (final recipe in userRecipes) recipe.id,
        for (final recipe in bundledRecipes) recipe.id,
      };
      final recipeId = createId().trim();
      if (!_validId.hasMatch(recipeId) || existingIds.contains(recipeId)) {
        throw FormatException('Invalid or duplicate recipe id: $recipeId.');
      }

      final sourceImage = File(newRecipe.sourceImagePath);
      if (!await sourceImage.exists()) {
        throw const FileSystemException('The selected image no longer exists.');
      }

      await _imageDirectory.create(recursive: true);
      final extension = _safeExtension(sourceImage.path);
      copiedImage = File.fromUri(
        _imageDirectory.uri.resolve('$recipeId$extension'),
      );
      if (await copiedImage.exists()) {
        throw FileSystemException(
          'The recipe image already exists.',
          copiedImage.path,
        );
      }

      final temporaryImage = File('${copiedImage.path}.tmp');
      await sourceImage.copy(temporaryImage.path);
      await temporaryImage.rename(copiedImage.path);

      final recipe = Recipe(
        id: recipeId,
        name: newRecipe.name,
        servings: 4,
        prepMinutes: 0,
        cookMinutes: 0,
        image: RecipeImage.file(copiedImage.path),
        ingredients: newRecipe.ingredients,
        steps: newRecipe.steps,
      );
      await _writeUserRecipes(<Recipe>[recipe, ...userRecipes]);
      return recipe;
    } catch (error, stackTrace) {
      await _deleteIfPresent(copiedImage);
      throw RecipeRepositoryException(
        message: _saveErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Recipe>> _readUserRecipes() async {
    final recipesFile = _recipesFile;
    if (!await recipesFile.exists()) {
      return const <Recipe>[];
    }

    final Object? decoded = jsonDecode(await recipesFile.readAsString());
    if (decoded is! Map<String, Object?> || decoded['version'] != 1) {
      throw const FormatException('Unsupported local recipe data.');
    }
    final values = decoded['recipes'];
    if (values is! List<Object?>) {
      throw const FormatException('Local recipes must be a list.');
    }

    final recipes = <Recipe>[];
    for (var index = 0; index < values.length; index++) {
      final recipe = Recipe.fromJson(values[index]);
      if (recipe.image.kind != RecipeImageKind.file) {
        throw FormatException(
          'Local recipe at index $index must use a file image.',
        );
      }
      recipes.add(recipe);
    }
    _ensureUniqueIds(recipes);
    return recipes;
  }

  Future<void> _writeUserRecipes(List<Recipe> recipes) async {
    await _dataDirectory.create(recursive: true);
    final temporaryFile = File('${_recipesFile.path}.tmp');
    try {
      await temporaryFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 1,
          'recipes': recipes.map((recipe) => recipe.toJson()).toList(),
        }),
        flush: true,
      );
      await temporaryFile.rename(_recipesFile.path);
    } catch (_) {
      await _deleteIfPresent(temporaryFile);
      rethrow;
    }
  }
}

final RegExp _validId = RegExp(r'^[A-Za-z0-9_-]+$');
final RegExp _validExtension = RegExp(r'^\.[A-Za-z0-9]{1,8}$');

String _safeExtension(String path) {
  final fileName = Uri.file(path).pathSegments.last;
  final separator = fileName.lastIndexOf('.');
  if (separator <= 0) {
    return '.jpg';
  }
  final extension = fileName.substring(separator).toLowerCase();
  return _validExtension.hasMatch(extension) ? extension : '.jpg';
}

void _ensureUniqueIds(Iterable<Recipe> recipes) {
  final ids = <String>{};
  for (final recipe in recipes) {
    if (!ids.add(recipe.id)) {
      throw FormatException('Duplicate recipe id: ${recipe.id}.');
    }
  }
}

Future<void> _deleteIfPresent(File? file) async {
  if (file == null) {
    return;
  }
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } on FileSystemException {
    return;
  }
}
