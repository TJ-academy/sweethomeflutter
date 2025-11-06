import 'package:flutter/material.dart';
import '../api_client.dart';

class Login extends StatefulWidget {
  final ApiClient api;
  final void Function(
      String email,
      String nickname,
      String profileImg,
      String token,
      ) onLoggedIn;

  const Login({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
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
      if (r.ok) {
        widget.onLoggedIn(
          r.email ?? emailCtrl.text.trim(),
          r.nickname ?? '알수없음',
          r.profileImg ?? '-',
          r.token ?? '알수없음',
        );
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
      if (r.ok) {
        widget.onLoggedIn(
          r.email ?? '알수없음',
          r.nickname ?? '알수없음',
          r.profileImg ?? '-',
          r.token ?? '알수없음',
        );
      } else {
        setState(() => errorText = r.error ?? '로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) setState(() => kakaoworking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 16);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Card(
            color: Colors.white, // ✅ 카드 흰색 유지
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  spacing,
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  spacing,
                  TextField(
                    controller: pwCtrl,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  spacing,
                  if (errorText != null)
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  spacing,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: working ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        working ? '로그인 중...' : '로그인',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  spacing,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: kakaoworking ? null : _loginWithKakao,
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.black),
                      label: Text(
                        kakaoworking ? '카카오로 로그인 중...' : '카카오로 로그인',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
