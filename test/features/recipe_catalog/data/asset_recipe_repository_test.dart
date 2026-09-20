import 'dart:convert';

import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assetPath = 'assets/data/test_recipes.json';

  group('AssetRecipeRepository', () {
    test('loads, parses, and returns immutable recipes', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{
          assetPath: jsonEncode(<Object?>[
            _recipeJson(id: 'first', name: 'First Recipe'),
            _recipeJson(id: 'second', name: 'Second Recipe'),
          ]),
        }),
        assetPath: assetPath,
      );

      final recipes = await repository.getAllRecipes();

      expect(recipes.map((recipe) => recipe.id), <String>['first', 'second']);
      expect(() => recipes.add(recipes.first), throwsUnsupportedError);
    });

    test('allows an empty recipe collection', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{assetPath: '[]'}),
        assetPath: assetPath,
      );

      expect(await repository.getAllRecipes(), isEmpty);
    });

    test('converts a missing asset into a repository error', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(const <String, String>{}),
        assetPath: assetPath,
      );

      await _expectRepositoryError(
        repository,
        causeMatcher: isA<FlutterError>(),
      );
    });

    test('converts malformed JSON into a repository error', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{assetPath: '{broken'}),
        assetPath: assetPath,
      );

      await _expectRepositoryError(
        repository,
        causeMatcher: isA<FormatException>(),
      );
    });

    test('rejects a non-list recipe collection', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{assetPath: '{}'}),
        assetPath: assetPath,
      );

      await _expectRepositoryError(
        repository,
        causeMatcher: isA<FormatException>(),
      );
    });

    test('converts invalid recipes into a repository error', () async {
      final invalidRecipe = _recipeJson(id: 'invalid', name: 'Invalid')
        ..['servings'] = 0;
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{
          assetPath: jsonEncode(<Object?>[invalidRecipe]),
        }),
        assetPath: assetPath,
      );

      await _expectRepositoryError(
        repository,
        causeMatcher: isA<FormatException>(),
      );
    });

    test('rejects duplicate recipe ids', () async {
      final repository = AssetRecipeRepository(
        assetBundle: _FakeAssetBundle(<String, String>{
          assetPath: jsonEncode(<Object?>[
            _recipeJson(id: 'duplicate', name: 'First'),
            _recipeJson(id: 'duplicate', name: 'Second'),
          ]),
        }),
        assetPath: assetPath,
      );

      await _expectRepositoryError(
        repository,
        causeMatcher: isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Duplicate recipe id: duplicate'),
        ),
      );
    });
  });
}

Future<void> _expectRepositoryError(
  RecipeRepository repository, {
  required Matcher causeMatcher,
}) async {
  try {
    await repository.getAllRecipes();
    fail('Expected RecipeRepositoryException.');
  } on RecipeRepositoryException catch (error) {
    expect(error.message, 'Recipes could not be loaded. Please try again.');
    expect(error.toString(), error.message);
    expect(error.cause, causeMatcher);
    expect(error.stackTrace, isNot(StackTrace.empty));
  }
}

Map<String, Object?> _recipeJson({required String id, required String name}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'servings': 2,
    'prepMinutes': 5,
    'cookMinutes': 10,
    'image': <String, Object?>{
      'kind': 'asset',
      'path': 'assets/images/recipe_placeholder.png',
    },
    'ingredients': <Object?>[
      <String, Object?>{'name': 'ingredient'},
    ],
    'steps': <Object?>['Cook the recipe.'],
  };
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final source = assets[key];
    if (source == null) {
      throw FlutterError('Missing asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
  }
}
