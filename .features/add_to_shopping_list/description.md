# In-App Shopping List

The user should be able to add the ingredients of a recipe to a shopping list
inside the app.

## First Increment

- The recipe detail screen has an "Add to shopping list" button.
- Pressing it adds all recipe ingredients, including their quantity and unit when provided, to the app's shopping list.
- A dedicated Shopping list view is accessible from the app's main navigation.
- No Google Keep integration, account login, list selection, or integration settings screen is required. The feature works offline.

## Proposed Defaults

- Use one shopping list, stored locally and retained after restarting the app.
- Users can check/uncheck purchased items and remove individual items.
- Preserve ingredient order and optional notes. Existing entries remain intact; adding another recipe appends its ingredients as unchecked entries.
- Do not merge duplicate ingredients or convert units. Adding the same recipe again intentionally appends another set of entries.
- Show loading, empty, and recoverable error states. Report a successful addition only after it has been saved, and prevent repeated presses while saving.
- Manual item creation/editing, multiple lists, sharing, synchronization, and bulk clearing are outside this increment.

Current planning documents: [plan1.md](plan1.md) and [steps1.md](steps1.md).
The earlier plan and steps describe the superseded Google Keep approach.
