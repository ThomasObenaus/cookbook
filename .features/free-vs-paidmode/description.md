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

Establish the application states, onboarding, settings, and test subscription
infrastructure needed for future paid sharing without changing where cookbook
data is stored. All cookbook data remains local in this increment.

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
  - exposes an upgrade or subscription test entry point;
  - exposes purchase restoration when test billing is enabled;
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
- Define injected entitlement and billing boundaries so widget and controller
  tests do not contact Google Play or Supabase.
- Preserve all existing local repositories and local data.
- Ensure a purchase, cancellation, or entitlement-state change never uploads,
  deletes, or silently relinks local cookbook data.
- Configure any real Google Play product used by this increment as an internal
  test product only. Do not make the subscription publicly purchasable.

If end-to-end Google Play Billing is implemented in this increment, it must also
include:

- Supabase authentication before starting or restoring a purchase;
- Google Play purchase and restore handling;
- server-side verification through a Supabase Edge Function;
- verification through the Google Play Developer API;
- binding each purchase token to one Supabase user;
- server-controlled entitlement persistence;
- purchase acknowledgement after successful verification;
- refresh on application start and resume; and
- explicit handling of pending, cancelled, grace-period, on-hold, expired,
  revoked, and temporarily unverifiable subscriptions.

Client-side Google Play state alone must not grant an entitlement. Real-time
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
- A user without an entitlement sees the test upgrade entry point when billing
  testing is enabled.
- An active test entitlement is shown accurately but does not imply that local
  data has moved to Supabase.
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
- A pending or failed test purchase never grants an active entitlement.
- When end-to-end billing is included, an active entitlement is granted only
  after server-side Google Play verification.
- Cancelling automatic renewal retains the entitlement until the verified
  expiration time.
- Temporary verification failure does not silently change an active user to
  expired or an unpaid user to active.
- Purchase restoration, when billing testing is enabled, binds the verified
  purchase to the authenticated Supabase user.
- No production user can be charged while shared cookbook functionality remains
  unavailable.

## Later Increments

1. Create the Supabase shared-cookbook schema, authentication, membership, and
   Row-Level Security policies.
2. Let an entitled user convert a local cookbook into their one owned shared
   cookbook through a resumable and verifiable migration.
3. Add owner-created invitations and invitation acceptance for members who do
   not need their own subscription.
4. Add switching between the local cookbook, the owned shared cookbook, and
   invited shared cookbooks.
5. Add offline synchronization for shared cookbooks if required.
