Yes. That is a practical architecture and probably the best fit for this app.

## Proposed model

### Free mode

- No account required
- No Supabase connection
- Recipes, meal plans, shopping list, and images remain on the device
- Works completely offline
- No sharing between users or devices
- Optional manual export/backup later

```text
Free user
    ↓
Flutter app
    ↓
Local application storage
```

The app can continue using its existing local repositories.

### Paid sharing mode

- User purchases sharing
- User signs in, for example with Google
- Local cookbook is uploaded to your Supabase project
- Owner can invite other users
- Shared data is stored in Supabase
- Members see changes made by other members

```text
Paid owner and invited members
            ↓
       Supabase Auth
            ↓
Your Supabase project
├── cookbooks
├── cookbook_members
├── recipes
├── meal plans
├── shopping items
└── recipe images
```

## Prefer one app, not separate free and paid apps

I recommend distributing one Android application with two modes:

```text
Cookbook
├── Local cookbook
└── Shared cookbook
```

The application decides which repositories to use based on the active cookbook.

Conceptually:

```dart
abstract interface class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe> createRecipe(NewRecipe recipe);
}
```

Implementations:

```text
LocalRecipeRepository
SupabaseRecipeRepository
```

Your current application already uses repository abstractions, which is a good foundation for this.

A separate paid app would cause problems:

- Android keeps the two applications’ data in separate sandboxes
- Migrating local recipes becomes difficult
- Users could accidentally install both versions
- Links and invitations must choose the correct application
- You would maintain two Play Store listings and package IDs

One app with an entitlement is simpler.

## Possible user journey

### Initial use

```text
Welcome to Cookbook

[Use locally for free]
[Enable sharing]
```

Choosing local mode opens the existing cookbook immediately. It should not require sign-in.

### Later upgrade

A free user selects:

```text
Settings
└── Share this cookbook
```

The flow becomes:

1. Explain the paid sharing feature.
2. Complete the purchase or subscription.
3. Sign in with Google.
4. Create an owned cookbook in Supabase.
5. Upload existing local recipes and associated data.
6. Confirm that migration succeeded.
7. Switch the active cookbook to shared mode.
8. Allow invitations.

Do not delete the local data until the cloud migration has been verified. Prefer retaining a recoverable local backup for a defined period.

## Paid owner versus invited users

A good family-oriented pricing model is:

> The cookbook owner pays; invited family members join for free.

For example:

```text
Alice owns Family Cookbook
├── Alice: paid owner
├── Bob: invited member, no payment required
└── Carol: invited member, no payment required
```

Bob and Carol can use:

- Their own free local cookbook
- Alice’s shared cookbook

They only need to pay if they want to create and share a cookbook of their own.

This maps naturally to your rule:

> A user can own at most one shared cookbook.

A database constraint can enforce this:

```sql
create table cookbooks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id),
  name text not null
);
```

The unique owner ID prevents one account from owning multiple shared cookbooks.

## Switching between cookbooks

An invited user might see:

```text
My cookbooks

On this device
- My local cookbook

Shared with me
- Alice's Family Cookbook
- Weekend Cooking Group
```

If users may only own one cookbook but join multiple cookbooks, the distinction should be:

- One local cookbook
- Zero or one owned shared cookbook
- Any number of invited shared cookbooks

Each shared cookbook uses the same Supabase project but has a different `cookbook_id`.

## What remains local in paid mode?

There are two reasonable approaches.

### Online-first

The paid/shared cookbook reads and writes directly to Supabase.

**Advantages**

- Simpler first implementation
- Fewer synchronization problems

**Disadvantages**

- Limited offline behavior
- Every operation needs connectivity

### Local-first with synchronization

The shared cookbook keeps a local database and synchronizes with Supabase, potentially using PowerSync later.

**Advantages**

- Works offline
- Fast local UI
- Existing local-first behavior is preserved

**Disadvantages**

- More complex
- Requires conflict and synchronization rules

I recommend starting online-first while preserving the repository interfaces, then introducing PowerSync as a separate increment if offline shared editing is important.

The free local cookbook remains fully offline either way.

## Migrating the local cookbook

Upgrading should be treated as a real migration, not merely switching repositories.

A safe migration flow is:

1. Create the remote cookbook.
2. Assign stable IDs to every local record.
3. Upload recipes.
4. Upload ingredients and steps.
5. Upload recipe images.
6. Upload meal plans.
7. Upload shopping-list entries, if sharing those is intended.
8. Verify record counts and references.
9. Mark the local cookbook as linked to the remote cookbook.
10. Retain a local backup until successful synchronization is confirmed.

The migration must be resumable. If image 15 of 20 fails, retrying should not duplicate the first 14.

## Payment enforcement

The Flutter UI can decide whether to show the upgrade screen, but Flutter alone cannot securely verify payment.

For robust Google Play subscriptions:

```text
Flutter app
    ↓ purchase token
Supabase Edge Function
    ↓ verifies purchase with Google Play
subscriptions table
    ↓
Database permits shared cookbook ownership
```

This does not require a separately operated backend. The Edge Function runs within your Supabase project.

If you do not want any server-side purchase verification, alternatives are:

- Manually grant owner entitlements
- Publish a separately paid app, with the disadvantages above
- Initially treat sharing as free for selected/test users
- Accept weaker client-side Play Billing enforcement

For a production paid feature, server-side verification is recommended.

## Database authorization

Payment should control **ownership**, while membership controls **access**.

For example:

- `subscriptions`: whether the user may own a shared cookbook
- `cookbooks`: owner and cookbook metadata
- `cookbook_members`: who can access each cookbook
- RLS policies: whether the current user can access each row

Invited members do not receive access because they paid. They receive access because they have a valid membership.

## If the subscription expires

A user-friendly policy would be:

- Stop new invitations
- Stop adding new shared content after a grace period
- Keep existing data readable
- Allow export
- Do not immediately delete anything
- Restore normal editing after renewal

Invited members inherit the owner cookbook’s subscription state.

## Recommendation

Use one Android application with:

```text
Free tier
├── No login
├── Local device storage
├── Fully offline
└── No sharing

Paid sharing tier
├── Google login
├── One owner per cookbook
├── Invited members join free
├── Data in your Supabase project
└── RLS isolates cookbooks
```

This keeps Supabase costs limited to people actually using sharing, preserves a useful no-account free version, and provides a clear reason to upgrade.
