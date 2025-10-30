import 'package:flutter/material.dart';
import 'package:sweethomeflutter/screens/home_screen.dart';
import 'package:sweethomeflutter/screens/kakao_login.dart';
import 'package:sweethomeflutter/screens/kakao_login_vew_model.dart';
import '../services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  final kakaoViewModel = KakaoLoginViewModel(KakaoLogin());

  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    bool success = await _authService.login(
        emailController.text.trim(), passwordController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (success) {
      print("성공?");
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        _error = "로그인 실패. 이메일과 비밀번호를 확인하세요.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text('로그인'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // 카카오 로그인 함수 호출
                await kakaoViewModel.login();
                if (kakaoViewModel.isLogined) {
                  setState(() {}); // 화면 갱신
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(viewModel: kakaoViewModel)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('카카오 로그인 실패')),
                  );
                }
              },
              child: const Text('카카오 로그인'),
            ),
            // const SizedBox(height: 20),
            // TextButton(
            //   onPressed: () {
            //     // 회원가입 웹페이지로 이동
            //   },
            //   child: const Text('회원가입'),
            // ),
          ],
        ),
      ),
    );
  }
}
