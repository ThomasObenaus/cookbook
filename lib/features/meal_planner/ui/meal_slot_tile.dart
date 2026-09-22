import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:flutter/material.dart';

class MealSlotTile extends StatelessWidget {
  const MealSlotTile({
    required this.date,
    required this.mealType,
    this.recipe,
    this.isUnavailable = false,
    this.isMutating = false,
    this.onTap,
    super.key,
  });

  final DateTime date;
  final MealType mealType;
  final Recipe? recipe;
  final bool isUnavailable;
  final bool isMutating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assignmentLabel = switch ((recipe, isUnavailable)) {
      (final Recipe recipe, _) => recipe.name,
      (null, true) => 'Recipe unavailable',
      (null, false) => 'Add ${mealType.label.toLowerCase()}',
    };
    final semanticsLabel =
        '${formatCalendarDate(date)}, ${mealType.label}, $assignmentLabel'
        '${isMutating ? ', saving' : ''}';

    return Semantics(
      button: onTap != null && !isMutating,
      onTap: isMutating ? null : onTap,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: isMutating ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 56,
                      child: _SlotLeading(
                        mealType: mealType,
                        recipe: recipe,
                        isUnavailable: isUnavailable,
                        isMutating: isMutating,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            mealType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            assignmentLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) ...<Widget>[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotLeading extends StatelessWidget {
  const _SlotLeading({
    required this.mealType,
    required this.recipe,
    required this.isUnavailable,
    required this.isMutating,
  });

  final MealType mealType;
  final Recipe? recipe;
  final bool isUnavailable;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget content;
    if (recipe != null) {
      content = RecipeImageView(
        image: recipe!.image,
        fallbackIconSize: 28,
        fit: BoxFit.cover,
      );
    } else {
      content = ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            isUnavailable ? Icons.link_off : _mealIcon(mealType),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          content,
          if (isMutating)
            ColoredBox(
              color: colorScheme.surface.withValues(alpha: 0.78),
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _mealIcon(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => Icons.free_breakfast_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.dinner_dining_outlined,
  };
}
