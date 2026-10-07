# Free vs Paid Mode: Increment 1 Implementation Plan

## Goal

Establish the application structure that distinguishes free local use from a
future paid sharing entitlement, without changing where cookbook data is stored:

- explain local use and future sharing once, on first launch;
- let the user start using a local cookbook with no account, payment, or
  network request;
- remember that choice across launches;
- add a Settings destination that reports the current cookbook and sharing
  status;
- model sharing entitlement as explicit typed states behind an injected source;
  and
- show an honest, disabled `Invite members` preview.

All recipes, meal plans, shopping-list items, and images remain local and
unchanged. No user can purchase anything in this increment.

## Agreed Decisions

- Implement the entitlement foundation only. Real Google Play Billing and
  Supabase authentication move to a later increment.
- Add no new dependencies. The increment uses `dart:io`, `path_provider`, and
  the existing Flutter test tooling already present in the project.
- Keep `StatefulWidget` and `setState` for widget state, and use a
  `ChangeNotifier` controller for shared entitlement state, matching
  `ShoppingListController`.
- Persist onboarding completion as versioned JSON written atomically through a
  temporary file and rename, matching `LocalMealPlanRepository`.
- Inject the entitlement source so tests never depend on billing, network, or
  real time.
- Ship a production entitlement source that reports sharing as unavailable.
  This is truthful while no paid feature exists.
- Expose a debug-only entitlement simulator so every state can be inspected on a
  device. Exclude it from release builds.
- Add Settings as a fourth `NavigationBar` destination rather than duplicating a
  settings action in each screen's app bar.
- Treat onboarding as a one-time gate, not a prompt shown on every launch.
- Derive the `Invite members` explanation from entitlement state, but keep the
  control disabled in all states.
- Inject a clock so expiration logic is deterministic, reusing the existing
  `CurrentDateProvider` convention.

## Deferred to a Later Increment

These were considered for this increment and are deliberately postponed. The
entitlement source abstraction is the seam they will plug into.

| Deferred work | Reason |
| --- | --- |
| Google Play Billing integration | No paid feature exists yet to justify a purchase. |
| Supabase authentication and Google sign-in | A purchase must bind to a stable account, which is only needed once purchases exist. |
| Supabase Edge Function purchase verification | Server-side verification belongs with the billing flow it protects. |
| Google Play Developer API verification | Same as above. |
| Purchase acknowledgement and restoration | Only meaningful with real purchases. |
| Real-time Developer Notifications | Required before a public subscription release, not before a foundation. |
| Persisted entitlement cache across restarts | Depends on a real verified entitlement; in-session continuity is sufficient now. |

The production entitlement source added here reports
`sharingUnavailable`. The billing increment replaces it with a verified source
without changing the controller, settings UI, or gating rules.

## Scope

### Included

- A one-time onboarding screen with a local-use action and a sharing
  explanation.
- Durable, versioned storage of onboarding completion.
- A startup gate that chooses onboarding or the existing cookbook shell.
- A typed sharing entitlement model covering every documented state.
- An injected entitlement source contract with production, debug, and test
  implementations.
- An entitlement controller that loads on start, refreshes on resume, ignores
  stale results, and preserves a known entitlement when verification fails.
- A Settings destination showing cookbook storage, sharing status, expiration,
  and a retry action.
- A disabled `Invite members` preview whose explanation depends on entitlement
  state.
- A debug-only state simulator.
- Updates to existing composition, widget, and integration tests affected by the
  new startup path and fourth destination.
- README documentation of free local use and the deferred paid sharing.

### Excluded

- Purchasing, restoring, or verifying any subscription.
- Supabase clients, authentication, schema, or network calls of any kind.
- Creating, owning, converting, or uploading a shared cookbook.
- Invitations, membership, and owner/member roles.
- Switching between local and shared cookbooks.
- Persisting an entitlement cache across app restarts.
- Changing any existing local repository contract or stored data format.
- Changing the behavior of the Recipes, Meal plan, or Shopping list screens.

## User Experience

### First Launch

1. The app shows a `Welcome to Cookbook` screen instead of the cookbook shell.
2. It explains that recipes are stored on this device and need no account.
3. It states that sharing a cookbook with family is planned and will require a
   subscription for the cookbook owner.
