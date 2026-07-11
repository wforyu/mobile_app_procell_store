import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String? _overrideBaseUrl;

  /// Set the base URL at runtime (e.g. from a settings screen or env).
  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
  }

  /// Base URL resolution order:
  /// 1. Runtime override (setBaseUrl)
  /// 2. Compile-time --dart-define=API_URL=...
  /// 3. Platform defaults
  static String get baseUrl {
    if (_overrideBaseUrl != null) return _overrideBaseUrl!;

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
