/// Placeholder owner id used for all locally-created rows until authentication
/// lands (P5). At sign-in, local rows are re-associated with the real user id.
const String kLocalUserId = 'local-user';

/// SharedPreferences key for the "onboarding completed" flag.
const String kOnboardingSeenKey = 'onboarding_seen';

/// Deep-link the OAuth provider redirects back to (must match the Android
/// intent-filter, iOS URL scheme, and Supabase allowed redirect URLs).
const String kOAuthRedirect = 'com.jordanos.flo://login-callback';
