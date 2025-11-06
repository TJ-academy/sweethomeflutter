import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api_client.dart';

class ChatRoomPage extends StatefulWidget {
  final ApiClient api;
  final int roomId;
  final String myEmail;
  final String myNickname;
  final String token;

  const ChatRoomPage({
    super.key,
    required this.api,
    required this.roomId,
    required this.myEmail,
    required this.myNickname,
    required this.token,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  //Map<String, dynamic>? chatData;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  // late WebSocketChannel channel;
  bool loading = true;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  String? otherEmail;
  String? otherNickname;
  String? otherProfileImg;

  @override
  void initState() {
    super.initState();
    // _loadMessages();
    // _connectWebSocket();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final data = await widget.api.fetchChatRoomDetail(widget.roomId, widget.token);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data["messages"]);
        otherEmail = data["otherEmail"];
        otherNickname = data["otherNickname"];
        otherProfileImg = data["otherProfileImg"];
        loading = false;
      });

      // ✅ 실시간 구독
      widget.api.subscribeRoom(widget.roomId, (msg) {
        if (msg['roomId'] == widget.roomId) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      });

      _scrollToBottom();
    } catch(e) {
      print("❌ 채팅방 로드 실패: $e");
      setState(() => loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        //_scroll.jumpTo(_scroll.position.maxScrollExtent);
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String content = "", String img = "-"}) async {
    if (content.trim().isEmpty && img == "-") return;

    print("_sendMessage 실행됨");

    final msg = {
      "roomId": widget.roomId,
      "senderNickname": widget.myNickname,
      "senderEmail": widget.myEmail,
      "receiverEmail": otherEmail,
      "content": content,
      "img": img,
    };
    widget.api.sendMessage(msg);
    _controller.clear();
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imgUrl = await widget.api.uploadImage(widget.roomId, widget.token, picked.path);
    await _sendMessage(img: imgUrl);
  }

  String _formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime);
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherNickname ?? "채팅방"),
        backgroundColor: const Color(0xFF4DB2FF),
      ),
      body: loading
          ? const Center(child:CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                scrollbars: true, // 스크롤바 표시
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}, // 마우스와 터치 모두 가능
              ),
              child: ListView.builder(
                controller: _scroll,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMine = msg["senderEmail"] == widget.myEmail;
                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if(!isMine)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundImage: otherProfileImg != null && otherProfileImg!.isNotEmpty
                                  ? NetworkImage(widget.api.makeImgUrl(otherProfileImg!)!)
                                  : AssetImage('assets/default_profile.png') as ImageProvider,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 250, // 메시지 박스 최대 너비
                              minWidth: 50,  // 최소 너비
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMine ? const Color(0xFF4DB2FF) : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (msg["img"] != null && msg["img"] != "-")
                                    Image.network(widget.api.makeImgUrl(msg["img"])!, width: 200),
                                  if (msg["content"] != null && msg["content"].trim().isNotEmpty)
                                    Text(
                                      msg["content"],
                                      softWrap: true,
                                      style: TextStyle(
                                        color: isMine ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(msg["createdAt"] ?? DateTime.now().toString()),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Color(0xFF4DB2FF)),
                onPressed: _sendImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 1,    //줄바꿈 대신 전송
                  textInputAction: TextInputAction.send, // Enter로 전송
                  decoration: const InputDecoration(
                    hintText: "메시지를 입력하세요...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) => _sendMessage(content: val),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF4DB2FF)),
                onPressed: () => _sendMessage(content: _controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