4. `Use locally for free` records the choice and opens the existing Recipes
   destination.
5. `Learn about sharing` opens an explanation that clearly says sharing is not
   available yet. It must not start any purchase.
6. No Supabase or billing call occurs at any point.

### Later Launches

- The app opens directly on the Recipes destination.
- Onboarding is never shown again unless stored preferences are missing or
  unreadable.
- Unreadable preferences are treated as a first launch rather than a crash.

### Settings

A fourth destination labeled `Settings` shows two sections.

**This cookbook**

- `Local cookbook`
- An explanation that data is stored on this device and works offline.

**Sharing**

- The current sharing status.
- The expiration date when an entitlement is cancelled but still active.
- A `Retry` action when verification is unavailable.
- A disabled `Invite members` control.

Status presentation per state:

| State | Settings text | Invite preview explanation |
| --- | --- | --- |
| `unknown` | Checking sharing status | Checking sharing status |
| `sharingUnavailable` | Sharing is not available yet | Sharing is coming in a future update |
| `notEntitled` | No sharing subscription | Requires a sharing subscription |
| `purchasePending` | Purchase is being processed | Requires a sharing subscription |
| `active` | Sharing subscription active | Invitations are not available yet |
| `cancelledUntilExpiration` | Active until <date> | Invitations are not available yet |
| `gracePeriod` | Payment problem, access continues | Invitations are not available yet |
| `onHold` | Subscription on hold | Requires an active sharing subscription |
| `expired` | Sharing subscription expired | Requires an active sharing subscription |
| `verificationUnavailable` | Sharing status could not be checked | Explanation of the last known state |

The `Invite members` control is disabled in every state. It must never be an
enabled control that does nothing.

### Debug Simulator

In debug builds only, Settings exposes `Simulate sharing state`. It lists the
entitlement states and applies the selected one to the injected debug source.
It is absent from release builds and performs no persistence.

## Data Design

### Entitlement Status

An exhaustive enum covering the states documented in the feature description:

```text
unknown
sharingUnavailable
notEntitled
purchasePending
active
cancelledUntilExpiration
gracePeriod
onHold
expired
verificationUnavailable
```

### Sharing Entitlement

An immutable value:

- `status`: required `EntitlementStatus`.
- `expiresAt`: optional UTC timestamp, required for
  `cancelledUntilExpiration` and `gracePeriod`.
- `lastKnownStatus`: optional, set only for `verificationUnavailable`.

Validated factories enforce these invariants so the UI cannot render a
cancellation without an expiration date.

One derived rule owns the gating decision:

```dart
bool allowsSharingOwnership(DateTime now);
```

It returns `true` only for `active`, `gracePeriod`, and
`cancelledUntilExpiration` whose `expiresAt` is still in the future. For
`verificationUnavailable` it evaluates `lastKnownStatus` using the same rule.

No other code may infer entitlement from status text or booleans.

### App Preferences

Versioned JSON in the existing application support directory, beside the current
cookbook files:

```text
cookbook/
  app_preferences.json
```

```json
{
  "schemaVersion": 1,
  "onboardingCompletedAt": "2026-10-07T12:00:00Z"
}
```

- Validate the schema version, types, and timestamp format.
- Treat a missing file as a first launch.
- Treat malformed content as a first launch and overwrite it on the next write,
  because no user content is stored here.
- Write to `app_preferences.json.tmp` and rename into place.
- Never store entitlement secrets, purchase tokens, or account identifiers.

## Architecture

```text
lib/
  app/
    cookbook_app.dart
    cookbook_home_screen.dart
    startup_gate.dart
  features/
    sharing/
      data/
        app_preferences_store.dart
        entitlement_source.dart
      logic/
        entitlement_controller.dart
      models/
        entitlement_status.dart
        sharing_entitlement.dart
      ui/
        onboarding_screen.dart
        settings_screen.dart
        invite_preview_tile.dart
  main.dart
test/
  app/
    startup_gate_test.dart
  features/
    sharing/
      data/
        app_preferences_store_test.dart
      logic/
        entitlement_controller_test.dart
      models/
        sharing_entitlement_test.dart
      ui/
        onboarding_screen_test.dart
        settings_screen_test.dart
      fake_entitlement_source.dart
      fake_app_preferences_store.dart
```

