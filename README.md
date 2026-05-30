<div align="center">

# 💸 Flo

**Personal finance, simplified.**

Track expenses, set budgets, and understand your money —
offline-first with optional cloud sync.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-optional-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?logo=android)](/)

[**⬇ Download APK**](https://github.com/j-ordanos/Flo/releases/latest/download/app-release.apk) &nbsp;·&nbsp; [Report a Bug](https://github.com/j-ordanos/Flo/issues)

</div>

---

## Demo

<div align="center">
  <video src="res/video/demo.mp4" width="320" controls></video>
  <br/>
  <sub><i>Screen recording of the app in action</i></sub>
</div>

---

## Screenshots

<div align="center">
  <img src="res/screenshots/dashboard.png" width="200" alt="Dashboard" />
  &nbsp;
  <img src="res/screenshots/analytics.png" width="200" alt="Analytics" />
  &nbsp;
  <img src="res/screenshots/budgets.png" width="200" alt="Budgets" />
</div>

---

## Features

- **Expense & Income Logging** — amount keypad, category, date, and optional note
- **Dashboard** — monthly spending, income, balance, and budget health at a glance
- **Category Budgets** — set monthly limits, track remaining, get alerted on overages
- **Analytics** — bar charts and category breakdowns by day, week, or month
- **Receipt Capture** — attach photos to any transaction (requires Supabase)
- **CSV Export** — share reports via the system share sheet
- **Push Notifications** — local budget-overage alerts
- **Offline-first** — all data lives locally; Supabase is optional
- **Cloud Sync** — sign in to sync across devices with conflict-safe merging

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter + Dart |
| State management | Riverpod |
| Navigation | GoRouter |
| Local database | Drift / SQLite |
| Cloud | Supabase (Auth, Postgres, Storage) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |

---

## Getting Started

### 1 — Install dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2 — Run (local-only, no account needed)

```bash
flutter run
```

### 3 — Run with Supabase (accounts + cloud sync)

```bash
cp env/example.json env/dev.json
# Open env/dev.json and fill in your Supabase URL and anon key
flutter run --dart-define-from-file=env/dev.json
```

### 4 — Build a release APK

```bash
bash scripts/build_apk.sh
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

<details>
<summary><b>Supabase — database migrations</b></summary>

Create a Supabase project, open the SQL editor, and run each file in `supabase/migrations/` in order:

1. `0001_initial_schema.sql`
2. `0002_receipts.sql`
3. `0003_transaction_type.sql`
4. `0004_category_kind.sql`

</details>

---

<div align="center">
  <sub>Built with ❤️ using Flutter</sub>
</div>
