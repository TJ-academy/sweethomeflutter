import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl = 'http://localhost:8080/api';
  final http.Client _client = http.Client();
  String? _jwt;

  /// 로그인
  Future<bool> login(String email, String password) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _jwt = data['token']; // 서버에서 발급한 JWT
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _jwt!);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// JWT 포함 헤더
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_jwt != null) {
      headers['Authorization'] = 'Bearer $_jwt';
    }
    return headers;
  }

  /// 로그인 유저 확인
  Future<User?> session() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('jwt_token');
    if (_jwt == null) return null;

    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/user/session'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return User.fromJson(data['user']);
      }
    } catch (e) {
      print('Session error: $e');
    }
    return null;
  }

  /// 로그아웃
  Future<void> logout() async {
    _jwt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}