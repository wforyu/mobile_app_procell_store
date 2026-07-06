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

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.get(url, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.delete(url, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile(
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

  Future<Map<String, dynamic>> uploadFiles(
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

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      clearToken();
      _onUnauthenticated?.call();
      throw ApiException(
        statusCode: 401,
        message: 'Sesi berakhir. Silakan login ulang.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] as String? ?? 'Unknown error',
      errors: body['errors'] as Map<String, dynamic>?,
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
