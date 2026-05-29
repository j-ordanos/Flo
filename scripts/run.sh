#!/usr/bin/env bash
# Run Flo in debug with Supabase keys injected. Same as `flutter run` but never
# forgets the env file — without it the app has no cloud config and login fails.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f env/dev.json ]]; then
  echo "error: env/dev.json not found. Copy env/example.json and fill in your keys." >&2
  exit 1
fi

exec flutter run --dart-define-from-file=env/dev.json "$@"
