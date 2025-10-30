import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<ChatRoom> rooms = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    try {
      // var fetchedRooms = await _api.fetchChatRooms();
      // setState(() {
      //   rooms = fetchedRooms;
      //   loading = false;
      // });
    } catch (e) {
      // 에러 처리
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('채팅방 리스트')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('채팅방 리스트')),
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          var room = rooms[index];
          return ListTile(
            title: Text('방 ID: ${room.id}'),
            subtitle: Text('예약번호: ${room.reservationIdx ?? "없음"}'),
            onTap: () {
              Navigator.pushNamed(context, '/chat_room', arguments: room);
            },
          );
        },
      ),
    );
  }
}
