import 'dart:io';

import 'package:cookbook/app/cookbook_home_screen.dart';
import 'package:cookbook/features/meal_planner/data/local_meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/ui/weekly_meal_planner_screen.dart';
import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/gallery_recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/shopping_list/data/local_shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createCookbookApp());
}

Future<Widget> createCookbookApp({
  Future<Directory> Function() supportDirectoryProvider =
      getApplicationSupportDirectory,
}) async {
  try {
    final supportDirectory = await supportDirectoryProvider();
    final repository = LocalRecipeRepository(
      seedRepository: AssetRecipeRepository(assetBundle: rootBundle),
      applicationSupportDirectory: supportDirectory,
      createId: const Uuid().v4,
    );
    final mealPlanRepository = LocalMealPlanRepository(
      applicationSupportDirectory: supportDirectory,
    );
    return CookbookApp(
      repository: repository,
      mealPlanRepository: mealPlanRepository,
      shoppingListRepository: LocalShoppingListRepository(
        applicationSupportDirectory: supportDirectory,
        createId: const Uuid().v4,
      ),
      imagePicker: GalleryRecipeImagePicker(),
      currentDateProvider: DateTime.now,
    );
  } catch (_) {
    return const CookbookStartupFailureApp();
  }
}

class CookbookStartupFailureApp extends StatelessWidget {
  const CookbookStartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookbook',
      debugShowCheckedModeBanner: false,
      theme: _cookbookTheme(),
      home: const Scaffold(
        body: Center(
          key: ValueKey<String>('cookbook-startup-error'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cookbook could not start. Please restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class CookbookApp extends StatelessWidget {
  const CookbookApp({
    required this.repository,
    required this.mealPlanRepository,
    required this.shoppingListRepository,
    required this.imagePicker,
    required this.currentDateProvider,
    super.key,
  });

  final MutableRecipeRepository repository;
  final MealPlanRepository mealPlanRepository;
  final ShoppingListRepository shoppingListRepository;
  final RecipeImagePicker imagePicker;
  final CurrentDateProvider currentDateProvider;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookbook',
      debugShowCheckedModeBanner: false,
      theme: _cookbookTheme(),
      home: CookbookHomeScreen(
        recipeRepository: repository,
        mealPlanRepository: mealPlanRepository,
        shoppingListRepository: shoppingListRepository,
        imagePicker: imagePicker,
        currentDateProvider: currentDateProvider,
      ),
    );
  }
}

ThemeData _cookbookTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF365C4A))
      .copyWith(
        primary: const Color(0xFF365C4A),
        secondary: const Color(0xFFB64E33),
        tertiary: const Color(0xFFD29B2D),
        surface: const Color(0xFFFFFBF5),
      );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF7F2E8),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
