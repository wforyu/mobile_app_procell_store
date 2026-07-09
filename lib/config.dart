import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  /// Android emulator → ganti ke `10.0.2.2`.
  /// Web / iOS / desktop → `localhost`.
  /// HP fisik di jaringan LAN → pake IP komputer (misal `192.168.100.7`).
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    return 'http://192.168.100.7:8000/api';
  }

  static const String appName = 'ProCell Store';

  /// Normalize image URL from API to match the API base URL's origin.
  ///
  /// Local dev: `http://localhost:8000/storage/...` → `http://10.0.2.2:8000/storage/...`
  /// (emulator), or stays `http://localhost:8000/...` (web).
  ///
  /// Production: stays as-is (`https://procell-store.com/storage/...`).
  /// External URLs (non-localhost) are never modified.
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
