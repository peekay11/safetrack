/// Backend base URL. Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-worker.workers.dev
///
/// Defaults to the `wrangler dev` local address. Note that on the Android
/// emulator "localhost" refers to the emulator itself, not your host
/// machine — use 10.0.2.2 there, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  /// Resolves an R2-backed media path (e.g. `/uploads/selfies/...` from the
  /// verification endpoints) into an absolute URL against the backend.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl$path';
  }
}
