# Building & sharing Flo

## TL;DR — sharing a test APK with friends

```bash
./scripts/build_apk.sh
```

Then send `build/app/outputs/flutter-apk/app-release.apk` to your testers.

## Why a plain `flutter build apk` breaks login

The Supabase URL and anon key are **compile-time** constants
(`String.fromEnvironment` in [lib/core/config/app_env.dart](lib/core/config/app_env.dart)).
They are read from `env/dev.json` only when you pass `--dart-define-from-file`.

- `flutter run --dart-define-from-file=env/dev.json` → keys present → login/sync work.
- `flutter build apk` (no env file) → keys empty → `AppEnv.hasSupabase` is `false`
  → `Supabase.initialize` is skipped in `main()` → every sign-in/register fails on
  your testers' phones.

`env/dev.json` lives on **your** machine (it's git-ignored). Your testers don't
have it — so the keys must be **baked into the APK at build time**. That's exactly
what `./scripts/build_apk.sh` does.

> The anon key is the public client key (protected by row-level security), so it
> is safe to ship inside the app. The service-role key is never used in the app.

## Everyday commands

| Task                       | Command                                            |
| -------------------------- | -------------------------------------------------- |
| Run on a device/emulator   | `./scripts/run.sh`                                 |
| Release APK (share)        | `./scripts/build_apk.sh`                            |
| App bundle (Play Store)    | `flutter build appbundle --dart-define-from-file=env/dev.json` |

## First-time setup

1. `cp env/example.json env/dev.json`
2. Paste your `SUPABASE_URL` and `SUPABASE_ANON_KEY` into `env/dev.json`.
3. `flutter pub get`
