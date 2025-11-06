import 'dart:async';
import 'dart:convert';
//import 'package:http/browser_client.dart' as http_browser;
import 'package:http/http.dart' as http;   //모바일용
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:web_socket_channel/io.dart';   //모바일용 WebSocket

import 'package:sweethomeflutter/models/reservation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/browser_client.dart' as browser;
import 'models/home.dart';

/// 로그인 결과 모델
class LoginResult {
  final bool ok;
  final String? email;
  final String? nickname;
  final String? profileImg;
  final String? token;
  final String? error;

  LoginResult({
    required this.ok,
    this.email,
    this.nickname,
    this.profileImg,
    this.token,
    this.error,
  });
}

class ApiClient {
  //late final http.Client _client;
  StompClient? _stompClient;
  //String? token;

  late final http.Client _client;
  final String baseUrl;

  ApiClient({this.baseUrl = "http://localhost:8080"}) {
    //ApiClient({this.baseUrl = "http://homesweethome.koyeb.app/"})
    //: _client = http.Client();
    if (kIsWeb) {
      final c = browser.BrowserClient();
      c.withCredentials = true; // ✅ 세션 쿠키 전송
      _client = c; // BaseClient 로 OK
    } else {
      _client = http.Client(); // BaseClient 로 OK
    }
  }

  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/user/login');
    try {
      //10초내에 응답을 못받으면 종료
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if(res.statusCode == 200) {
        final map = jsonDecode(res.body);
        return LoginResult(
          ok: true,
          email: map['email']?.toString(),
          nickname: map['nickname']?.toString(),
          profileImg: makeImgUrl(map['profileImg']?.toString() ?? ''),
          token: map['token']?.toString(),
        );
      } else {
        final map = jsonDecode(res.body);
        return LoginResult(
          ok: false,
          error: (map['message'] ?? map['error'])?.toString() ?? '로그인 실패',
        );
      }
    } on TimeoutException {
      return LoginResult(ok: false, error: '서버 응답 지연');
    } catch (e) {
      return LoginResult(ok: false, error: '네트워크 오류: $e');
    }
  }

  Future<LoginResult> kakaologin() async {
    final uri = Uri.parse('$baseUrl/api/kakao/login');
    try {
      //카카오 SDK로 로그인 시도
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인');
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인');
      }

      print('카카오 accessToken: ${token.accessToken}');

      //10초내에 응답을 못받으면 종료
      final res = await _client.post(
        uri,
        body: {'accessToken': token.accessToken},
      ).timeout(const Duration(seconds: 10));

      print('Status: ${res.statusCode}');
      print('Body: ${res.body}');

      if (res.statusCode == 200) {
        print('로그인 성공');
        final map = jsonDecode(res.body);
        return LoginResult(
          ok: true,
          email: map['email']?.toString(),
          nickname: map['nickname']?.toString(),
          profileImg: makeImgUrl(map['profileImg']?.toString() ?? ''),
          token: map['token']?.toString(),
        );
      } else {
        final map = jsonDecode(res.body);
        return LoginResult(
          ok: false,
          error: (map['message'] ?? map['error'])?.toString() ?? '카카오 로그인 실패',
        );
      }
    } on TimeoutException {
      return LoginResult(ok: false, error: '서버 응답 지연');
    } catch (e) {
      return LoginResult(ok: false, error: '네트워크 오류: $e');
    }
  }

  Future<void> logout() async {
    final uri = Uri.parse('$baseUrl/api/user/logout');
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
    final uri = Uri.parse('$baseUrl/api/user/session');
    try {
      final res = await _client.get(
          uri,
          headers: {"Content-Type": "application/json"}
      ).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch(_) {
      return false;
    }
  }

  String? makeImgUrl(String? path) {
    if(path == null || path == '-' || path.isEmpty) return null;

    /*//사진이 링크로 되어있으면 그대로
    if(path.startsWith('http')) {
      return path;
    } else if (path.startsWith('/img/')) {
      //img/ 어쩌구 저장소로 되어있으면 서버 url로
      String cleanedPath = path.split('?t')[0]; // ? 이전까지만
      return 'https://github.com/TJ-academy/sweethome/blob/main/src/main/resources/static$cleanedPath?raw=true';
    }*/

    // 사진이 링크로 되어있으면 그대로 사용
    if (path.startsWith('http')) {
      return path;
    }

    // 서버 static 경로에서 직접 불러오기
    if (path.startsWith('/img/')) {
      return '$baseUrl$path';
    }

    // 혹시 상대경로 형태면 직접 붙이기
    return '$baseUrl/img/userProfile/$path';

    return path;
  }

  void connectWebSocket({
    required String token,
    required Function(Map<String, dynamic>) onMessage}) {
    print("이것 뭐에요?");
    _stompClient = StompClient(
      config: StompConfig(
        url: "ws://localhost:8080/ws-flutter?token=$token",
        //url: "ws://homesweethome.koyeb.app/ws-flutter?token=$token",
        onConnect: (StompFrame frame) {
          print("✅ STOMP 연결 성공");

          // 예시: 기본 구독
          _stompClient!.subscribe(
            destination: "/topic/chat",
            callback: (frame) {
              if (frame.body != null) {
                final msg = jsonDecode(frame.body!);
                onMessage(msg);
              }
            },
          );
        },
        onStompError: (frame) => print("STOMP 오류: ${frame.body}"),
        onWebSocketError: (error) => print("웹소켓 오류: $error"),
        onDisconnect: (frame) => print("STOMP 연결 종료"),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _stompClient!.activate();
  }

  void subscribeRoom(int roomId, Function(Map<String, dynamic>) onMessage) {
    _stompClient?.subscribe(
      destination: "/topic/chat/$roomId",
      callback: (frame) {
        if (frame.body != null) {
          final msg = jsonDecode(frame.body!);
          onMessage(msg);
        }
      },
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    print("api까지 들어옴");
    _stompClient?.send(
      destination: "/app/api/message/send",
      body: jsonEncode(message),
    );
  }

  void disconnect() {
    _stompClient?.deactivate();
  }

  Map<String, dynamic> parseMessage(String body) {
    // 🔹 새로 추가됨: STOMP 메시지 파싱
    final data = json.decode(body);
    return {
      'roomId': data['roomId'],
      'content': data['content'],
      'createdAt': data['createdAt'],
    };
  }

  Future<List<Map<String, dynamic>>> fetchChatRooms(String token) async {
    final uri = Uri.parse("$baseUrl/api/chat/rooms");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });
    if (res.statusCode != 200) throw Exception("채팅방 목록 로드 실패");
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> fetchChatRoomDetail(int roomId, String token) async {
    final uri = Uri.parse("$baseUrl/api/chat/rooms/$roomId");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });
    if (res.statusCode != 200) throw Exception("채팅방 메시지 로드 실패");
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<String> uploadImage(int roomId, String token, String path) async {
    final uri = Uri.parse("$baseUrl/api/chat/uploadImage");
    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["roomId"] = roomId.toString()
      ..files.add(await http.MultipartFile.fromPath("image", path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("이미지 업로드 실패: ${response.statusCode} ${body}");
    }

    final data = jsonDecode(body);
    return data["imgUrl"];
  }

  Future<void> updateLastRead(int roomId, int msgId, String token) async {
    final uri = Uri.parse("$baseUrl/api/chat/updateLastRead?roomId=$roomId&msgId=$msgId");
    await http.post(uri, headers: {
      "Authorization": "Bearer $token",
    });
  }

  final Map<int, Home> _homeCache = {}; // 홈 단건 캐시

  Future<Home> fetchHomeBrief(int id) async {
    if (_homeCache.containsKey(id)) return _homeCache[id]!;

    final uri = Uri.parse('$baseUrl/api/homes/$id'); // 단건 조회 엔드포인트
    final res = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('숙소 정보 로드 실패: ${res.statusCode}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final home = Home.fromJson(map);
    _homeCache[id] = home;
    return home;
  }
}

extension ReservationApi on ApiClient {
  Future<List<Reservation>> fetchMyReservations() async {
    final uri = Uri.parse('$baseUrl/api/reservations/my');
    final res = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('예약 목록 로드 실패: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => Reservation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Reservation> fetchReservationDetail(int reservationIdx) async {
    final uri = Uri.parse('$baseUrl/api/reservations/$reservationIdx');
    final res = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('예약 상세 로드 실패: ${res.statusCode}');
    }

    final map = jsonDecode(res.body);
    return Reservation.fromJson(Map<String, dynamic>.from(map));
  }
}
