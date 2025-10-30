import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:sweethomeflutter/screens/kakao_login_vew_model.dart';

import 'kakao_login.dart';


class HomeScreen extends StatefulWidget {
  final KakaoLoginViewModel viewModel;
  const HomeScreen({super.key, required this.viewModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final viewModel = KakaoLoginViewModel(KakaoLogin());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
          children: [
            if (viewModel.user?.kakaoAccount?.profile?.profileImageUrl != null)
              CircleAvatar(
                radius: 100,
                backgroundImage: NetworkImage(
                  viewModel.user?.kakaoAccount?.profile?.profileImageUrl ?? '',
                ),
              ),
            Center(
              child: Text(
                viewModel.user?.kakaoAccount?.profile?.nickname ?? '',
                style: const TextStyle(
                  fontSize: 36.0,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (viewModel.user == null) {
                  await viewModel.login();
                } else {
                  await viewModel.logout();
                }
                setState(() {
                  // 로그인 / 로그아웃 후에 화면 갱신
                });
              },
              child: Text(
                viewModel.user == null ? '카카오 로그인' : '카카오 로그아웃',
              ),
            ),
          ],
        )
    );
  }
}