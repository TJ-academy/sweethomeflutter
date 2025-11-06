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
  bool _loading = true;
  late StompClient stompClient;
  int? _openedRoomId;

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

      // ✅ 채팅방 목록 로드가 완료된 후, 연결이 성공했다면 구독을 시작합니다.
      // _onStompConnect에서 호출하거나, 연결 상태를 확인 후 여기서 호출할 수 있습니다.
      // _onStompConnect에서 구독을 처리하는 것이 더 일반적이나, 여기서는 일단 연결 완료를 기다립니다.
      if (stompClient.connected) {
        _subscribeToChatRooms();
      }

    } catch (e) {
      print("❌ 채팅방 로드 실패: $e");
      setState(() => _loading = false);
    }
  }

  void _connectStomp() {
    // 1. 공용 서버에 연결할 때는 보안 연결을 위해 wss://를 사용합니다. (401 오류 방지)
    final String stompUrl = 'wss://homesweethome.koyeb.app/ws-flutter';

    stompClient = StompClient(
      config: StompConfig(
        url: stompUrl,
        onConnect: _onStompConnect,
        onWebSocketError: (dynamic error) => print('채팅 리스트 웹소켓 에러: $error'),
        onDisconnect: (frame) => print('Disconnected'),
        // 2. 401 Unauthorized 오류 해결을 위해 유효한 토큰을 헤더에 추가합니다.
        webSocketConnectHeaders: {
          'Authorization': 'Bearer ${widget.token}',
        },
      ),
    );

    // 3. ChatRoomPage에서 메시지 전송에 사용할 수 있도록 ApiClient에 StompClient 인스턴스를 설정합니다.
    // ⚠️ 이 함수(setStompClient)는 api_client.dart에 정의해야 합니다. (아래 2번 항목 참고)
    widget.api.setStompClient(stompClient);

    stompClient.activate();
  }

  void _onStompConnect(StompFrame frame) {
    print("StompConnect 함수 실행 (연결 성공)");
    // 채팅방 목록이 로드된 경우에만 구독을 시작합니다.
    if (!_loading) {
      _subscribeToChatRooms();
    }
  }

  void _subscribeToChatRooms() {
    // 내 이메일 기준으로 모든 방 메시지 수신
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
                  chatRooms[index]['unreadCount'] = (chatRooms[index]['unreadCount'] ?? 0) + 1;
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
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
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