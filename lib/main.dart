import 'dart:io';

import 'package:cookbook/app/cookbook_app.dart';
import 'package:cookbook/features/meal_planner/data/local_meal_plan_repository.dart';
import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/gallery_recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/shopping_list/data/local_shopping_list_repository.dart';
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
    final preferencesStore = LocalAppPreferencesStore(
      applicationSupportDirectory: supportDirectory,
    );
    final initialPreferences = await preferencesStore.load();
    final entitlementController = EntitlementController(
      source: const SharingUnavailableEntitlementSource(),
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
      initialPreferences: initialPreferences,
      preferencesStore: preferencesStore,
      entitlementController: entitlementController,
    );
  } catch (_) {
    return const CookbookStartupFailureApp();
  }
}
