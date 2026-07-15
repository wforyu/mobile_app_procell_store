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

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword(String email, String token, String password, String passwordConfirmation) async {
    await _api.post('/auth/reset-password', body: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> updatePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    await _api.put('/auth/password', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPasswordConfirmation,
    });
  }

  Future<void> deleteAccount(String password) async {
    await _api.delete('/profile', body: {'password': password});
  }
}
