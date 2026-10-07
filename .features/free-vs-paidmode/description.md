The cookbook app should have both a free mode and a paid mode.
In the free mode:

- the users data is persisted only locally on the device
- he cannot invite other users to join a shared cookbook

In the paid mode:

- the users data is persisted online in Supabase
- he can invite other users to join a shared cookbook

## First Increment

- setup of the needed google play services for handling subscriptions and supabase if needed
- On application start the user is prompted to "Use locally for free" or "Upgrade to paid mode to invite users"
- Add a settings page to allow switching between free and paid modes
- In paid mode show an invite to share the cookbook with other users option in the settings page (for now that button does nothing)
- In free mode the option to invite other users disabled but still visible, a hint should be given that upgrading to the paid mode is required to use this feature.
- when the user cancels its subscription (leaves paid mode) then the option to invite other users should be disabled and a hint should be given that upgrading to the paid mode is required to use this feature.
- Handling of the subscription process via google play
- Handling of the subscription check via google play (is the user currently subscribed)

### Out of scope

- persisting recipes in supabase
- Handling of user invitations to shared cookbooks
- migrations of the database schema related to recipes and shared cookbooks
- Handling of switching between free and paid modes related to user data and invitations
