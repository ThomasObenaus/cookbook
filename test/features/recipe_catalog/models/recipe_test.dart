import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ingredient.fromJson', () {
    test('parses required and optional fields', () {
      final ingredient = Ingredient.fromJson(<String, Object?>{
        'name': '  mushrooms ',
        'quantity': ' 250 ',
        'unit': ' g ',
        'note': ' sliced ',
      });

      expect(ingredient.name, 'mushrooms');
      expect(ingredient.quantity, '250');
      expect(ingredient.unit, 'g');
      expect(ingredient.note, 'sliced');
    });

    test('allows omitted optional fields', () {
      final ingredient = Ingredient.fromJson(<String, Object?>{'name': 'salt'});

      expect(ingredient.quantity, isNull);
      expect(ingredient.unit, isNull);
      expect(ingredient.note, isNull);
    });

    test('rejects a non-object value', () {
      expect(() => Ingredient.fromJson('salt'), throwsFormatException);
    });

    test('rejects missing, empty, and wrongly typed names', () {
      for (final invalidJson in <Map<String, Object?>>[
        <String, Object?>{},
        <String, Object?>{'name': '   '},
        <String, Object?>{'name': 1},
      ]) {
        expect(
          () => Ingredient.fromJson(invalidJson),
          throwsFormatException,
          reason: '$invalidJson',
        );
      }
    });

    test('rejects wrongly typed optional fields', () {
      for (final field in <String>['quantity', 'unit', 'note']) {
        expect(
          () =>
              Ingredient.fromJson(<String, Object?>{'name': 'salt', field: 1}),
          throwsFormatException,
          reason: field,
        );
      }
    });
  });

  group('Recipe.fromJson', () {
    test('parses a valid recipe and derives total time', () {
      final recipe = Recipe.fromJson(_validRecipeJson());

      expect(recipe.id, 'mushroom-pasta');
      expect(recipe.name, 'Creamy Mushroom Pasta');
      expect(recipe.servings, 4);
      expect(recipe.prepMinutes, 10);
      expect(recipe.cookMinutes, 20);
      expect(recipe.totalMinutes, 30);
      expect(recipe.imageAssetPath, 'assets/images/recipe_placeholder.png');
      expect(recipe.ingredients.single.name, 'mushrooms');
      expect(recipe.steps, <String>['Slice mushrooms', 'Cook pasta']);
    });

    test('copies parsed collections into immutable lists', () {
      final json = _validRecipeJson();
      final sourceIngredients = json['ingredients']! as List<Object?>;
      final sourceSteps = json['steps']! as List<Object?>;
      final recipe = Recipe.fromJson(json);

      sourceIngredients.add(<String, Object?>{'name': 'garlic'});
      sourceSteps.add('Serve');

      expect(recipe.ingredients, hasLength(1));
      expect(recipe.steps, hasLength(2));
      expect(
        () => recipe.ingredients.add(const Ingredient(name: 'garlic')),
        throwsUnsupportedError,
      );
      expect(() => recipe.steps.add('Serve'), throwsUnsupportedError);
    });

    test('copies constructor collections into immutable lists', () {
      final ingredients = <Ingredient>[const Ingredient(name: 'salt')];
      final steps = <String>['Season'];
      final recipe = Recipe(
        id: 'seasoning',
        name: 'Seasoning',
        servings: 1,
        prepMinutes: 0,
        cookMinutes: 0,
        imageAssetPath: 'assets/images/recipe_placeholder.png',
        ingredients: ingredients,
        steps: steps,
      );

      ingredients.add(const Ingredient(name: 'pepper'));
      steps.add('Serve');

      expect(recipe.ingredients, hasLength(1));
      expect(recipe.steps, hasLength(1));
      expect(() => recipe.steps.clear(), throwsUnsupportedError);
    });

    test('rejects a non-object value', () {
      expect(() => Recipe.fromJson(<Object?>[]), throwsFormatException);
    });

    test('rejects every missing required field', () {
      for (final field in <String>[
        'id',
        'name',
        'servings',
        'prepMinutes',
        'cookMinutes',
        'imageAssetPath',
        'ingredients',
        'steps',
      ]) {
        final json = _validRecipeJson()..remove(field);

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: field,
        );
      }
    });

    test('rejects wrong types for every required field', () {
      final invalidValues = <String, Object?>{
        'id': 1,
        'name': false,
        'servings': '4',
        'prepMinutes': 1.5,
        'cookMinutes': null,
        'imageAssetPath': <Object?>[],
        'ingredients': 'mushrooms',
        'steps': <String, String>{'first': 'Cook'},
      };

      for (final entry in invalidValues.entries) {
        final json = _validRecipeJson()..[entry.key] = entry.value;

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: entry.key,
        );
      }
    });

    test('rejects empty required strings', () {
      for (final field in <String>['id', 'name', 'imageAssetPath']) {
        final json = _validRecipeJson()..[field] = '   ';

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: field,
        );
      }
    });

    test('rejects out-of-range numeric values', () {
      final invalidValues = <String, int>{
        'servings': 0,
        'prepMinutes': -1,
        'cookMinutes': -1,
      };

      for (final entry in invalidValues.entries) {
        final json = _validRecipeJson()..[entry.key] = entry.value;

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: entry.key,
        );
      }
    });

    test('rejects empty ingredient and step lists', () {
      for (final field in <String>['ingredients', 'steps']) {
        final json = _validRecipeJson()..[field] = <Object?>[];

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: field,
        );
      }
    });

    test('rejects invalid ingredients', () {
      final json = _validRecipeJson()
        ..['ingredients'] = <Object?>[
          <String, Object?>{'name': ''},
        ];

      expect(() => Recipe.fromJson(json), throwsFormatException);
    });

    test('rejects wrongly typed and empty steps', () {
      for (final invalidStep in <Object?>[1, '   ']) {
        final json = _validRecipeJson()..['steps'] = <Object?>[invalidStep];

        expect(
          () => Recipe.fromJson(json),
          throwsFormatException,
          reason: '$invalidStep',
        );
      }
    });
  });
}

Map<String, Object?> _validRecipeJson() {
  return <String, Object?>{
    'id': 'mushroom-pasta',
    'name': 'Creamy Mushroom Pasta',
    'servings': 4,
    'prepMinutes': 10,
    'cookMinutes': 20,
    'imageAssetPath': 'assets/images/recipe_placeholder.png',
    'ingredients': <Object?>[
      <String, Object?>{'name': 'mushrooms', 'quantity': '250', 'unit': 'g'},
    ],
    'steps': <Object?>['Slice mushrooms', 'Cook pasta'],
  };
}
