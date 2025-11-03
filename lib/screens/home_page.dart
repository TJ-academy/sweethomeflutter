import 'package:flutter/material.dart';

import '../api_client.dart';

class HomePage extends StatefulWidget {
  final ApiClient api;
  final String email;
  final String nickname;
  final String profileImg;

  //매개변수도 없고 리턴도 없는 타입
  final VoidCallback onLoggedOut;

  const HomePage({
    super.key,
    required this.api,
    required this.email,
    required this.nickname,
    required this.profileImg,
    required this.onLoggedOut,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _authOk;

  String? _email;
  String? _nickname;
  String? _profileImg;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _nickname = widget.nickname;
    _profileImg = widget.profileImg;
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final ok = await widget.api.isAuthenticated();
    setState(() => _authOk = ok);
  }

  Future<void> _logout() async {
    await widget.api.logout();
    if(!mounted) return;
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_nickname}님 환영합니다', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8,),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}