## Findings

### LOW

None.

### MEDIUM

- **Suppress delayed planner feedback after a tab switch**: [`_selectDestination`](lib/app/cookbook_home_screen.dart#L50) hides only a SnackBar that already exists. If the user switches tabs while [`addIngredients` is still pending](lib/features/meal_planner/ui/weekly_meal_planner_screen.dart#L384), the retained planner posts its feedback after completion through the shared messenger, so it still appears over the new destination and can intercept taps. The regression test waits for completion before switching; cover the in-flight case and scope or suppress feedback when the planner is inactive.

### HIGH

None.

## Title

Expand shopping list management and planner additions

## summary

Add completed-item grouping, persisted reordering and editing, confirmed clearing, and planner-wide ingredient batching to the local shopping list. Extend repository and controller contracts, shared home wiring, documentation, and focused unit, widget, and Android integration coverage.

### Why

Make the offline shopping list easier to maintain and let users add every ingredient from the displayed meal-planner week in one operation.
