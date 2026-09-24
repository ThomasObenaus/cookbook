import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/ui/weekly_meal_planner_screen.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/logic/shopping_list_controller.dart';
import 'package:cookbook/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:flutter/material.dart';

class CookbookHomeScreen extends StatefulWidget {
  const CookbookHomeScreen({
    required this.recipeRepository,
    required this.mealPlanRepository,
    required this.shoppingListRepository,
    required this.imagePicker,
    required this.currentDateProvider,
    super.key,
  });

  final MutableRecipeRepository recipeRepository;
  final MealPlanRepository mealPlanRepository;
  final ShoppingListRepository shoppingListRepository;
  final RecipeImagePicker imagePicker;
  final CurrentDateProvider currentDateProvider;

  @override
  State<CookbookHomeScreen> createState() => _CookbookHomeScreenState();
}

class _CookbookHomeScreenState extends State<CookbookHomeScreen> {
  int _selectedIndex = 0;
  late final ShoppingListController _shoppingList;

  @override
  void initState() {
    super.initState();
    _shoppingList = ShoppingListController(
      repository: widget.shoppingListRepository,
    );
    _shoppingList.load();
  }

  @override
  void dispose() {
    _shoppingList.dispose();
    super.dispose();
  }

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
            onAddIngredients: _shoppingList.appendIngredients,
          ),
          WeeklyMealPlannerScreen(
            recipeRepository: widget.recipeRepository,
            mealPlanRepository: widget.mealPlanRepository,
            currentDateProvider: widget.currentDateProvider,
            shoppingListListenable: _shoppingList,
            isShoppingListAvailable: () =>
                _shoppingList.loaded && !_shoppingList.busy,
            onAddIngredients: _shoppingList.appendIngredients,
          ),
          ShoppingListScreen(controller: _shoppingList),
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
          NavigationDestination(
            key: ValueKey<String>('shopping-list-destination'),
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Shopping list',
          ),
        ],
      ),
    );
  }
}
