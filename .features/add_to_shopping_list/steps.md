# Add To Shopping List: Implementation Steps

Source: [description.md](description.md). Design, criteria, and evidence:
[plan.md](plan.md).

Status: **Blocked.** The user requires Google Keep with personal Google accounts.
Step 1 is a feasibility/decision gate. Steps 2-8 are conditional, not permission
to implement an unsupported integration. Complete one cohesive change at a time.
All checkboxes remain unchecked because planning is not implementation.

## Ordered Checklist

### 1. Resolve The Google Keep Feasibility Gate

- [ ] Establish a supported personal-account integration and append operation.

Requirements: R2, R3, R7, R8. Prerequisites: resolution of B1/B2 in the plan;
explicit permission before any live account test. **Currently blocked:** the
documented API cannot append to an existing note, and personal-account support
has not been established.

Change: obtain official evidence for both capabilities and product confirmation
of checklist eligibility, ingredient notes, duplicate handling, and restoration
defaults. If the requirements must change, seek approval and produce a revised
plan/steps pair without overwriting this pair. Do not change application files.

Tests: no code tests at this decision stage. Only after identifying a documented
supported route and receiving authorization, use a disposable note to test
personal-account authorization, note enumeration, append, denied access, and
preservation of existing items and note identity. Never ask for secrets in chat.

Verification: manually record authoritative links and observed device results.
Completion requires demonstrated personal-account read and append support, or an
approved scope change with replacement steps. If neither is available, stop;
successful sign-in alone or mocked writes do not pass this gate.

### 2. Share Ingredient Formatting

- [ ] Extract and test the ingredient text used for display and export.

Requirements: R2. Prerequisite: step 1 passed with these requirements unchanged.
**Blocked by step 1.**

Change: move the private formatting logic from
[recipe details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart)
to a small shared pure formatter next to the recipe model (proposed component,
not created). Keep the existing display output and immutable ingredient data.

