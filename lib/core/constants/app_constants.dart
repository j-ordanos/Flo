import 'package:uuid/uuid.dart';

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

/// Namespace for deterministic category UUIDs (any fixed valid UUID works).
const String _kCategoryNamespace = '6f9619ff-8b86-d011-b42d-00c04fc964ff';

/// Deterministic id for a seeded default category. Stable per (user, kind, icon)
/// so re-seeding across installs/logins is idempotent — upsert/insert-or-ignore
/// collapse onto the same row instead of creating duplicates. [kind] is part of
/// the key because expense and income can share an icon (e.g. "other").
///
/// Must be a valid UUID: the Supabase `categories.id` column is type `uuid`, so
/// a plain string id (the old `cat_<user>_<kind>_<icon>`) is rejected on sync
/// with "invalid input syntax for type uuid". A v5 UUID is both valid and
/// deterministic.
String defaultCategoryId(String userId, String kind, String icon) =>
    const Uuid().v5(_kCategoryNamespace, '${userId}_${kind}_$icon');

/// True if [id] is a syntactically valid UUID (so it's safe to push to a `uuid`
/// column). Used to migrate legacy non-UUID category ids.
bool isValidUuid(String id) => _uuidPattern.hasMatch(id);

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
