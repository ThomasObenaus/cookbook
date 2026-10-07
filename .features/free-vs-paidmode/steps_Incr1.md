# Free vs Paid Mode: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all of its tasks and
its focused check are checked.

## 1. Add the Entitlement Domain Model

- [x] Create an exhaustive `EntitlementStatus` value with:
  `unknown`, `sharingUnavailable`, `notEntitled`, `purchasePending`, `active`,
  `cancelledUntilExpiration`, `gracePeriod`, `onHold`, `expired`, and
  `verificationUnavailable`.
- [x] Create an immutable `SharingEntitlement` value with status, optional
  expiration, and optional last-known status.
- [x] Validate that `cancelledUntilExpiration` and `gracePeriod` require a
  future-capable expiration timestamp.
- [x] Validate that `verificationUnavailable` carries a last-known status when
  one exists and never presents a fresh active entitlement by accident.
- [x] Implement `allowsSharingOwnership(DateTime now)` as the only ownership
  entitlement decision.
- [x] Allow ownership only for active, grace-period, and not-yet-expired
  cancelled states.
- [x] Evaluate `verificationUnavailable` from its last-known state without
  turning an unavailable check into a new entitlement.
- [x] Add unit tests for every status, expiration boundary, invalid
  combinations, and immutable values.
- [x] Run the focused model tests:

```bash
flutter test test/features/sharing/models
```

## 2. Add Durable App Preferences

- [x] Define a small preferences model containing onboarding completion.
- [x] Store preferences in `cookbook/app_preferences.json` below the application
  support directory.
- [x] Validate schema version, required fields, and timestamp format.
- [x] Treat a missing preferences file as first launch.
- [x] Treat malformed or unsupported preferences as first launch and preserve
  the existing local cookbook data.
- [x] Write preferences through a temporary file and atomic rename.
- [x] Clean up a failed temporary write without replacing the last valid file.
- [x] Convert filesystem failures into a typed exception with a friendly
  message, cause, and stack trace.
- [x] Never store purchase tokens, Supabase credentials, account identifiers, or
  entitlement secrets in preferences.
- [x] Add an in-memory fake preferences store for widget and integration tests.
- [x] Test missing, valid, malformed, unsupported, round-trip, and failed-write
  behavior.
- [x] Run the focused preferences tests:

```bash
flutter test test/features/sharing/data/app_preferences_store_test.dart
```

## 3. Add the Entitlement Source Boundary

- [ ] Define `EntitlementSource` with only the fetch operation needed by this
  increment.
- [ ] Do not add purchase, restore, acknowledge, Google Play, or Supabase
  methods to the interface.
- [ ] Implement the production source to report `sharingUnavailable`, because
  no paid feature exists yet.
- [ ] Implement a configurable fake source with success and failure results.
- [ ] Implement a debug-only mutable source for exercising all entitlement
  states on a device.
- [ ] Ensure the debug source cannot be selected in release builds.
- [ ] Add tests that verify production loading performs no network operation.
- [ ] Add tests covering fake success and failure injection.
- [ ] Run the focused source tests:

```bash
flutter test test/features/sharing/data
```

## 4. Implement the Entitlement Controller

- [ ] Create an entitlement controller using `ChangeNotifier`, following the
  existing `ShoppingListController` lifecycle pattern.
- [ ] Expose the current entitlement, loading state, and user-facing error
  state.
- [ ] Load the initial entitlement through the injected source.
- [ ] Allow only one refresh request at a time.
- [ ] Add a generation or request identity to discard stale asynchronous
  results.
- [ ] Preserve the previous known entitlement when a refresh fails.
- [ ] Represent a failed refresh as `verificationUnavailable` rather than
  silently reporting `expired` or `active`.
- [ ] Suppress notifications after disposal.
- [ ] Clear transient errors before a retry.
- [ ] Test initial success, initial failure, retry, overlapping refreshes, stale
  results, previous-state fallback, and post-dispose completion.
- [ ] Run the focused controller tests:

```bash
flutter test test/features/sharing/logic
```

## 5. Add First-Launch Onboarding

- [ ] Create an onboarding screen titled `Welcome to Cookbook`.
- [ ] Explain that local use needs no account, payment, or network.
- [ ] Explain that future sharing will require a subscription for the cookbook
  owner.
- [ ] Add `Use locally for free`.
- [ ] Add `Learn about sharing`.
- [ ] Make local use the clear default path into the existing cookbook.
- [ ] Make the sharing explanation explicit that sharing is not available in
  this increment.
- [ ] Persist onboarding completion before leaving the screen.
- [ ] Keep the existing local repositories and data untouched.
- [ ] Show a retryable error if preference persistence fails.
- [ ] Ensure this screen cannot start billing, authentication, Supabase, or
  network work.
- [ ] Test first-launch rendering, local-use completion, sharing explanation,
  persistence failure, and retry.
- [ ] Run the focused onboarding tests:

```bash
flutter test test/features/sharing/ui/onboarding_screen_test.dart
```

## 6. Add the Startup Gate

- [ ] Extract the existing app composition into a testable app-shell location
  only as far as startup gating requires.
- [ ] Keep `main.dart` responsible for initialization and dependency
  composition, not feature behavior.
- [ ] Resolve the application support directory once and inject the preferences
  store.
