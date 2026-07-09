import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<User> login(String email, String password) async {
    final res = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final user = User.fromJson(res['user'] as Map<String, dynamic>,
        token: res['token'] as String);
    await _api.setToken(user.token!);
    return user;
  }

  Future<User> register(
      String name, String email, String password, String passwordConfirmation,
      {String? phone}) async {
    final res = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
    });
    final user = User.fromJson(res['user'] as Map<String, dynamic>,
        token: res['token'] as String);
    await _api.setToken(user.token!);
    return user;
  }

  Future<User> getUser() async {
    final res = await _api.get('/auth/user');
    return User.fromJson(res);
  }

  Future<void> logout() async {
    await _api.post('/auth/logout');
    await _api.clearToken();
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put('/profile', body: data);
    return User.fromJson(res);
  }
}
