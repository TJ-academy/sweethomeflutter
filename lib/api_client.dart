import 'dart:async';
import 'dart:convert';
import 'package:http/browser_client.dart' as http_browser;
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiClient {
  late final http.Client _client;

  ApiClient() {
    final bc = http_browser.BrowserClient()..withCredentials = true;
    _client = bc;
  }

  Future<({bool ok,
  String? email,
  String? nickname,
  String? profileImg,
  String? token,
  String? error})> login(
      String email,
      String password,
      ) async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/user/login');
    try {
      //10초내에 응답을 못받으면 종료
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'password': password},
      )
          .timeout(const Duration(seconds: 10));

      if(res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        String token = (map['token'] ?? '').toString();
        final emailId = (map['email'] ?? '알수없음').toString();
        final name = (map['nickname'] ?? '알수없음').toString();
        final profileUrl = (map['profileImg'] ?? '-').toString();
        return (ok: true, email: emailId, nickname: name, profileImg: profileUrl, token: token, error: null);
      } else {
        String? msg;
        try {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          msg = (map['message'] ?? map['error'])?.toString();
        } catch (_) {}
        return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: msg ?? '로그인에 실패했습니다.');
      }
    } on TimeoutException {
      return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: '서버 응답이 지연되고 있습니다.');
    } catch(_) {
      return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: '네트워크 오류가 발생했습니다.');
    }
  }

  Future<({bool ok,
  String? email,
  String? nickname,
  String? profileImg,
  String? token,
  String? error})> kakaologin() async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/kakao/login');
    try {
      //카카오 SDK로 로그인 시도
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('Kakao accessToken: ${token.accessToken}');

      //10초내에 응답을 못받으면 종료
      final res = await _client.post(
        uri,
        body: {'accessToken': token.accessToken},
      )
          .timeout(const Duration(seconds: 10));

      if(res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        String token = (map['token'] ?? '').toString();
        final emailId = (map['email'] ?? '알수없음').toString();
        final name = (map['nickname'] ?? '알수없음').toString();
        final profileUrl = (map['profileImg'] ?? '-').toString();
        return (ok: true, email: emailId, nickname: name, profileImg: profileUrl, token: token, error: null);
      } else {
        String? msg;
        try {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          msg = (map['message'] ?? map['error'])?.toString();
        } catch (_) {}
        return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: msg ?? '로그인에 실패했습니다.');
      }
    } on TimeoutException {
      return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: '서버 응답이 지연되고 있습니다.');
    } catch(_) {
      return (ok: false, email: null, nickname: null, profileImg: null, token: null, error: '네트워크 오류가 발생했습니다.');
    }
  }

  Future<void> logout() async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/user/logout');
    try {
      //6초 안에 응답하지 않으면 종료
      await _client.post(uri).timeout(const Duration(seconds: 6));
    } catch (_) {}

    try {
      //카카오 로그아웃 (카카오 토큰 무효화)
      await UserApi.instance.logout();
      print('카카오 로그아웃 성공');
    } catch (error) {
      print('카카오 로그아웃 실패: $error');
    }
  }

  Future<bool> isAuthenticated() async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/user/session');
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch(_) {
      return false;
    }
  }

  // WebSocket 연결
  WebSocketChannel connectChatWebSocket(String token) {
    // 서버 주소. ws:// 또는 wss://로 시작해야 함
    final uri = Uri.parse('ws://192.168.0.104:8080/ws-flutter');
    final wsUri = uri.replace(queryParameters: {'token': token});
    return WebSocketChannel.connect(wsUri);
  }

  Future<List<dynamic>> getChatRooms(String token) async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/chat/rooms');
    try {
      final res = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token', // ← 여기 추가
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChatRoomDetail(int roomId, String token) async {
    final uri = Uri.parse('http://192.168.0.104:8080/api/chat/rooms/$roomId');
    try {
      final res = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token', // ← 여기 추가
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }
}