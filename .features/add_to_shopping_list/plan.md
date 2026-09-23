# Add Recipe Ingredients To Google Keep

Source: [description.md](description.md). Execution checklist: [steps.md](steps.md).

Status: **Blocked on integration feasibility; not ready for implementation.**
Planning date: 2026-09-23. The user confirmed Google Keep and personal Google
accounts. No alternative service or reduced workflow has been approved.

## Goal And Scope

Let an Android Cookbook user connect a personal Google account in a separate
settings screen, select an existing Google Keep checklist, and append a recipe's
ingredients, including quantities and units, from recipe details.

The first increment includes connection, note selection, remembered configuration,
the add action, and truthful disabled/error states. It does not include ingredient
aggregation, serving scaling, automatic shopping-list creation, offline queuing,
editing shopping items inside Cookbook, or other platforms. These are scope
assumptions, not additional approved requirements.

## Requirements And Acceptance Criteria

Criteria below describe the requested result, not currently available behavior.

| ID  | Requirement                        | Observable acceptance criterion                                                                                                                                                                                          | Steps      |
| --- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| R1  | Recipe-detail action               | Every recipe detail screen exposes an accessible "Add to shopping list" button.                                                                                                                                          | 7, 8       |
| R2  | Complete ingredient transfer       | One successful press appends one unchecked item per ingredient, in recipe order, preserving name, quantity and unit when supplied. Existing items remain unchanged.                                                      | 2, 6, 7, 8 |
| R3  | Dedicated Google Keep list         | Additions reach the selected existing Keep checklist, retaining its identity and existing content; another note is not silently created or substituted.                                                                  | 1, 4, 6, 8 |
| R4  | Configurable destination           | The user can choose and change the destination. The selection is associated with the connected account and restored after restart only after revalidation.                                                               | 3, 4, 5, 8 |
| R5  | Separate settings screen           | An independently navigable Settings screen contains connection and destination controls; returning does not discard recipe search or meal-plan state.                                                                    | 5, 8       |
| R6  | Disabled action with explanation   | Without an authorized account and a valid selected destination, the add button is gray and non-actionable, makes no write request, and exposes the specific reason through an accessible tooltip/information affordance. | 3, 4, 7, 8 |
| R7  | Personal Google account connection | Settings can initiate supported Google authorization, show the connected identity, and handle cancellation, denied permission, expiry, and sign-out without claiming success.                                            | 1, 3, 5, 8 |
| R8  | Browse notes after connection      | After authorization, Settings displays the user's available notes, including subsequent pages, in a picker/list. It supports selection of an eligible checklist and has loading, empty, failure, and retry states.       | 1, 4, 5, 8 |

## Current Implementation

- [Recipe and Ingredient](../../lib/features/recipe_catalog/models/recipe.dart)
  are immutable data models. Ingredient quantity, unit, and note are optional
  strings; quantities may be nonnumeric. Do not introduce numeric conversion.
- [Recipe details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart)
  currently renders ingredients and method without actions or external state.
  Its private formatter trims and joins quantity, unit, and name and appends an
  optional ingredient note in parentheses.
