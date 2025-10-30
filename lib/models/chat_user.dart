import 'package:flutter/foundation.dart';

class ChatUser {
  final int roomId;
  final String nickname;
  final int? lastRead;

  ChatUser({
    required this.roomId,
    required this.nickname,
    this.lastRead,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      roomId: json['roomId'],
      nickname: json['nickname'],
      lastRead: json['lastRead'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'nickname': nickname,
      'lastRead': lastRead,
    };
  }
}
