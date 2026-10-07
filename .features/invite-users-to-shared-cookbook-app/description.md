The user should be able to invite other users to join the shared cookbook.

For the online persistence Supabase shall be used.
The user should be able to persist his cookbook online in supabase.
Such a user becomes the cookbook owner.
A cookbook owner has the ability to invite other users to join the shared cookbook. Invited users will receive an invitation and can join the shared cookbook upon accepting it. Users that use the cookbook in invitation mode can't invite other users.
There should be a clear distinction between the cookbook owner and invited users in the user interface.
It should be possible for the users to switch between different cookbooks they have access to.

1. the ones they were invited to
2. the one they own.

A user always can only be owner of one cookbook.

# first increment

- when the app starts and the user has not yet connected to a supabase account, then the user should be prompted to connect to their supabase account.
- the app should check if the connection is successful and inform the user accordingly.
- if the connection was successful the app persists the connection information.
- but in any case the user is prompted to login to their supabase account if needed on followup application starts
- the application should not persist the full login credentials of the user.
