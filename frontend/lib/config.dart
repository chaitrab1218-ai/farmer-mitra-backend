import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API and environment configuration.
class AppConfig {
  /// Default backend base URL.
  /// After deploying to Render.com, set your live URL here:
  /// e.g. 'https://krushi-mitra-backend.onrender.com'
  static const String defaultApiUrl = 'http://localhost:5000';

  static String _apiUrl = defaultApiUrl;

  /// Current active API base URL without trailing slash
  static String get apiUrl => _apiUrl;

  /// Loads saved custom API URL from local storage (if user configured one in app)
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('custom_backend_url');
    if (saved != null && saved.trim().isNotEmpty) {
      _apiUrl = saved.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// Sets a new backend URL at runtime (persisted in SharedPreferences)
  static Future<void> setApiUrl(String url) async {
    _apiUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_backend_url', _apiUrl);
  }
}
