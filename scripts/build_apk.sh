#!/usr/bin/env bash
# Build a release APK to share for testing.
#
# IMPORTANT: the Supabase URL/key are compile-time values (String.fromEnvironment).
# They must be injected at BUILD time with --dart-define-from-file, otherwise the
# installed app has no cloud config and every login/register fails. A plain
# `flutter build apk` produces exactly that broken APK — always use this script.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f env/dev.json ]]; then
  echo "error: env/dev.json not found. Copy env/example.json and fill in your keys." >&2
  exit 1
fi

flutter build apk --release --dart-define-from-file=env/dev.json "$@"

echo
echo "Built: build/app/outputs/flutter-apk/app-release.apk"
echo "Send that file to your testers. It has the Supabase keys baked in, so"
echo "sign-in/sync works on any device without env/dev.json."
