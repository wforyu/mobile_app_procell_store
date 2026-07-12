import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String? _overrideBaseUrl;
  static const String _prefKeyUser = 'custom_api_url';
  static const String _prefKeyServer = 'server_api_url';

  /// Set the base URL at runtime (user manual override).
  static Future<void> setBaseUrl(String url) async {
    _overrideBaseUrl = url.isNotEmpty ? url : null;
    final prefs = await SharedPreferences.getInstance();
    if (url.isNotEmpty) {
      await prefs.setString(_prefKeyUser, url);
    } else {
      await prefs.remove(_prefKeyUser);
    }
  }

  /// Load persisted URLs on app start.
  /// Priority: user override > server-pushed URL > compile-time default
  static Future<void> loadPersistedUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // User manual override (highest priority)
    final userUrl = prefs.getString(_prefKeyUser);
    if (userUrl != null && userUrl.isNotEmpty) {
      _overrideBaseUrl = userUrl;
      return;
    }

    // Server-pushed URL (from admin panel)
    final serverUrl = prefs.getString(_prefKeyServer);
    if (serverUrl != null && serverUrl.isNotEmpty) {
      _overrideBaseUrl = serverUrl;
    }
  }

  /// Current active URL (for display).
  static String get currentUrl => _overrideBaseUrl ?? '';

  /// Base URL resolution order:
  /// 1. User override or server-pushed URL (persisted)
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

  /// Fetch app config from server. If admin panel has set mobile_api_url,
  /// auto-apply it and persist for next startup.
  static Future<void> fetchAndUpdateConfig() async {
    try {
      final url = Uri.parse('${baseUrl}/app-config');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverUrl = data['mobile_api_url'] as String?;

        final prefs = await SharedPreferences.getInstance();

        if (serverUrl != null && serverUrl.isNotEmpty) {
          // Simpan URL dari server → dipakai di startup berikutnya
          await prefs.setString(_prefKeyServer, serverUrl);
          _overrideBaseUrl = serverUrl;
        } else {
          // Admin kosongkan URL → hapus saved, balik ke default
          await prefs.remove(_prefKeyServer);
          // Cek apakah user juga gak punya override
          final userUrl = prefs.getString(_prefKeyUser);
          if (userUrl == null || userUrl.isEmpty) {
            _overrideBaseUrl = null;
          }
        }
      }
    } catch (_) {
      // Gagal fetch → pakai URL yang sudah tersimpan
    }
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
