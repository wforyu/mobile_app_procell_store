import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  /// Android emulator → `10.0.2.2` (localhost host).
  /// Web / iOS / desktop → `localhost`.
  /// Ganti IP ini ke IP komputer di jaringan lokal kalau mau test dari HP fisik.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  static const String appName = 'ProCell Store';
}
