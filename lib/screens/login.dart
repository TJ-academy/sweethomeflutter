import 'package:flutter/material.dart';
import '../api_client.dart';

class Login extends StatefulWidget {
  final ApiClient api;
  final void Function(String email, String nickname, String profileImg, String token) onLoggedIn;
  const Login({super.key, required this.api, required this.onLoggedIn});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailCtrl = TextEditingController(text: '');
  final pwCtrl = TextEditingController(text: '');
  bool working = false;
  bool kakaoworking = false;
  String? errorText;

  Future<void> _login() async {
    setState(() {
      working = true;
      errorText = null;
    });

    try {
      final r = await widget.api.login(emailCtrl.text.trim(), pwCtrl.text);
      if(r.ok) {
        widget.onLoggedIn(r.email ?? emailCtrl.text.trim(),
            r.nickname ?? '알수없음', r.profileImg ?? '-',
            r.token ?? '알수없음');
      } else {
        setState(() => errorText = r.error ?? '로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _loginWithKakao() async {
    setState(() {
      kakaoworking = true;
      errorText = null;
    });

    try {
      final r = await widget.api.kakaologin();
      if(r.ok) {
        widget.onLoggedIn(r.email ?? '알수없음',
            r.nickname ?? '알수없음',
            r.profileImg ?? '-',
            r.token ?? '알수없음');
      } else {
        setState(() => errorText = r.error ?? '로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) setState(() => kakaoworking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12,);
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: '이메일'),
              textInputAction: TextInputAction.next, // 다음 입력 필드로 이동
            ),
            spacing,
            TextField(
              controller: pwCtrl,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,  //암호 마스킹
              textInputAction: TextInputAction.done, // 엔터를 '완료'로 설정
              onSubmitted: (_) => _login(), // 엔터 치면 로그인 실행
            ),
            spacing,
            if(errorText != null)
              Text(errorText!, style: const TextStyle(color: Colors.red),),
            spacing,
            ElevatedButton(
              onPressed: working ? null : _login,
              child: Text(working ? '로그인 중...' : '로그인'),
            ),
            spacing,
            ElevatedButton(
              onPressed: kakaoworking ? null : _loginWithKakao,
              child: Text(kakaoworking ? '카카오로 로그인 중...' : '카카오로 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
