import 'package:dio/dio.dart';
import 'package:sweethomeflutter/services/api_service.dart';
import 'package:sweethomeflutter/models/user.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// 로그인 (Spring 세션 방식)
  Future<bool> login(String email, String password) async {
    try {
      Response res = await _api.post('/user/login', data: {
        'email': email,
        'password': password,
      });
      // 성공 시 redirect 대신 200 OK만 받는다면 true 반환
      return res.statusCode == 200;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _api.get('/user/logout');
      await _api.clearCookies();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// 현재 세션 유저 가져오기
  Future<User?> session() async {
    try {
      Response res = await _api.get('/user/session');
      if (res.statusCode == 200 && res.data['loginId'] != null) {
        return User.fromJson(res.data);
      }
    } catch (e) {
      print('Session error: $e');
    }
    return null;
  }
}