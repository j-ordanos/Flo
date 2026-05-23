import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The initialized Supabase client.
///
/// Only valid after `Supabase.initialize` runs in `main()`, which happens when
/// `AppEnv.hasSupabase` is true. Used by auth (P5) and sync (P6).
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);
