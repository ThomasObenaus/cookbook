import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory supportDirectory;
  late File sourceImage;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'cookbook-repository-',
    );
    sourceImage = File.fromUri(supportDirectory.uri.resolve('picked.png'));
    await sourceImage.writeAsBytes(<int>[1, 2, 3, 4], flush: true);
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('loads bundled recipes when local storage does not exist', () async {
    final seed = _recipe('seed', 'Bundled Recipe');
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[seed],
    );

    final recipes = await repository.getAllRecipes();

    expect(recipes, <Recipe>[seed]);
    expect(() => recipes.clear(), throwsUnsupportedError);
  });

  test('copies an image and persists a recipe across instances', () async {
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[_recipe('seed', 'Bundled Recipe')],
      ids: <String>['created-id'],
    );

    final created = await repository.createRecipe(
      _newRecipe('Created Recipe', sourceImage.path),
    );

    expect(created.id, 'created-id');
    expect(created.servings, 4);
    expect(created.prepMinutes, 0);
    expect(created.cookMinutes, 0);
    expect(created.image.kind, RecipeImageKind.file);
    expect(await File(created.image.path).readAsBytes(), <int>[1, 2, 3, 4]);
    expect(
      (await repository.getAllRecipes()).map((recipe) => recipe.name),
      <String>['Created Recipe', 'Bundled Recipe'],
    );

    final restartedRepository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[_recipe('seed', 'Bundled Recipe')],
    );
    expect(
      (await restartedRepository.getAllRecipes()).map((recipe) => recipe.name),
      <String>['Created Recipe', 'Bundled Recipe'],
    );
  });

  test('keeps the newest user recipe first', () async {
    final ids = <String>['first-id', 'second-id'];
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[_recipe('seed', 'Bundled Recipe')],
      ids: ids,
    );

    await repository.createRecipe(_newRecipe('First', sourceImage.path));
    await repository.createRecipe(_newRecipe('Second', sourceImage.path));

    expect(
      (await repository.getAllRecipes()).map((recipe) => recipe.name),
      <String>['Second', 'First', 'Bundled Recipe'],
    );
  });

  test('rejects an id that collides with a bundled recipe', () async {
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[_recipe('duplicate', 'Bundled Recipe')],
      ids: <String>['duplicate'],
    );

    await expectLater(
      repository.createRecipe(_newRecipe('Created', sourceImage.path)),
      throwsA(
        isA<RecipeRepositoryException>().having(
          (error) => error.message,
          'message',
          'The recipe could not be saved. Please try again.',
        ),
      ),
    );
  });

  test('wraps malformed local metadata as a load error', () async {
    final dataDirectory = Directory.fromUri(
      supportDirectory.uri.resolve('cookbook/'),
    );
    await dataDirectory.create();
    await File.fromUri(dataDirectory.uri.resolve('user_recipes.json'))
        .writeAsString('{broken');
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: const <Recipe>[],
    );

    await expectLater(
      repository.getAllRecipes(),
      throwsA(
        isA<RecipeRepositoryException>().having(
          (error) => error.cause,
          'cause',
          isA<FormatException>(),
        ),
      ),
    );
  });

  test('rejects a missing selected image', () async {
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: const <Recipe>[],
      ids: <String>['missing-image'],
    );

    await expectLater(
      repository.createRecipe(
        _newRecipe('Created', '${supportDirectory.path}/missing.png'),
      ),
      throwsA(isA<RecipeRepositoryException>()),
    );
    expect(
      await Directory.fromUri(
        supportDirectory.uri.resolve('cookbook/recipe_images/'),
      ).exists(),
      isFalse,
    );
  });

  test('removes the copied image when metadata writing fails', () async {
    final dataDirectory = Directory.fromUri(
      supportDirectory.uri.resolve('cookbook/'),
    );
    await dataDirectory.create();
    await Directory('${dataDirectory.path}/user_recipes.json.tmp').create();
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: const <Recipe>[],
      ids: <String>['failed-save'],
    );

    await expectLater(
      repository.createRecipe(_newRecipe('Created', sourceImage.path)),
      throwsA(isA<RecipeRepositoryException>()),
    );

    final imageDirectory = Directory.fromUri(
      supportDirectory.uri.resolve('cookbook/recipe_images/'),
    );
    expect(await imageDirectory.list().toList(), isEmpty);
  });

  test('stores only user recipes in local metadata', () async {
    final repository = _repository(
      supportDirectory: supportDirectory,
      seeds: <Recipe>[_recipe('seed', 'Bundled Recipe')],
      ids: <String>['created-id'],
    );

    await repository.createRecipe(_newRecipe('Created', sourceImage.path));

    final metadata = jsonDecode(
      await File.fromUri(
        supportDirectory.uri.resolve('cookbook/user_recipes.json'),
      ).readAsString(),
    ) as Map<String, Object?>;
    expect(metadata['version'], 1);
    expect(metadata['recipes'], hasLength(1));
  });
}

LocalRecipeRepository _repository({
  required Directory supportDirectory,
  required List<Recipe> seeds,
  List<String> ids = const <String>[],
}) {
  var idIndex = 0;
  return LocalRecipeRepository(
    seedRepository: _StaticRepository(seeds),
    applicationSupportDirectory: supportDirectory,
    createId: () => ids.isEmpty ? 'unused-id' : ids[idIndex++],
  );
}

NewRecipe _newRecipe(String name, String imagePath) {
  return NewRecipe.fromInput(
    name: name,
    ingredients: const <IngredientDraft>[
      IngredientDraft(name: 'salt', quantity: '1', unit: 'tsp'),
    ],
    preparationSteps: 'Mix.\nCook.',
    sourceImagePath: imagePath,
  );
}

Recipe _recipe(String id, String name) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 20,
    image: RecipeImage.asset('assets/images/recipe_placeholder.png'),
    ingredients: const <Ingredient>[Ingredient(name: 'salt')],
    steps: const <String>['Cook.'],
  );
}

class _StaticRepository implements RecipeRepository {
  const _StaticRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;
}