- [ ] Load preferences before selecting the initial screen.
- [ ] Render onboarding when completion is absent.
- [ ] Render the existing cookbook shell after onboarding is complete.
- [ ] Treat malformed preferences as first launch.
- [ ] Preserve `CookbookStartupFailureApp` when support-directory initialization
  fails.
- [ ] Keep startup errors controlled and user-visible.
- [ ] Update every `CookbookApp` construction site with the new dependencies.
- [ ] Test first launch, completed onboarding, malformed preferences, and
  support-directory failure.
- [ ] Run the focused startup tests:

```bash
flutter test test/app/startup_gate_test.dart
```

## 7. Add the Settings Destination

- [ ] Add a fourth `Settings` destination to the existing `NavigationBar`.
- [ ] Keep Recipes, Meal plan, and Shopping list at indices 0, 1, and 2.
- [ ] Add a stable key for the Settings destination and screen.
- [ ] Show a `Local cookbook` section with an offline-storage explanation.
- [ ] Show a Sharing section driven by the entitlement controller.
- [ ] Display the documented text for every entitlement state.
- [ ] Display the expiration date for `cancelledUntilExpiration`.
- [ ] Offer `Retry` only when verification is unavailable.
- [ ] Make retry use the controller rather than directly invoking the source.
- [ ] Preserve existing destination state when switching to and from Settings.
- [ ] Test navigation, local status, all entitlement states, expiration display,
  retry behavior, and existing destination indices.
- [ ] Run the focused Settings and app-shell tests:

```bash
flutter test test/features/sharing/ui test/app/cookbook_home_screen_test.dart
```

## 8. Add the Disabled Invitation Preview

- [ ] Add an `Invite members` control to Settings.
- [ ] Keep it visibly disabled in every entitlement state.
- [ ] Explain that invitations are unavailable in this increment.
- [ ] Use distinct explanatory text for unavailable, expired, and active
  simulated states where that improves clarity.
- [ ] Ensure tapping or activating the disabled control cannot mutate state,
  navigate, or start network work.
- [ ] Add a stable key and semantic label.
- [ ] Test disabled behavior and explanatory text for every state.

## 9. Add the Debug Entitlement Simulator

- [ ] Expose `Simulate sharing state` only when `kDebugMode` is true.
- [ ] List every entitlement state in a testable control.
- [ ] Apply the selected state through the debug source and refresh the
  controller.
- [ ] Allow expiration timestamps to be deterministic in tests through the
  injected clock.
- [ ] Do not persist simulated state across launches.
- [ ] Confirm no simulator control is present in a release configuration.
- [ ] Test state selection, controller refresh, expiration rendering, and
  release exclusion.

## 10. Refresh Entitlement State on Resume

- [ ] Observe app lifecycle changes from the existing app shell.
- [ ] Refresh the entitlement controller when the app resumes.
- [ ] Avoid refreshing on every widget rebuild or navigation change.
- [ ] Remove the lifecycle observer during disposal.
- [ ] Ignore completion after disposal.
- [ ] Test resume-triggered refresh, duplicate resume protection, and disposal.

## 11. Update Existing App Tests and Integration Coverage

- [ ] Update `test/widget_test.dart` to complete or bypass onboarding through
  injected preferences.
- [ ] Update `test/app/cookbook_home_screen_test.dart` helpers with the new
  preferences and entitlement dependencies.
- [ ] Update `integration_test/app_test.dart` so the existing persistence
  journey starts after onboarding.
- [ ] Add an integration journey for first launch and `Use locally for free`.
- [ ] Verify app recreation opens directly on Recipes after onboarding.
- [ ] Verify local recipes, meal plans, shopping-list items, and images remain
  available after recreation.
- [ ] Verify Settings can be opened and closed without losing catalogue,
  planner, or shopping-list state.
- [ ] Verify no test contacts Google Play, Supabase, or a network service.
- [ ] Run the focused app and integration tests:

```bash
flutter test test/widget_test.dart test/app/cookbook_home_screen_test.dart
flutter test integration_test/app_test.dart
```

## 12. Update Documentation and Complete Validation

- [ ] Update `README.md` with the free local mode and the deferred paid sharing
  model.
- [ ] Document that real Google Play Billing, Supabase Auth, and server-side
  purchase verification belong to a later increment.
- [ ] Document that no user can be charged in this increment.
- [ ] Confirm the feature description and this steps file agree on scope.
- [ ] Run Dart formatting:

```bash
dart format lib test integration_test
```

- [ ] Run strict static analysis:

```bash
make analyze
```

- [ ] Run the complete unit and widget test suite:

```bash
make test
```

- [ ] Run the Android integration journey:

```bash
make integration-test DEVICE=emulator-5554
```

- [ ] Build the debug APK:

```bash
flutter build apk --debug
```

- [ ] Manually verify first launch, local onboarding, app restart, Settings,
  disabled invitations, and the debug simulator on the configured emulator.
- [ ] Confirm no Google Play, Supabase, billing, or network dependency was
  introduced accidentally.
- [ ] Confirm every acceptance criterion in
  [plan_Incr1.md](plan_Incr1.md#acceptance-criteria).
- [ ] If the implementation is committed in `main...HEAD`, complete the
  repository review workflow.
