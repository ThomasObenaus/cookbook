import 'dart:io';

import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:flutter/material.dart';

class RecipeImageView extends StatelessWidget {
  const RecipeImageView({
    required this.image,
    this.fit = BoxFit.cover,
    this.fallbackKey,
    this.fallbackIconSize = 44,
    this.semanticLabel,
    super.key,
  });

  final RecipeImage image;
  final BoxFit fit;
  final Key? fallbackKey;
  final double fallbackIconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final imageWidget = switch (image.kind) {
      RecipeImageKind.asset => Image.asset(
        image.path,
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      ),
      RecipeImageKind.file => Image.file(
        File(image.path),
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      ),
    };
    return imageWidget;
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      key: fallbackKey,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: fallbackIconSize,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: fallback);
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: fallback),
    );
  }
}