Tests: extend [detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
and add focused formatter cases for whitespace, missing/empty quantity and unit,
fractional/nonnumeric quantities, optional notes, and original ingredient order.

Verification: `flutter test test/features/recipe_catalog`.
Complete when existing display tests pass and exported strings preserve every
provided quantity/unit without changing their meaning or inventing values.

### 3. Implement Account Connection State

- [ ] Add the approved authorization adapter and shared connection owner.

Requirements: R4, R6, R7. Prerequisite: step 1 and approval of any package,
OAuth setup, scopes, and storage changes. **Blocked by step 1.**

Change: introduce a small injectable shopping-list gateway/session component
(proposed new feature components). Compose it through
[app startup](../../lib/main.dart) and
[home](../../lib/app/cookbook_home_screen.dart). Use the approved supported SDK
flow for personal accounts; do not present identity sign-in as Keep permission.
Keep authentication failures isolated from recipe startup. Do not add a new state
framework or embed client secrets/service-account keys in the APK.

Tests: new focused session tests using an injected authorization fake for success,
cancellation, denial, restored sessions, expiry, sign-out, account switches, and
late completions. Verify unavailable/unauthorized states cannot report readiness
and credentials are not persisted as ordinary configuration.

Verification: run the new session test file with `flutter test <test-file>`,
then `flutter test test/app test/widget_test.dart` and `make analyze`.
Complete when state transitions are deterministic and no failed login prevents
offline recipe use. Perform the authorized Android OAuth smoke test separately.

### 4. Load And Persist The Destination

- [ ] Add note enumeration, eligibility checks, and account-scoped selection.

Requirements: R3, R4, R6, R8. Prerequisites: steps 1 and 3.
**Blocked by step 1.**

Change: extend the shopping-list gateway with the supported note-list/read
adapter and a selection metadata store (proposed components), composed in
[app startup](../../lib/main.dart). Handle all pages; retain stable identities;
identify non-trashed writable checklist destinations; persist only non-secret
account/destination metadata in the existing application-support directory.
Revalidate on restoration and clear incompatible selection on account change.

Tests: injected adapter and temporary-directory tests for pagination, empty
results, duplicate/empty titles, malformed responses, denied reads, invalid or
deleted destinations, corrupt metadata, storage failures, restart restoration,
and stale results after account changes. No real credentials in fixtures.

Verification: run the new adapter/store test files with `flutter test <test-file>`
and `make analyze`. Complete when every reachable note is represented correctly,
selection uses identity rather than title, and cached metadata alone never
enables writes. Proposed test-file placeholders must be replaced with the actual
paths when the components are implemented.

### 5. Add The Settings Screen

- [ ] Expose connection and note selection in a separate Settings destination.

Requirements: R4, R5, R7, R8. Prerequisites: steps 3 and 4.
**Blocked by step 1.**

Change: add the proposed Settings screen and a destination in
[home navigation](../../lib/app/cookbook_home_screen.dart), preserving the
IndexedStack pattern and existing Material theme. Connect the account/status,
sign-out, and picker controls to the shared owner. Include loading, empty,
failure, retry, and invalid-selection states without requiring recipe navigation
to configure a destination.

Tests: add focused Settings widget tests with gateway fakes and extend
[home tests](../../test/app/cookbook_home_screen_test.dart). Cover cancellation,
connection failure, note loading/retry, ineligible notes, selection changes,
sign-out, preservation of other destinations, 320-dp width, and 200% text scale.

Verification: run the new Settings test file with `flutter test <test-file>` and
`flutter test test/app/cookbook_home_screen_test.dart`. Complete when the
destination can be configured independently and shared readiness reflects the
configuration without dropping catalog or meal-plan state.

### 6. Implement Non-Destructive Ingredient Append

- [ ] Add the supported write operation behind the shopping-list gateway.

Requirements: R2, R3. Prerequisites: steps 1-4 and a documented append capability
proven at step 1. **Blocked by B1; no such Keep operation is currently documented.**

Change: implement the approved adapter using the shared formatter and captured
account/destination. Preserve note identity, existing content, and checked states;
append one unchecked item per ingredient. Bound writes to the selected account
and note; surface missing permissions, deleted notes, limits, timeouts, partial
completion, and uncertain outcomes. Never delete/recreate notes or blindly retry
an uncertain write. No production fake-success fallback.

Tests: focused gateway tests assert exact strings/order and destination, existing
content preservation, auth failure, note disappearance, account switches, API
limits, concurrent changes, partial failures, and no automatic duplicate writes
after an ambiguous timeout. Add idempotency tests only if the approved API provides
that capability; otherwise verify truthful unknown-outcome reporting.

Verification: run the new gateway tests with `flutter test <test-file>` and
`make analyze`. Completion also requires a separately authorized disposable-note
smoke test confirming real append and unchanged note identity/checked items.
Fakes alone cannot mark this step complete.

### 7. Connect The Recipe-Detail Action

- [ ] Add the enabled/disabled shopping-list button and submission feedback.

Requirements: R1, R2, R6. Prerequisites: steps 2-6.
**Blocked by step 1.**

Change: pass the shared shopping-list dependency through
[catalog navigation](../../lib/features/recipe_catalog/ui/recipe_catalog_screen.dart)
into [recipe details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart).
Add an icon-and-text button by the ingredients, a touch/keyboard/screen-reader
accessible disabled explanation, busy protection, and confirmed success/failure
feedback. Observe changed connection/selection state, capture the intended
destination at submission, and guard asynchronous updates after navigation away.

Tests: extend [detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
for signed-out, no-selection, invalid-selection, ready, and busy states; assert
zero disabled writes, exact payload, one in-flight request, errors and uncertain
outcomes, disconnect while visible, navigation away during submission, tooltip
accessibility, and existing narrow-screen/back-navigation regressions.

Verification: `flutter test test/features/recipe_catalog/ui`.
Complete when only confirmed readiness enables addition, all ingredient data is
sent to the chosen note, and no failure is reported as success.

### 8. Verify The Complete Workflow

- [ ] Add cross-screen regression coverage and run the feature release checks.

Requirements: R1, R2, R3, R4, R5, R6, R7, R8. Prerequisites: steps 1-7.
**Blocked by step 1.**

Change: extend [integration flow](../../integration_test/app_test.dart) and
[home tests](../../test/app/cookbook_home_screen_test.dart) with injected shopping
dependencies. Reuse existing helpers. Automate connect/select/add, destination
change, restoration, disconnect/expired authorization, and failure recovery;
do not put live Google authentication in deterministic CI tests.

Tests: verify all R1-R8 paths together, including catalog and meal-plan state
preservation and compact display/large text. Cross-reference observed outcomes to
the acceptance criteria; do not infer external API success from fake-backed tests.

Verification after focused tests pass:

- `dart format --output=none --set-exit-if-changed lib test integration_test`
- `make analyze`
- `make test`
- `make integration-test DEVICE=<device-id>` on a connected Android test device.
- Hot reload/restart a connected development app and inspect runtime errors.
- With explicit authorization, manually verify personal-account sign-in, real
  note selection, restart restoration, appending, existing item preservation,
  and graceful permission loss using a disposable Google Keep checklist.

Complete only when every criterion passes and required checks have observed
results. Record unavailable device/live-account checks as outstanding. These
commands are planned, not executed by this document. Follow repository review/PR
gates later when applicable; do not commit merely to enable review.
