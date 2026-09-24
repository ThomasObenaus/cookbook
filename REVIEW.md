## Findings

### LOW

None.

### MEDIUM

- **Dismiss planner feedback when changing destinations**: [`_showShoppingMessage`](lib/features/meal_planner/ui/weekly_meal_planner_screen.dart#L398) posts through the shared ancestor `ScaffoldMessenger` while the planner remains mounted in the home [`IndexedStack`](lib/app/cookbook_home_screen.dart#L59). After adding a week, switching destinations leaves the four-second SnackBar over the new screen, where it can intercept lower-screen taps; the integration flow currently avoids this by [waiting five seconds](integration_test/app_test.dart#L122). Dismiss the message on destination changes or scope it to the planner.

### HIGH

None.

## Title

Expand shopping list management and planner additions

## summary

Add completed-item grouping, persisted reordering and editing, confirmed clearing, and planner-wide ingredient batching to the local shopping list. Extend repository and controller contracts, shared home wiring, documentation, and focused unit, widget, and Android integration coverage.

### Why

Make the offline shopping list easier to maintain and let users add every ingredient from the displayed meal-planner week in one operation.
