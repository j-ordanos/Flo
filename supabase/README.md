# Flo — Supabase backend

The cloud schema for sync (P6) and auth (P5). Flo stays fully usable offline; the
backend only adds backup + multi-device sync.

## One-time setup
1. Create a project at [supabase.com](https://supabase.com) (free tier is fine).
2. In the dashboard: **SQL Editor → New query**, paste the contents of
   [`migrations/0001_initial_schema.sql`](migrations/0001_initial_schema.sql),
   and **Run**. This creates the tables, indexes, `updated_at` triggers, and
   row-level-security policies.
3. In **Project Settings → API**, copy the **Project URL** and the **anon public**
   key.
4. Locally:
   ```bash
   cp env/example.json env/dev.json   # if you haven't already
   ```
   Put the URL + anon key into `env/dev.json` (git-ignored), then run:
   ```bash
   flutter run --dart-define-from-file=env/dev.json
   ```

## Notes
- **RLS is on** — every row is scoped to `auth.uid()`, so users only ever see
  their own data.
- `updated_at` is server-maintained (authoritative for last-write-wins sync).
- Ids are client-generated UUIDs, so sync is an idempotent upsert.
- `sync_status` is local-only (not stored server-side).
- Email auth works out of the box. For **Google sign-in** (P5), enable the Google
  provider under **Authentication → Providers** and add the OAuth client (we'll
  cover the Android SHA-1 / iOS redirect when we get there).
