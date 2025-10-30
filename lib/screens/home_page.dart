import 'package:flutter/material.dart';
import 'login.dart';
import 'chat_list.dart';
import '../services/auth_service.dart';

//앱 시작. 로그인 여부 판단
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  //Future<자료형> 비동기 방식 리턴자료형
  Future<void> _checkLogin() async {
    //bool loggedIn = await AuthService.isLoggedIn();

    setState(() {
      //_isLoggedIn = loggedIn;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return const Login();
    } else {
      return const ChatList();
    }
  }
}