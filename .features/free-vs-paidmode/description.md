# Free Local Cookbooks and Paid Sharing

The Cookbook app supports free local use and, in a later increment, paid
sharing through the application's Supabase project.

These concepts are independent and must not be represented by one `isPaidMode`
flag:

- **Cookbook storage:** a cookbook is either local to the device or shared
  through Supabase.
- **Sharing entitlement:** an authenticated user may or may not be entitled to
  own one shared cookbook.
- **Cookbook role:** a user can be the owner or an invited member of a shared
  cookbook.

An invited member does not need a subscription to use an owner's shared
cookbook. A user needs an active sharing entitlement only to own a shared
cookbook and invite members. A user can own at most one shared cookbook but may
join multiple shared cookbooks.

## Free Local Use

- No account or subscription is required.
- Recipes, meal plans, shopping-list items, and images are stored only on the
  device.
- Local cookbook functionality works offline and does not contact Supabase.
- A local cookbook cannot be shared and cannot invite members.
- The user can learn about or start an upgrade from Settings.

## Paid Sharing

- The cookbook owner pays for the sharing entitlement.
- Invited members can use the owner's shared cookbook without purchasing their
  own subscription.
- Shared cookbook data is persisted in the application's Supabase project.
- Supabase Auth identifies owners and invited members.
- Row-Level Security and cookbook membership determine access to shared data.
- Subscription state controls whether a user may own a shared cookbook and
  invite members.
- Cancelling renewal does not immediately remove the entitlement. Access
  remains active until the verified paid period expires.

The paid sharing experience, shared data persistence, and invitations are
delivered in later increments. A production subscription must not be sold until
the application provides usable paid functionality.

## First Increment: Entitlement Foundation

### Goal

Establish the application states, onboarding, and settings needed for future
paid sharing without changing where cookbook data is stored. All cookbook data
remains local in this increment, and no purchase is possible.

### Included

- On first launch, explain the two future usage models:
  - `Use locally for free`
  - `Learn about sharing`
- Make local use the default and allow it without authentication, payment, or a
  Supabase request.
- Persist completion of onboarding so the choice is not requested on every app
  launch.
- Add a Settings page that:
  - identifies the current cookbook as local;
  - explains that local cookbooks cannot invite members;
  - explains that sharing is planned and will require an owner subscription;
  - shows the current entitlement status; and
  - shows an `Invite members` preview that is disabled with honest explanatory
    text.
- Introduce typed entitlement states rather than a manually writable paid-mode
  boolean:
  - unknown;
  - not entitled;
  - purchase pending;
  - active;
  - cancelled but active until expiration;
  - grace period;
  - on hold;
  - expired;
  - verification unavailable.
- Define an injected entitlement source so widget and controller tests do not
  contact Google Play or Supabase, and so real billing can replace it later
  without changing the controller, settings UI, or gating rules.
- Provide a debug-only way to exercise every entitlement state on a device, and
  exclude it from release builds.
- Preserve all existing local repositories and local data.
- Ensure an entitlement-state change never uploads, deletes, or silently
  relinks local cookbook data.
- Add no purchase flow. No user can be charged anywhere in the app.

### Deferred to a Later Increment

Real purchasing is deliberately not part of this increment, because no paid
feature exists yet. The following work moves to the increment that introduces
shared cookbooks:

- Google Play Billing integration;
- Supabase authentication before starting or restoring a purchase;
- Google Play purchase and restore handling;
- server-side verification through a Supabase Edge Function;
- verification through the Google Play Developer API;
- binding each purchase token to one Supabase user;
- server-controlled entitlement persistence;
- purchase acknowledgement after successful verification; and
- explicit handling of revoked and refunded subscriptions.

The injected entitlement source added in this increment is the seam that the
billing work plugs into. Its production implementation reports that sharing is
unavailable, which is accurate while no paid feature exists.

Client-side Google Play state alone must never grant an entitlement. Real-time
Developer Notifications, or an equivalent authoritative server-side refresh
strategy, are required before subscriptions are released publicly.

### User Experience

#### First Launch

1. The user sees a concise explanation of local use and future sharing.
2. `Use locally for free` opens the existing cookbook without sign-in or
   network access.
3. `Learn about sharing` explains the planned owner-paid model. It must not
   start a production purchase while sharing is unavailable.
4. Completing or dismissing onboarding is persisted.

#### Settings

- A local user sees `Local cookbook` and an explanation that the data remains on
  this device.
- A user without an entitlement sees an explanation that sharing is planned, not
  a purchase action.
- A simulated active entitlement is shown accurately but does not imply that
  local data has moved to Supabase.
- A cancelled subscription remains active until its verified expiration time,
  which is displayed.
- Pending, grace-period, on-hold, expired, and verification-unavailable states
  have distinct messaging and actions.
- `Invite members` remains disabled and is labeled as unavailable in this
  increment. It must not be an enabled no-op button.

### Out of Scope

- Selling or publicly releasing the production sharing subscription.
- Creating or owning a shared cookbook.
- Converting, uploading, or synchronizing a local cookbook.
- Persisting recipes, meal plans, shopping-list items, or images in Supabase.
- Creating the Supabase schema for shared cookbook domain data.
- PowerSync or any other offline synchronization service.
- Creating, sending, accepting, declining, or revoking invitations.
- Owner and invited-member workflows.
- Switching between local, owned shared, and invited shared cookbooks.
- Enforcing subscription status against shared cookbook data.
- Changing or deleting existing local cookbook data when entitlement state
  changes.

## Acceptance Criteria for the First Increment

- A new user can choose local use without authentication, payment, or a network
  request.
- The onboarding decision survives application restarts.
- Existing local recipes, meal plans, shopping-list items, and images remain
  available and unchanged.
- Settings clearly identifies the current cookbook as local.
- Settings explains that invitations require future paid sharing.
- The invitation preview is disabled and does not perform an action.
- Entitlement state is represented by the documented typed states, not by a
  user-controlled paid-mode toggle.
- Cancelling automatic renewal retains the entitlement until its expiration
  time.
- Temporary verification failure does not silently change an active user to
  expired or an unpaid user to active.
- No purchase can be started anywhere in the app, so no user can be charged
  while shared cookbook functionality remains unavailable.

## Later Increments

1. Add Google Play Billing, Supabase authentication, and server-side purchase
   verification so a sharing entitlement can be purchased and trusted.
2. Create the Supabase shared-cookbook schema, membership, and Row-Level
   Security policies.
3. Let an entitled user convert a local cookbook into their one owned shared
   cookbook through a resumable and verifiable migration.
4. Add owner-created invitations and invitation acceptance for members who do
   not need their own subscription.
5. Add switching between the local cookbook, the owned shared cookbook, and
   invited shared cookbooks.
6. Add offline synchronization for shared cookbooks if required.
