// lib/models/reservation.dart
class Reservation {
  final int reservationIdx;
  final String bookerEmail;
  final int reservedHomeId;
  final int adult;
  final int child;
  final int pet;
  final DateTime? reservedDate;
  final String? message;
  final String reservationStatus; // enum 문자열
  final String payby;             // enum 문자열
  final String? bank;
  final int? account;             // 서버는 Long, Dart는 int로 받음
  final int totalMoney;
  final DateTime startDate;
  final DateTime endDate;
  final String? memoForHost;
  final String? cancelMessage;
  final String? memoForCheckIn;
  final String? memoForCheckOut;
  final String? merchantUid;
  final String? impUid;

  Reservation({
    required this.reservationIdx,
    required this.bookerEmail,
    required this.reservedHomeId,
    required this.adult,
    required this.child,
    required this.pet,
    this.reservedDate,
    this.message,
    required this.reservationStatus,
    required this.payby,
    this.bank,
    this.account,
    required this.totalMoney,
    required this.startDate,
    required this.endDate,
    this.memoForHost,
    this.cancelMessage,
    this.memoForCheckIn,
    this.memoForCheckOut,
    this.merchantUid,
    this.impUid,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
    reservationIdx: j['reservationIdx'] ?? 0,
    bookerEmail: j['bookerEmail'] ?? '',
    reservedHomeId: j['reservedHomeId'] ?? 0,
    adult: j['adult'] ?? 0,
    child: j['child'] ?? 0,
    pet: j['pet'] ?? 0,
    reservedDate:
    j['reservedDate'] != null ? DateTime.parse(j['reservedDate']) : null,
    message: j['message'],
    reservationStatus: j['reservationStatus'] ?? 'UNKNOWN',
    payby: j['payby'] ?? 'UNKNOWN',
    bank: j['bank'],
    account: j['account'],
    totalMoney: j['totalMoney'] ?? 0,
    startDate: DateTime.parse(j['startDate']),
    endDate: DateTime.parse(j['endDate']),
    memoForHost: j['memoForHost'],
    cancelMessage: j['cancelMessage'],
    memoForCheckIn: j['memoForCheckIn'],
    memoForCheckOut: j['memoForCheckOut'],
    merchantUid: j['merchantUid'],
    impUid: j['impUid'],
  );

  Map<String, dynamic> toJson() => {
    'reservationIdx': reservationIdx,
    'bookerEmail': bookerEmail,
    'reservedHomeId': reservedHomeId,
    'adult': adult,
    'child': child,
    'pet': pet,
    'reservedDate': reservedDate?.toIso8601String(),
    'message': message,
    'reservationStatus': reservationStatus,
    'payby': payby,
    'bank': bank,
    'account': account,
    'totalMoney': totalMoney,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'memoForHost': memoForHost,
    'cancelMessage': cancelMessage,
    'memoForCheckIn': memoForCheckIn,
    'memoForCheckOut': memoForCheckOut,
    'merchantUid': merchantUid,
    'impUid': impUid,
  };
}