- [Detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
  cover full data, absent quantity/unit, "to taste", back navigation, and a
  320-dp screen at 200% text scaling. Extend these rather than duplicating them.
- [Catalog navigation](../../lib/features/recipe_catalog/ui/recipe_catalog_screen.dart)
  constructs the detail route with only a recipe. It is the path through which
  the shopping-list dependency must reach details.
- [Home navigation](../../lib/app/cookbook_home_screen.dart) uses StatefulWidget,
  setState, an IndexedStack, and Recipes/Meal plan destinations. There is no
  Settings destination in this shell.
- [App composition](../../lib/main.dart) creates and injects local repositories
  using an application-support directory. Reuse this composition pattern for
  shopping-list dependencies and non-secret selection metadata.
- [Dependencies](../../pubspec.yaml) contain no Google authorization or Keep API
  client. Existing path_provider can supply the metadata storage directory; it
  is not a credential store. Package choices require separate approval.
- [Makefile](../../Makefile) provides strict analysis, unit/widget coverage, and
  device-based Android integration checks.

## Proposed Design

Everything in this section is conditional on the feasibility gates below. A
passing fake-backed UI is not proof of a working Google Keep integration.

### Data And State

Introduce a small shopping-list feature with an injectable `ShoppingListGateway`
for account connection, listing destinations, checking a destination, and
appending items. These are application contracts, **not existing Keep endpoints**.
Do not build a multi-provider framework or add a backend speculatively.

Keep one shared session/selection owner at the home composition boundary, passed
explicitly through the catalog to details and to Settings. Follow existing
StatefulWidget/setState conventions; use a small notifier only if required for
an already-open route to observe connection changes. No new state framework.

Represent signed-out, connecting, selecting, ready, and unavailable states
explicitly. Derive readiness from current authorization, confirmed write
capability, and a valid destination, not merely a saved note ID. Account changes,
sign-out, deleted notes, and revoked permissions invalidate readiness. Ignore
stale responses from a previous account or selection; guard async UI updates
after disposal.

Persist only account identity and destination identity/display metadata in
application-support storage. Restore authorization through the approved SDK and
revalidate saved selections. Corrupt configuration should require reselection,
not prevent recipes from loading. Keep tokens in an approved SDK/platform-secure
store; never store passwords, service-account keys, or tokens in ordinary JSON,
logs, fixtures, or the repository.

### Settings And Selection

Add a Settings destination to the existing navigation shell using Material icons
and the established theme. The screen shows connection status, a connect/sign-out
control, and a note picker after authorization. Distinguish authorization from
simple identity sign-in. Paginate notes, distinguish equal/empty titles, and
surface failures without losing the user's current valid selection.

Proposed eligibility rule: only existing, non-trashed, writable checklist notes
can be selected. Display other returned notes as ineligible with a reason; do not
silently convert text notes. This rule needs product confirmation. Changing the
selection persists its stable identity, not an array index or title.

### Ingredient Transfer And Detail Action

Extract the existing ingredient formatter into one shared pure function and
reuse it for display and export. Preserve string quantities, units, ordering,
and the currently displayed optional notes. Missing values must not become
"null", fabricated quantities, or extra separators.

Place an icon-and-text add button near the ingredients. Provide an independent
information affordance so the disabled explanation remains available by touch,
keyboard, and screen reader. Examples include "Connect a Google account in
Settings" and "Choose a shopping list in Settings". Do not enable it when the
integration is unsupported, even if identity sign-in succeeds.

One press captures the current account/destination and ingredient snapshot, then
awaits confirmed completion. Prevent overlapping submissions and show progress
and success/failure feedback. Keep existing list content and checked states
untouched; append new unchecked items. A later deliberate press may add the same
ingredients again; deduplication is not part of this increment.

Do not blindly retry writes after a timeout or partial result. Report an unknown
outcome and require reconciliation if the eventual approved API cannot guarantee
idempotence. Account switches must never redirect an in-flight operation to the
new account. Do not emulate append by deleting and recreating a note.

## Dependencies And Feasibility

Official documentation inspected on 2026-09-23:

1. [Keep API overview](https://developers.google.com/workspace/keep/api/guides)
   describes enterprise-administrator use and domain-wide delegation using a
   service account or OAuth client ID. An OAuth client ID alone does not establish
   a supported consumer-account authorization route.
2. [Keep notes REST resource](https://developers.google.com/workspace/keep/api/reference/rest/v1/notes)
   exposes create, delete, get, and list methods, but no update/patch/append
   operation. Its list-item representation does not itself provide a write API
   for an existing note.
3. [Keep Java quickstart](https://developers.google.com/workspace/keep/api/guides/java)
   includes Workspace administrator/domain-wide-delegation setup. Although its
   prerequisites mention a Google account and its sample uses OAuth, it does not
   resolve the consumer-access question raised by the overview. Do not mistake
   this Java sample for a verified Flutter/Android personal-account integration.
4. [List notes reference](https://developers.google.com/workspace/keep/api/reference/rest/v1/notes/list)
   documents pagination and Keep OAuth scopes. This describes API behavior for
   authorized callers, not proof of access for personal accounts.

**B1: confirmed API capability blocker.** The documented API has no operation to
append ingredients to the selected existing note (R2/R3). Choosing a sign-in
package, enabling the API, or moving requests to a backend does not supply that
missing operation.

**B2: unresolved personal-account support.** No supported end-to-end personal
Google account authorization flow has been established by the inspected sources
(R7/R8). This needs explicit official support evidence and an authorized device
proof, not an assumption based on ordinary Google sign-in.

The release gate requires both issues resolved with official documentation and a
non-destructive Android proof using an explicitly authorized personal test
account and a disposable note. Until then, do not install integration packages,
configure credentials, or start production feature implementation. Do not request
passwords/tokens through chat. Any later package additions, architecture changes,
OAuth client configuration, scopes, and verification requirements need agreement
after a viable approach exists.

Alternatives requiring explicit requirement changes, none approved:

- Investigate Google Tasks as a different shopping-list service.
- Investigate Android sharing to Keep as a user-mediated export, without promising
  automatic append, account configuration, or preselection of an existing note.
- Defer the feature until a supported Keep capability is available.

These alternatives have not been validated here. Unofficial APIs, scraping,
embedded credentials, and delete/recreate workarounds are outside this plan.

## Validation Strategy

- First validate B1/B2. Automated fakes cannot satisfy this gate. Do not run a
  write against a user's real shopping list as a feasibility experiment.
- Unit tests: ingredient formatting, account-scoped persistence, readiness,
  pagination, invalid destinations, stale responses, and append failure mapping.
- Widget tests: settings navigation and all connection/picker states; disabled
  button semantics and explanation; payload/destination selection; busy and
  failure states; 320-dp layouts and 200% text scaling.
- Extend [home tests](../../test/app/cookbook_home_screen_test.dart),
  [detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart),
  and [integration flow](../../integration_test/app_test.dart). Use injected
  fakes, never live personal Google credentials, for automated runs.
- Run focused tests first, then `dart format --output=none --set-exit-if-changed lib test integration_test`,
  `make analyze`, `make test`, and `make integration-test DEVICE=<device-id>` after
  implementation. The integration command needs a connected Android device.
- Hot reload/restart a connected development app after Dart changes and inspect
  runtime errors. A separate authorized manual Keep smoke test must verify
  sign-in, list selection, restart restoration, real append, and preservation of
  existing checked items. Keep-only failures must not break recipe access.

No application tests, live account requests, or implementation checks have been
run as part of this planning task.

## Assumptions And Open Questions

- Confirmed: Google Keep, personal Google accounts. Android is inferred from the
  current application's platform and dependency metadata.
- Blocking: what supported approach can satisfy B1 and B2 without changing the
  requirements? None has been identified. If none exists, approve an alternative
  or defer; do not execute the conditional implementation steps.
- Proposed defaults: existing checklists only; preserve ingredient notes; append
  without aggregation; allow duplicates on separate deliberate presses; remember
  one account-scoped destination. Confirm these before implementation.
- No new dependency, backend, unofficial API, or alternative service is approved
  by this plan. The original description remains unchanged.
