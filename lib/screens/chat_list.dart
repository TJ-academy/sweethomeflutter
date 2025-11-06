import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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
  bool _loading = true;
  late StompClient stompClient;

  @override
  void initState() {
    super.initState();
    _connectStomp();
    _loadChatRooms();
  }

  @override
  void dispose() {
    stompClient.deactivate();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    try {
      final rooms = await widget.api.fetchChatRooms(widget.token);
      setState(() {
        chatRooms = rooms;
        _loading = false;
      });

      if (stompClient.connected) {
        _subscribeToChatRooms();
      }
    } catch (e) {
      print("❌ 채팅방 로드 실패: $e");
      setState(() => _loading = false);
    }
  }

  void _connectStomp() {
    final String stompUrl = 'wss://homesweethome.koyeb.app/ws-flutter';

    stompClient = StompClient(
      config: StompConfig(
        url: stompUrl,
        onConnect: _onStompConnect,
        onWebSocketError: (error) => print('채팅 리스트 웹소켓 에러: $error'),
        onDisconnect: (frame) => print('Disconnected'),
        webSocketConnectHeaders: {
          'Authorization': 'Bearer ${widget.token}',
        },
      ),
    );

    widget.api.setStompClient(stompClient);
    stompClient.activate();
  }

  void _onStompConnect(StompFrame frame) {
    print("✅ STOMP 연결 성공");
    if (!_loading) {
      _subscribeToChatRooms();
    }
  }

  void _subscribeToChatRooms() {
    for (var room in chatRooms) {
      final roomId = room['roomId'];
      stompClient.subscribe(
        destination: '/topic/chat/$roomId',
        callback: (frame) {
          if (frame.body != null) {
            final msg = widget.api.parseMessage(frame.body!);
            print("📩 새 메시지 도착 (roomId=$roomId): ${msg['content']}");

            if (mounted) {
              setState(() {
                final index = chatRooms.indexWhere((r) => r['roomId'] == msg['roomId']);
                if (index != -1) {
                  chatRooms[index]['lastMessage'] = msg['content'];
                  chatRooms[index]['lastMessageTime'] = msg['createdAt'];
                  chatRooms[index]['unreadCount'] =
                      (chatRooms[index]['unreadCount'] ?? 0) + 1;
                }
              });
            }
          }
        },
      );
    }
  }

  Future<void> _logout() async {
    try {
      await widget.api.logout();
      widget.onLoggedOut();
    } catch (e) {
      print("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text("채팅 목록"),
        centerTitle: true,
        backgroundColor: const Color(0xFF4DB2FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4DB2FF)))
          : chatRooms.isEmpty
          ? const Center(child: Text("채팅방이 없습니다."))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          return Card(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: room['profileImg'] != null &&
                    room['profileImg'].isNotEmpty
                    ? NetworkImage(widget.api.makeImgUrl(room['profileImg'])!)
                    : const AssetImage('assets/default_profile.png')
                as ImageProvider,
              ),
              title: Text(
                room['roomName'] ?? '알 수 없음',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                room['lastMessage'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    room["lastMessageTime"] ?? "",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (room["unreadCount"] != null &&
                      room["unreadCount"] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4), // overflow 수정 ✅
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${room["unreadCount"]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
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
            ),
          );
        },
      ),
    );
  }
}
