/// Placeholder owner id used for all locally-created rows until authentication
/// lands (P5). At sign-in, local rows are re-associated with the real user id.
const String kLocalUserId = 'local-user';

/// SharedPreferences key for the "onboarding completed" flag.
const String kOnboardingSeenKey = 'onboarding_seen';

/// SharedPreferences flag: the user chose to use the app locally without an
/// account. Their data lives under [kLocalUserId] and migrates to their account
/// if they sign in later.
const String kGuestModeKey = 'guest_mode';

/// Deep-link the OAuth provider redirects back to (must match the Android
/// intent-filter, iOS URL scheme, and Supabase allowed redirect URLs).
const String kOAuthRedirect = 'com.jordanos.flo://login-callback';

/// Deterministic id for a seeded default category. Stable per (user, kind, icon)
/// so re-seeding across installs/logins is idempotent — upsert/insert-or-ignore
/// collapse onto the same row instead of creating duplicates. [kind] is part of
/// the key because expense and income can share an icon (e.g. "other").
String defaultCategoryId(String userId, String kind, String icon) =>
    'cat_${userId}_${kind}_$icon';
