/// Build-time configuration injected via
/// `--dart-define-from-file=env/dev.json`.
///
/// Values are empty until the cloud phases (P4/P5). Never hardcode secrets here;
/// `env/` is git-ignored. See `env/example.json` for the expected shape.
abstract final class AppEnv {
  const AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether cloud sync/auth can be initialized.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
