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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool loading = true;
  final ImagePicker _picker = ImagePicker();
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

      // ✅ 실시간 구독
      widget.api.subscribeRoom(widget.roomId, (msg) {
        if (mounted && msg['roomId'] == widget.roomId) {
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

    // 1. 서버 전송용 메시지 객체 생성 (API가 요구하는 형태)
    final msgToSend = {
      "roomId": widget.roomId,
      "senderNickname": widget.myNickname,
      "senderEmail": widget.myEmail,
      "receiverEmail": otherEmail,
      "content": content,
      "img": img,
    };

    // 2. STOMP 전송
    widget.api.sendMessage(msgToSend);

    // 3. ✅ 로컬 상태 업데이트용 객체 생성 (즉시 화면 표시를 위해 최소한의 키만 포함)
    final now = DateTime.now().toIso8601String();
    final localMsgForDisplay = {
      "senderEmail": widget.myEmail, // isMine 판단용
      "content": content,
      "img": img,
      "createdAt": now, // 즉시 표시용 임시 시간 (서버 시간과 약간의 오차는 감수)
    };

    // 4. ✅ 로컬 상태에 즉시 메시지 추가 (핵심 수정)
    setState(() {
      _messages.add(localMsgForDisplay);
    });

    // 5. 입력 필드 초기화 및 스크롤
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
                                  : const AssetImage('assets/default_profile.png') as ImageProvider,
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
                                // ⚠️ 이미지를 로딩할 때 발생하는 오류를 대비해 에러 빌더 추가
                                  Image.network(
                                    widget.api.makeImgUrl(msg["img"])!,
                                    width: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      print("❌ 이미지 로딩 실패 (CORS 문제 예상): $error");
                                      return const Text('이미지 로딩 실패 (CORS)');
                                    },
                                  ),
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
                                  // 'createdAt' 키가 없는 경우를 대비해 처리 (서버에서 받은 메시지는 이 키를 가짐)
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