import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:sweethomeflutter/screens/chat_list.dart';
import 'package:sweethomeflutter/screens/login.dart';
import 'package:sweethomeflutter/screens/menu.dart';

import 'api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //네이티브 앱 키 입력
  KakaoSdk.init(
    nativeAppKey: '448fefd44eb5aa40ff41fe337054604d',
    //javaScriptAppKey: 'd8541a69eebb24f3789c2bb2c5a49775',
  );

  runApp(const HSHApp());
}

class HSHApp extends StatefulWidget {
  const HSHApp({super.key});

  @override
  State<HSHApp> createState() => _HSHAppState();
}

class _HSHAppState extends State<HSHApp> {
  final api = ApiClient();
  bool _booting = true;
  bool _loggedIn = false;
  String _email = '알수없음';
  String _nickname = '알수없음';
  String _profileImg = '-';
  String _token = '알수없음';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  //로그인 되어있는지
  Future<void> _bootstrap() async {
    final ok = await api.isAuthenticated();
    setState(() {
      _loggedIn = ok;
      _booting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '홈스위트홈',
      debugShowCheckedModeBanner: false,
      /*home: _booting
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_loggedIn
              ? ChatList(
                  api: api,
                  email: _email,
                  nickname: _nickname,
                  token: _token,
                  onLoggedOut: _onLoggedOut,
                )
              : Login(api: api, onLoggedIn: _onLoggedIn)),*/
      home: _booting
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_loggedIn
          ? MenuPage(
        api: api,
        email: _email,
        nickname: _nickname,
        profileImg: _profileImg,
        token: _token,
        onLoggedOut: _onLoggedOut,
      )
          : Login(api: api, onLoggedIn: _onLoggedIn)),
    );
  }

  void _onLoggedIn(String usermail, String name, String profileUrl, String token) {
    setState(() {
      _loggedIn = true;
      _email = usermail;
      _nickname = name;
      _profileImg = profileUrl;
      _token = token;
    });
  }

  void _onLoggedOut() {
    setState(() {
      _loggedIn = false;
      _email = '알수없음';
      _nickname = '알수없음';
      _profileImg = '-';
      _token = '알수없음';
    });
  }
}