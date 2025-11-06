import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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
  //Map<int, int> unreadCount = {}; // 방ID, 안읽은 메시지 수
  bool _loading = true;
  // late final WebSocketChannel _channel;
  late StompClient stompClient;
  int? _openedRoomId;

  @override
  void initState() {
    super.initState();
    // _connectWebSocket();
    _connectStomp();
    _loadChatRooms();
    //_connectStomp();
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
    } catch (e) {
      print("❌ 채팅방 로드 실패: $e");
      setState(() => _loading = false);
    }
  }
  void _connectStomp() {
    stompClient = StompClient(
      config: StompConfig(
        //url: 'ws://192.168.0.104:8080/ws-flutter?token=${widget.token}',
        url: 'ws://homesweethome.koyeb.app/ws-flutter?token=${widget.token}',
        onConnect: _onStompConnect,
        onWebSocketError: (dynamic error) => print('채팅 리스트 웹소켓 에러: $error'),
        onDisconnect: (frame) => print('Disconnected'),
        // stompConnectHeaders: {'Authorization': 'Bearer ${widget.token}'},
        // webSocketConnectHeaders: {'Authorization': 'Bearer ${widget.token}'},
      ),
    );
    stompClient.activate();
  }

  void _onStompConnect(StompFrame frame) {
    print("StompConnect 함수 실행");
    // 내 이메일 기준으로 모든 방 메시지 수신
    for (var room in chatRooms) {
      final roomId = room['roomId'];
      stompClient.subscribe(
        destination: '/topic/chat/$roomId',
        callback: (frame) {
          if (frame.body != null) {
            final msg = widget.api.parseMessage(frame.body!);
            print("📩 새 메시지 도착 (roomId=$roomId): ${msg['content']}");

            setState(() {
              final index = chatRooms.indexWhere((r) => r['roomId'] == msg['roomId']);
              if (index != -1) {
                chatRooms[index]['lastMessage'] = msg['content'];
                chatRooms[index]['lastMessageTime'] = msg['createdAt'];
                chatRooms[index]['unreadCount'] = (chatRooms[index]['unreadCount'] ?? 0) + 1;
              }
            });
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
          const SnackBar(content: Text('로그아웃에 실패했습니다.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("채팅 목록"),
        backgroundColor: const Color(0xFF4DB2FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : chatRooms.isEmpty
            ? const Center(child: Text("채팅방이 없습니다."))
            : ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: room['profileImg'] != null && room['profileImg'].isNotEmpty
                        ? NetworkImage(widget.api.makeImgUrl(room['profileImg'])!)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  title: Text(room['roomName'] ?? '알수없음'),
                  subtitle: Text(room['lastMessage'] ?? '-'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        room["lastMessageTime"] ?? "",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (room["unreadCount"] != null && room["unreadCount"] > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${room["unreadCount"]}",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
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
                );
              },
            ),
    );
  }
}
