# Flo

A clean, modern, **local-first** personal expense tracker built with Flutter —
inspired by Monzo and YNAB.

## Tech stack
- **Flutter** (Dart 3.11) · **Riverpod** (state + DI) · **go_router** (navigation)
- **Drift** (local SQLite, reactive) · **Supabase** (Postgres + Auth, cloud sync)
- **fl_chart** (analytics) · **freezed** + codegen · **intl** (formatting)

Architecture: **Clean Architecture**, feature-first (`domain` / `data` /
`presentation`).

## Getting started
```bash
flutter pub get

# Generate code (freezed / riverpod / drift). Run after pulling or editing models:
dart run build_runner build --delete-conflicting-outputs

flutter run
```

## Environment
Cloud features (auth + sync, added in later phases) read config from a
git-ignored `env/dev.json`. Copy the template and fill in your Supabase keys:
```bash
cp env/example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

## Project layout
```
lib/
  core/        # theme, router, constants, config, shared widgets
  features/    # dashboard, expenses, analytics, budgets, profile, auth, onboarding
```
