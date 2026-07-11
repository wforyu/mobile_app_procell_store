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

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.delete(url, headers: _headers, body: body != null ? jsonEncode(body) : null);
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

  // ── Cart ──
  Future<Map<String, dynamic>> getCart() async {
    return await get('/cart') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    return await post('/cart/add/$productId', body: {
      'quantity': quantity,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCartItem(int productId, int quantity) async {
    return await post('/cart/update', body: {
      'product_id': productId,
      'quantity': quantity,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeCartItem(int productId) async {
    return await post('/cart/remove', body: {
      'product_id': productId,
    }) as Map<String, dynamic>;
  }

  // ── Wishlist ──
  Future<List<Map<String, dynamic>>> getWishlist() async {
    final res = await get('/wishlist');
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> toggleWishlist(int productId) async {
    return await post('/wishlist/toggle/$productId') as Map<String, dynamic>;
  }

  Future<void> addToWishlist(int productId) async {
    await post('/wishlist/toggle/$productId');
  }

  Future<void> removeFromWishlist(int productId) async {
    await post('/wishlist/toggle/$productId');
  }

  // ── Orders ──
  Future<List<Map<String, dynamic>>> getOrders({int page = 1}) async {
    final res = await get('/orders?page=$page');
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    return await get('/orders/$orderId') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadPaymentProof(int orderId, String filePath) async {
    return await uploadFile('/orders/$orderId/payment-upload',
      field: 'payment_proof',
      file: File(filePath),
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmReceived(int orderId) async {
    return await post('/orders/$orderId/confirm-received') as Map<String, dynamic>;
  }

  // ── Reviews ──
  Future<Map<String, dynamic>> submitReview(int orderId, Map<String, dynamic> ratings) async {
    return await post('/orders/$orderId/review', body: ratings) as Map<String, dynamic>;
  }

  // ── Returns ──
  Future<Map<String, dynamic>> submitReturn(int orderId, Map<String, dynamic> data) async {
    return await post('/orders/$orderId/retur', body: data) as Map<String, dynamic>;
  }

  // ── Profile ──
  Future<Map<String, dynamic>> getProfile() async {
    return await get('/profile') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await put('/profile', body: data) as Map<String, dynamic>;
  }

  // ── Notifications ──
  Future<List<Map<String, dynamic>>> getNotifications({int page = 1}) async {
    final res = await get('/notifications?page=$page');
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Compare ──
  Future<void> removeFromCompare(int productId) async {
    // Compare is session-based on server, local-only on mobile
    return;
  }

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
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getBundleDetail(int id) async {
    return await get('/bundles/$id') as Map<String, dynamic>;
  }

  // ── Restock ──
  Future<Map<String, dynamic>> requestRestock(int productId, String email, {String? phone}) async {
    return await post('/restock', body: {
      'product_id': productId,
      'email': email,
      'phone': phone,
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
      'subject': subject,
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

  // ── Frequently Bought Together ──
  Future<List<Map<String, dynamic>>> getFrequentlyBoughtTogether(String slug) async {
    final res = await get('/products/$slug/frequently-bought-together');
    if (res is Map && res.containsKey('data')) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Loyalty Points ──
  Future<Map<String, dynamic>> getLoyaltyBalance() async {
    return await get('/loyalty/balance') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLoyaltyHistory({int page = 1}) async {
    return await get('/loyalty/history?page=$page') as Map<String, dynamic>;
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
