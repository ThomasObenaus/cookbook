import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    CookbookApp(repository: AssetRecipeRepository(assetBundle: rootBundle)),
  );
}

class CookbookApp extends StatelessWidget {
  const CookbookApp({required this.repository, super.key});

  final RecipeRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF365C4A))
        .copyWith(
          primary: const Color(0xFF365C4A),
          secondary: const Color(0xFFB64E33),
          tertiary: const Color(0xFFD29B2D),
          surface: const Color(0xFFFFFBF5),
        );

    return MaterialApp(
      title: 'Cookbook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: RecipeCatalogScreen(repository: repository),
    );
  }
}
