import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String? _overrideBaseUrl;
  static const String _prefKey = 'custom_api_url';

  /// Set the base URL at runtime and persist to storage.
  static Future<void> setBaseUrl(String url) async {
    _overrideBaseUrl = url.isNotEmpty ? url : null;
    final prefs = await SharedPreferences.getInstance();
    if (url.isNotEmpty) {
      await prefs.setString(_prefKey, url);
    } else {
      await prefs.remove(_prefKey);
    }
  }

  /// Load persisted base URL on app start.
  static Future<void> loadPersistedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _overrideBaseUrl = saved;
    }
  }

  /// Current persisted URL (for display in settings).
  static String get currentUrl => _overrideBaseUrl ?? '';

  /// Base URL resolution order:
  /// 1. Runtime/persisted override
  /// 2. Compile-time --dart-define=API_URL=...
  /// 3. Platform defaults
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    const envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:8000/api';
    return 'http://10.0.2.2:8000/api';
  }

  static const String appName = 'ProCell Store';

  static String? imageUrl(String? url) {
    if (url == null) return null;
    final imgUri = Uri.tryParse(url);
    if (imgUri == null || imgUri.host != 'localhost') return url;

    final apiUri = Uri.parse(baseUrl);
    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: imgUri.path,
      query: imgUri.query,
      fragment: imgUri.fragment,
    ).toString();
  }
}
