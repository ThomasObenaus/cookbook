import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/ui/weekly_meal_planner_screen.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:flutter/material.dart';

class CookbookHomeScreen extends StatefulWidget {
  const CookbookHomeScreen({
    required this.recipeRepository,
    required this.mealPlanRepository,
    required this.imagePicker,
    required this.currentDateProvider,
    super.key,
  });

  final MutableRecipeRepository recipeRepository;
  final MealPlanRepository mealPlanRepository;
  final RecipeImagePicker imagePicker;
  final CurrentDateProvider currentDateProvider;

  @override
  State<CookbookHomeScreen> createState() => _CookbookHomeScreenState();
}

class _CookbookHomeScreenState extends State<CookbookHomeScreen> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          RecipeCatalogScreen(
            repository: widget.recipeRepository,
            imagePicker: widget.imagePicker,
          ),
          WeeklyMealPlannerScreen(
            recipeRepository: widget.recipeRepository,
            mealPlanRepository: widget.mealPlanRepository,
            currentDateProvider: widget.currentDateProvider,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey<String>('cookbook-primary-navigation'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Meal plan',
          ),
        ],
      ),
    );
  }
}
