import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api_client.dart';

class ChatRoomPage extends StatefulWidget {
  final ApiClient api;
  final int roomId;
  final String myEmail;
  final String myNickname;
  final String token;
  // final String otherEmail;
  // final String otherNickname;
  // final String otherProfileImg;
  // final int lastRead;
  // final List<dynamic> messages;

  const ChatRoomPage({
    super.key,
    required this.api,
    required this.roomId,
    required this.myEmail,
    required this.myNickname,
    required this.token,
    // required this.otherEmail,
    // required this.otherNickname,
    // required this.otherProfileImg,
    // required this.lastRead,
    // required this.messages,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  Map<String, dynamic>? chatData;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late WebSocketChannel channel;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    channel = widget.api.connectChatWebSocket(widget.myEmail); // token 필요
    channel.stream.listen((event) {
      final msg = jsonDecode(event);
      if (msg['roomId'] == widget.roomId) {
        setState(() {
          chatData?['messages'].add(msg);
        });
        _scrollToBottom();
      }
    }, onError: (err) {
      print('WebSocket error: $err');
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await widget.api.getChatRoomDetail(widget.roomId, widget.token);
      setState(() {
        chatData = data;
        loading = false;
      });

    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // 메시지 수신
  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'roomId': widget.roomId,
      'content': text,
      'senderEmail': widget.myEmail,
    };

    channel.sink.add(jsonEncode(message));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final messages = chatData?['messages'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(chatData?['otherNickname'] ?? '채팅방'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              //reverse: true, // 최신 메시지가 아래로
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMine = msg['senderEmail'] == widget.myEmail;
                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Colors.lightBlueAccent.withOpacity(0.7)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: msg['img'] != '-' && msg['img'] != null
                        ? Image.network(msg['img'], width: 200)
                        : Text(msg['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요'
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