### Responsibilities

- `main.dart` stays the composition root. It resolves the support directory,
  builds the preferences store and production entitlement source, and injects
  them. It gains no feature logic.
- `cookbook_app.dart` receives the extracted `CookbookApp` and theme so startup
  gating is testable without `main.dart`. Move only what is required.
- `StartupGate` renders onboarding or `CookbookHomeScreen` from already-loaded
  preferences. It performs no file access itself.
- `EntitlementController` extends `ChangeNotifier`, owns the current
  entitlement, and guards against overlapping and stale refreshes.
- `EntitlementSource` exposes one method, `Future<SharingEntitlement> fetch()`.
- `AppPreferencesStore` owns JSON validation and atomic writes.
- `SettingsScreen` and `OnboardingScreen` render state and raise intent only.

The entitlement source must not expose speculative `purchase`, `restore`, or
`acknowledge` methods. Those arrive with the billing increment.

## State Handling

`EntitlementController` rules:

- One in-flight refresh at a time; concurrent calls are ignored, not queued.
- Each refresh carries a generation counter; results from a superseded
  generation are discarded.
- A successful fetch replaces the entitlement.
- A failed fetch produces `verificationUnavailable` carrying the previous known
  status, so an active user is never silently downgraded to expired, and a user
  with no entitlement is never silently upgraded to active.
- `dispose` suppresses later notifications, matching `ShoppingListController`.

`CookbookHomeScreen` refreshes the controller when the app resumes, using
`WidgetsBindingObserver`. Register in `initState` and remove in `dispose`.

## Impact on Existing Code and Tests

This increment changes app startup and the primary navigation, so existing tests
need updating. Treat these as part of the work, not as incidental breakage:

- `CookbookApp` gains an injected preferences snapshot and entitlement
  controller, so every existing construction site must be updated:
  - `test/widget_test.dart`
  - `test/app/cookbook_home_screen_test.dart` helper `_testApp`
  - `integration_test/app_test.dart`
- `cookbook_home_screen_test.dart` asserts `selectedIndex` values and taps
  destinations by label. Adding a fourth destination must leave indices 0, 1,
  and 2 unchanged; verify these assertions still hold.
- `widget_test.dart` counts occurrences of `Recipes`; confirm the new
  destination does not change those counts.
- The integration test must start with onboarding already completed so the
  existing persistence journey is unaffected, plus a separate assertion for the
  first-launch path.
- `createCookbookApp` already converts startup failure into
  `CookbookStartupFailureApp`. Preference-loading failure must not bypass that
  behavior; an unreadable preferences file is a first launch, while an
  unavailable support directory remains a startup failure.

## Implementation Steps

1. **Add the entitlement model**
   - Implement `EntitlementStatus` and immutable `SharingEntitlement` with
     validated factories.
   - Implement `allowsSharingOwnership` including the
     `verificationUnavailable` delegation.
   - Add unit tests for every state, expiration boundaries, and rejected
     invalid combinations.

2. **Add the preferences store**
   - Implement versioned JSON read and atomic write.
   - Define behavior for missing, malformed, and unsupported-version files.
   - Convert file errors into a typed exception that preserves cause and stack
     trace.
   - Add a fake in-memory store for widget and controller tests.

3. **Add the entitlement source contract**
   - Define `EntitlementSource` with a single `fetch` method.
   - Add the production implementation returning `sharingUnavailable`.
   - Add a debug-only mutable implementation for the simulator.
   - Add a configurable fake for tests, including failure injection.

4. **Add the entitlement controller**
   - Implement load, refresh, generation guarding, failure fallback, and
     disposal.
   - Test success, failure with and without a prior entitlement, overlapping
     refreshes, stale results, and post-dispose notification suppression.

5. **Add the onboarding screen**
   - Build the explanation, `Use locally for free`, and `Learn about sharing`.
   - Persist completion before leaving the screen and handle a write failure
     with a visible, retryable message.
   - Verify no billing or network call is reachable from this screen.

