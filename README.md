# Flo

Flo is a Flutter personal finance app for tracking expenses, income, category
budgets, and spending trends.

The app is local-first: transactions, categories, and budgets are stored in a
local Drift/SQLite database and the core app works without a network account.
When Supabase keys are provided at build time, Flo also enables sign-in,
cloud sync, and receipt storage.

## Current Functionality

- Log expenses and income with an amount keypad, category, date, and optional
  note.
- View, edit, and delete transactions from a detail screen.
- Attach receipt images to transactions when signed in with Supabase.
- Seed default expense and income categories, then create or edit your own
  categories.
- Track the current month from the dashboard with spending, income, balance,
  budget health, and recent transactions.
- Create monthly category budgets and see total usage, remaining budget, days
  left, and over-budget states.
- Review analytics by day, week, or month with bar charts, category breakdowns,
  income-vs-spending totals, and CSV export through the system share sheet.
- Manage profile preferences such as currency, dark mode, notifications,
  budget alerts, category settings, CSV export, and sign-in/sign-out.
- Use the app as a guest/local account, then migrate local data to a Supabase
  account after sign-in.
- Sync categories, expenses, and budgets through Supabase with pending local
  edits protected from being overwritten by older remote data.
- Receive local budget-overage notifications when push notifications and budget
  alerts are enabled.

## Current Limits

- Goal tracking is not implemented yet, even though onboarding currently
  references future saving goals.
- Password reset shows a placeholder message.
- Google sign-in requires Supabase OAuth and platform redirect/deep-link setup.
- Receipt upload requires the Supabase `receipts` storage bucket and policies
  from the provided migrations.

## Tech Stack

- Flutter and Dart
- Riverpod for state management and dependency injection
- GoRouter for nested shell navigation and auth/onboarding redirects
- Drift with SQLite for local reactive storage
- Supabase Auth, Postgres, and Storage for optional cloud features
- `fl_chart` for analytics charts
- `csv` and `share_plus` for report export
- `flutter_local_notifications` for budget alerts
- `image_picker` for receipt capture and gallery selection

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Generate the Drift, DAO, and Freezed files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run locally without Supabase:

```bash
flutter run
```

In this mode, Flo stores data locally and skips auth/sync.

## Supabase Setup

Supabase is optional, but required for accounts, multi-device sync, and receipt
uploads.

1. Create a Supabase project.
2. Run every SQL file in `supabase/migrations` in order:
   `0001_initial_schema.sql`, `0002_receipts.sql`,
   `0003_transaction_type.sql`, and `0004_category_kind.sql`.
3. Copy `env/example.json` to `env/dev.json`.
4. Add your Supabase project URL and anon public key to `env/dev.json`.
5. Run the app with the env file:

```bash
flutter run --dart-define-from-file=env/dev.json
```

On Windows PowerShell, the copy step is:

```powershell
Copy-Item env/example.json env/dev.json
```

The anon key is the public client key. Do not put a Supabase service-role key in
the app.

## Sharing a Test APK

The Supabase values are compile-time constants, so release builds need the env
file passed during build:

```bash
flutter build apk --release --dart-define-from-file=env/dev.json
```

If you are using Git Bash or another Bash shell, the helper script does the same
thing:

```bash
./scripts/build_apk.sh
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Testing

Run the test suite with:

```bash
flutter test
```

## Project Layout

- `lib/main.dart` initializes Flutter, optional Supabase, preferences, default
  categories, notifications, sync triggers, and the app router.
- `lib/core` contains routing, theme, constants, shared widgets, providers,
  money formatting, and the Drift database.
- `lib/features/expenses` contains transaction models, repositories, CSV export,
  receipt upload, add/edit UI, and transaction detail UI.
- `lib/features/categories` contains default category seeding, category
  management, icons, and category pickers.
- `lib/features/budgets` contains category budget models, repositories,
  providers, and budget UI.
- `lib/features/analytics` contains the analytics screen, period filters, charts,
  category totals, and export actions.
- `lib/features/auth` contains Supabase email/password auth, Google OAuth entry
  points, guest mode, and local-data migration after sign-in.
- `lib/features/sync` contains Supabase push/pull sync and conflict handling.
- `lib/features/notifications` contains local notification setup and budget
  alert delivery.
- `lib/features/profile` contains user/account display and app preferences.
- `supabase/migrations` contains the backend schema, RLS policies, receipt
  storage setup, and schema updates needed by the app.
