import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;
  void Function()? _onUnauthenticated;

  void setOnUnauthenticated(void Function() callback) {
    _onUnauthenticated = callback;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.get(url, headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.delete(url, headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> uploadFile(
    String endpoint, {
    required String field,
    required File file,
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';
    }
    request.files.add(await http.MultipartFile.fromPath(field, file.path));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> uploadFiles(
    String endpoint, {
    required String field,
    required List<File> files,
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';
    }
    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath(field, file.path));
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ── Search ──
  Future<List<Map<String, dynamic>>> searchSuggestions(String query) async {
    final res = await get('/search?q=$query');
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ── Compare ──
  Future<List<Map<String, dynamic>>> getCompare(List<int> ids) async {
    final idsStr = ids.join(',');
    final res = await get('/compare?ids=$idsStr');
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Pages ──
  Future<Map<String, dynamic>> getPage(String slug) async {
    return await get('/pages/$slug') as Map<String, dynamic>;
  }

  // ── Bundles ──
  Future<List<Map<String, dynamic>>> getBundles() async {
    final res = await get('/bundles');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBundleDetail(int id) async {
    return await get('/bundles/$id') as Map<String, dynamic>;
  }

  // ── Restock ──
  Future<Map<String, dynamic>> requestRestock(int productId, String email, {String? phone}) async {
    return await post('/restock', body: {
      'product_id': productId,
      'email': email,
      'phone': ?phone,
    }) as Map<String, dynamic>;
  }

  // ── Quick Buy ──
  Future<Map<String, dynamic>> quickBuy(int productId) async {
    return await post('/products/$productId/quick-buy') as Map<String, dynamic>;
  }

  // ── Chat ──
  Future<List<Map<String, dynamic>>> getChatConversations() async {
    final res = await get('/chat');
    return (res['conversations'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> startChat(String message, {String? subject}) async {
    return await post('/chat', body: {
      'message': message,
      'subject': ?subject,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getChatMessages(int conversationId) async {
    return await get('/chat/$conversationId') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendChatMessage(int conversationId, String message) async {
    return await post('/chat/$conversationId/send', body: {
      'message': message,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pollChatMessages(int conversationId, {String? since}) async {
    String url = '/chat/$conversationId/poll';
    if (since != null) url += '?since=$since';
    return await get(url) as Map<String, dynamic>;
  }

  // ── Cart add bundle ──
  Future<Map<String, dynamic>> addBundleToCart(int bundleId) async {
    return await post('/cart/add-bundle/$bundleId') as Map<String, dynamic>;
  }

  // ── Coupon apply/remove ──
  Future<Map<String, dynamic>> applyCoupon(String code, int cartTotal) async {
    return await post('/coupon/apply', body: {
      'code': code,
      'cart_total': cartTotal,
    }) as Map<String, dynamic>;
  }

  Future<void> removeCoupon() async {
    await post('/coupon/remove');
  }

  // ── Category by slug ──
  Future<Map<String, dynamic>> getCategoryBySlug(String slug) async {
    return await get('/categories/$slug') as Map<String, dynamic>;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      clearToken();
      _onUnauthenticated?.call();
      throw ApiException(
        statusCode: 401,
        message: 'Sesi berakhir. Silakan login ulang.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: decoded is Map<String, dynamic>
          ? (decoded['message'] as String? ?? 'Unknown error')
          : 'Unknown error',
      errors: decoded is Map<String, dynamic>
          ? decoded['errors'] as Map<String, dynamic>?
          : null,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
