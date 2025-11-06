import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool loading = true;
  List<Map<String, dynamic>> _messages = [];
  String? otherEmail;
  String? otherNickname;
  String? otherProfileImg;

  @override
  void initState() {
    super.initState();
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

      widget.api.subscribeRoom(widget.roomId, (msg) {
        if (mounted && msg['roomId'] == widget.roomId) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      });

      _scrollToBottom();
    } catch (e) {
      print("❌ 채팅방 로드 실패: $e");
      setState(() => loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
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

    final msgToSend = {
      "roomId": widget.roomId,
      "senderNickname": widget.myNickname,
      "senderEmail": widget.myEmail,
      "receiverEmail": otherEmail,
      "content": content,
      "img": img,
    };

    widget.api.sendMessage(msgToSend);

    final now = DateTime.now().toIso8601String();
    setState(() {
      _messages.add({
        "senderEmail": widget.myEmail,
        "content": content,
        "img": img,
        "createdAt": now,
      });
    });

    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imgUrl = await widget.api.uploadImage(widget.roomId, widget.token, picked.path);
    await _sendMessage(img: imgUrl);
  }

  String _formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(otherNickname ?? "채팅방", style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4DB2FF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4DB2FF)))
          : Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                scrollbars: false,
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMine = msg["senderEmail"] == widget.myEmail;

                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMine ? const Color(0xFF4DB2FF) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (msg["img"] != null && msg["img"] != "-")
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.api.makeImgUrl(msg["img"])!,
                                width: 200,
                                errorBuilder: (context, error, stackTrace) =>
                                const Text('이미지 로딩 실패'),
                              ),
                            ),
                          if (msg["content"] != null && msg["content"].trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                msg["content"],
                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(msg["createdAt"] ?? DateTime.now().toString()),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMine ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF4DB2FF)),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: "메시지를 입력하세요...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _sendMessage(content: val),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF4DB2FF)),
                  onPressed: () => _sendMessage(content: _controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
