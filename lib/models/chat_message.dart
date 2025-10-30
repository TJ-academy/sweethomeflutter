import 'package:flutter/foundation.dart';

class ChatMessage {
  final int idx;
  final int chatRoomId;
  final String sender;
  final String content;
  final String img;
  final DateTime? sendedAt;

  ChatMessage({
    required this.idx,
    required this.chatRoomId,
    required this.sender,
    required this.content,
    this.img = '-',
    this.sendedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      idx: json['idx'],
      chatRoomId: json['chatRoom']['id'],
      sender: json['sender'],
      content: json['content'],
      img: json['img'] ?? '-',
      sendedAt: json['sendedAt'] != null ? DateTime.parse(json['sendedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idx': idx,
      'chatRoom': {'id': chatRoomId},
      'sender': sender,
      'content': content,
      'img': img,
      'sendedAt': sendedAt?.toIso8601String(),
    };
  }
}
