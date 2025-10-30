import 'package:flutter/foundation.dart';

class ChatRoom {
  final int id;
  final int? reservationIdx; // Reservation 엔티티가 필요하다면 추가 가능

  ChatRoom({
    required this.id,
    this.reservationIdx,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      reservationIdx: json['reservation'] != null ? json['reservation']['id'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation': reservationIdx != null ? {'id': reservationIdx} : null,
    };
  }
}