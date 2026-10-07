import 'package:cookbook/app/cookbook_home_screen.dart';
import 'package:cookbook/app/startup_gate.dart';
import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/ui/weekly_meal_planner_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:flutter/material.dart';

class CookbookApp extends StatefulWidget {
  const CookbookApp({
    required this.repository,
    required this.mealPlanRepository,
    required this.shoppingListRepository,
    required this.imagePicker,
    required this.currentDateProvider,
    required this.initialPreferences,
    required this.preferencesStore,
    required this.entitlementController,
    this.debugEntitlementSource,
    super.key,
  });

  final MutableRecipeRepository repository;
  final MealPlanRepository mealPlanRepository;
  final ShoppingListRepository shoppingListRepository;
  final RecipeImagePicker imagePicker;
  final CurrentDateProvider currentDateProvider;
  final AppPreferences initialPreferences;
  final AppPreferencesStore preferencesStore;
  final EntitlementController entitlementController;
  final DebugEntitlementSource? debugEntitlementSource;

  @override
  State<CookbookApp> createState() => _CookbookAppState();
}

class _CookbookAppState extends State<CookbookApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.entitlementController.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.entitlementController.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.entitlementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookbook',
      debugShowCheckedModeBanner: false,
      theme: cookbookTheme(),
      home: StartupGate(
        initialPreferences: widget.initialPreferences,
        preferencesStore: widget.preferencesStore,
        currentTimeProvider: widget.currentDateProvider,
        cookbook: CookbookHomeScreen(
          recipeRepository: widget.repository,
          mealPlanRepository: widget.mealPlanRepository,
          shoppingListRepository: widget.shoppingListRepository,
          imagePicker: widget.imagePicker,
          currentDateProvider: widget.currentDateProvider,
          entitlementController: widget.entitlementController,
          debugEntitlementSource: widget.debugEntitlementSource,
        ),
      ),
    );
  }
}

class CookbookStartupFailureApp extends StatelessWidget {
  const CookbookStartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookbook',
      debugShowCheckedModeBanner: false,
      theme: cookbookTheme(),
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

ThemeData cookbookTheme() {
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
