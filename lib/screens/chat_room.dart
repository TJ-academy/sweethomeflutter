// import 'package:flutter/material.dart';
// import '../models/chat_room.dart';
// import '../models/chat_message.dart';
// import '../services/api_service.dart';
//
// class ChatRoomPage extends StatefulWidget {
//   final ChatRoom room;
//
//   const ChatRoomPage({super.key, required this.room});
//
//   @override
//   State<ChatRoomPage> createState() => _ChatRoomPageState();
// }
//
// class _ChatRoomPageState extends State<ChatRoomPage> {
//   List<ChatMessage> messages = [];
//   final TextEditingController _controller = TextEditingController();
//   bool loading = true;
//   final ApiService _api = ApiService();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMessages();
//   }
//
//   Future<void> _loadMessages() async {
//     try {
//       var fetchedMessages = await _api.fetchChatMessages(widget.room.id);
//       setState(() {
//         messages = fetchedMessages;
//         loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         loading = false;
//       });
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     String text = _controller.text.trim();
//     if (text.isEmpty) return;
//
//     // API 호출해서 메시지 보내기
//     bool success = await ApiService.sendChatMessage(widget.room.id, text);
//     if (success) {
//       _controller.clear();
//       _loadMessages(); // 다시 불러오기
//     } else {
//       // 실패 처리
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(
//         appBar:  AppBar(title: Text('채팅방')),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text('채팅방 ID: ${widget.room.id}')),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true, // 최신 메시지가 아래로
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 var msg = messages[index];
//                 return ListTile(
//                   title: Text(msg.sender),
//                   subtitle: Text(msg.content),
//                   trailing: msg.img != '-' ? Image.network(msg.img) : null,
//                   // 시간 표시 원하면 추가 가능
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(hintText: '메시지를 입력하세요'),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
