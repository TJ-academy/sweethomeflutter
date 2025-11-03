import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api_client.dart';
import 'chat_room.dart';

class ChatList extends StatefulWidget {
  final ApiClient api;
  final String email;
  final String nickname;
  final String token;
  final VoidCallback onLoggedOut;

  const ChatList({
    super.key,
    required this.api,
    required this.email,
    required this.nickname,
    required this.token,
    required this.onLoggedOut,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<Map<String, dynamic>> chatRooms = [];
  Map<int, int> unreadCount = {}; // 방ID, 안읽은 메시지 수
  bool loading = true;
  late final WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadChatRooms();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    final list = await widget.api.getChatRooms(widget.token);
    setState(() {
      chatRooms = List<Map<String, dynamic>>.from(list);
      loading = false;
    });
  }

  void _connectWebSocket() {
    // 로그인 후 저장된 JWT 토큰을 가져와서 WebSocket 연결
    _channel = widget.api.connectChatWebSocket(widget.token);

    _channel.stream.listen((message) {
      final data = message;
      // TODO: 수신한 메시지 처리 (예: 알림, 채팅방 메시지 업데이트)
      print('Received WS message: $data');
    }, onError: (err) {
      print('WebSocket error: $err');
    }, onDone: () {
      print('WebSocket closed');
    });
  }

  Future<void> _logout() async {
    await widget.api.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("채팅 목록"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : chatRooms.isEmpty
            ? const Center(child: Text("채팅방이 없습니다."))
            : ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(room['profileImg'] ?? '-'),
                  ),
                  title: Text(room['roomName'] ?? '알수없음'),
                  subtitle: Text(room['lastMessage'] ?? '-'),
                  trailing: Text(
                    room['unreadCount'] != null &&
                        room['unreadCount'] > 0
                        ? "${room['unreadCount']}"
                        : '',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          api: widget.api,
                          roomId: room['roomId'],
                          myEmail: widget.email,
                          myNickname: widget.nickname,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