6. **Add the startup gate**
   - Extract `CookbookApp` and the theme into `lib/app/cookbook_app.dart`,
     moving only what gating requires.
   - Load preferences in `createCookbookApp` and inject the result.
   - Render onboarding or the cookbook shell, preserving the existing startup
     failure behavior.

7. **Add the Settings destination**
   - Add the fourth `NavigationBar` destination with a stable value key.
   - Build the cookbook and sharing sections from controller state.
   - Add the retry action for `verificationUnavailable`.
   - Confirm existing destination indices and state preservation are unchanged.

8. **Add the invite preview**
   - Render a disabled control with state-derived explanatory text.
   - Assert it is disabled in every entitlement state.

9. **Add the debug simulator**
   - Gate strictly on `kDebugMode`.
   - Apply a selected state through the debug source and refresh the controller.
   - Assert its absence in a non-debug configuration.

10. **Refresh on resume**
    - Observe lifecycle changes in `CookbookHomeScreen`.
    - Refresh on resume and remove the observer on dispose.

11. **Update existing tests and documentation**
    - Update the three existing `CookbookApp` construction sites.
    - Add first-launch and returning-user integration coverage.
    - Update the README with free local use and the deferred paid sharing.

12. **Validate**
    - `dart format lib test integration_test`
    - Focused tests for the new model, store, controller, onboarding, settings,
      and startup gate.
    - `make test`, because startup composition and navigation changed.
    - `make analyze`
    - `make integration-test` on the configured emulator.
    - `flutter build apk --debug`, then manually verify first launch, restart,
      Settings, and the debug simulator.

## Test Plan

### Unit Tests

- Every `EntitlementStatus` maps to the documented gating result.
- `cancelledUntilExpiration` allows ownership before `expiresAt` and denies it
  afterwards, including the exact boundary.
- `cancelledUntilExpiration` and `gracePeriod` without `expiresAt` are rejected.
- `verificationUnavailable` delegates to `lastKnownStatus`.
- Preferences round-trip, reject an unsupported `schemaVersion`, treat malformed
  JSON as a first launch, and write atomically.
- A preferences write failure surfaces a typed exception.
- The controller discards stale generations and ignores concurrent refreshes.
- A failed refresh preserves a prior `active` status instead of reporting
  `expired`.
- A failed refresh with no prior entitlement does not report `active`.

### Widget Tests

- A first launch shows onboarding rather than the cookbook shell.
- `Use locally for free` persists completion and shows Recipes.
- A completed onboarding opens Recipes directly.
- A persistence failure during onboarding is visible and retryable.
- Settings reports `Local cookbook` and the correct text for each entitlement
  state.
- The expiration date is shown for `cancelledUntilExpiration`.
- `Retry` is offered only for `verificationUnavailable` and triggers one
  refresh.
- `Invite members` is present and disabled in every state.
- The debug simulator is absent outside debug mode.
- Screens remain usable at 320 dp width and 200% text scale.

### Integration Tests

- First launch shows onboarding; choosing local use opens Recipes, and the
  existing recipe, meal-plan, and shopping-list journeys still pass.
- App recreation after onboarding opens Recipes directly with all previously
  saved local data intact.
- Entering Settings and returning preserves catalogue and planner state.

No test may contact Google Play, Supabase, or any network service.

## Acceptance Criteria

- A new user reaches a working local cookbook without authentication, payment,
  or a network request.
- The onboarding choice survives app restarts.
- Existing local recipes, meal plans, shopping-list items, and images remain
  unchanged.
- Settings identifies the cookbook as local and explains that invitations
  require future paid sharing.
- Entitlement is represented by the documented typed states, with no
  user-writable paid-mode toggle.
- Gating decisions derive solely from `allowsSharingOwnership`.
- A failed verification never silently changes an entitled user to expired or an
  unentitled user to active.
- The `Invite members` control is disabled in every state and performs no
  action.
- No purchase can be initiated anywhere in the app.
- The debug simulator is unreachable in release builds.
- Formatting, focused tests, the full test suite, strict analysis, Android
  integration tests, and a debug APK build all pass.
