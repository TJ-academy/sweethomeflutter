import 'package:flutter/material.dart';
import '../api_client.dart';
import 'chat_list.dart';                 // 기존 채팅 화면
import 'my_reservation_list.dart';      // 네가 추가한 예약 목록 화면

class MenuPage extends StatelessWidget {
  final ApiClient api;
  final String email;
  final String nickname;
  final String profileImg;
  final String token;
  final VoidCallback onLoggedOut;

  const MenuPage({
    super.key,
    required this.api,
    required this.email,
    required this.nickname,
    required this.profileImg,
    required this.token,
    required this.onLoggedOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메뉴')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 간단한 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                  (profileImg != '-' && profileImg.isNotEmpty)
                      ? NetworkImage(profileImg)
                      : null,
                  child: (profileImg == '-' || profileImg.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$nickname 님',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 채팅 확인하기
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('채팅 확인하기'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatList(
                        api: api,
                        email: email,
                        nickname: nickname,
                        token: token,
                        onLoggedOut: onLoggedOut,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 예약 확인하기
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('예약 확인하기'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyReservationListPage(api: api),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // 로그아웃
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              onPressed: onLoggedOut,
            ),
          ],
        ),
      ),
    );
  }
}
