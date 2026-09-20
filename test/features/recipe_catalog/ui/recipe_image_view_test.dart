import 'dart:io';

import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a local recipe image from a file', (tester) async {
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;

    await tester.pumpWidget(
      MaterialApp(home: RecipeImageView(image: RecipeImage.file(imagePath))),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<FileImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('configures missing local images with the shared fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 150,
          child: RecipeImageView(
            image: RecipeImage.file('/missing/recipe.jpg'),
            fallbackKey: const ValueKey<String>('missing-image-fallback'),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<FileImage>());
    expect(image.errorBuilder, isNotNull);
  });
}
