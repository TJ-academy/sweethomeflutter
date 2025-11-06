import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models/reservation.dart';
import '../models/home.dart';

class MyReservationDetailPage extends StatefulWidget {
  final ApiClient api;
  final int reservationIdx;

  const MyReservationDetailPage({
    super.key,
    required this.api,
    required this.reservationIdx,
  });

  @override
  State<MyReservationDetailPage> createState() => _MyReservationDetailPageState();
}

class _MyReservationDetailPageState extends State<MyReservationDetailPage> {
  late Future<Reservation> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchReservationDetail(widget.reservationIdx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('예약 상세 #${widget.reservationIdx}')),
      body: FutureBuilder<Reservation>(
        future: _future,
        builder: (context, snap) {
          // 로딩
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 에러
          if (snap.hasError) {
            return Center(child: Text('에러: ${snap.error}'));
          }
          // 데이터 없음
          if (!snap.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          final r = snap.data!;

          // 홈 정보 로딩
          return FutureBuilder<Home>(
            future: widget.api.fetchHomeBrief(r.reservedHomeId),
            builder: (context, hSnap) {
              // 홈 로딩
              if (hSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // 홈 에러 → 홈 정보 없이도 예약 상세는 보여주자
              final home = hSnap.data;
              final thumb = (home?.thumbnail != null)
                  ? widget.api.makeImgUrl(home!.thumbnail)
                  : null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 헤더(숙소 정보)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (thumb != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumb,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.home_outlined, size: 48),
                          ),
                        )
                      else
                        const Icon(Icons.home_outlined, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          home?.title ?? '숙소 ${r.reservedHomeId}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (home?.address != null && home!.address!.isNotEmpty)
                    _tile('주소', home.address!),

                  // 예약 상세 정보
                  _tile('상태', r.reservationStatus),
                  _tile('숙소 ID', r.reservedHomeId.toString()),
                  _tile('인원(성인/아동/반려)', '${r.adult}/${r.child}/${r.pet}'),
                  _tile('입실/퇴실', '${_d(r.startDate)} ~ ${_d(r.endDate)}'),
                  _tile('총 결제 금액', _money(r.totalMoney)),
                  _tile('결제 수단', r.payby),
                  if (r.bank != null && r.bank!.isNotEmpty) _tile('입금 은행', r.bank!),
                  if (r.account != null) _tile('계좌', r.account.toString()),
                  if (r.message != null && r.message!.isNotEmpty) _tile('메시지', r.message!),
                  if (r.memoForCheckIn != null && r.memoForCheckIn!.isNotEmpty) _tile('체크인 메모', r.memoForCheckIn!),
                  if (r.memoForCheckOut != null && r.memoForCheckOut!.isNotEmpty) _tile('체크아웃 메모', r.memoForCheckOut!),
                  if (r.memoForHost != null && r.memoForHost!.isNotEmpty) _tile('호스트 메모', r.memoForHost!),
                  if (r.cancelMessage != null && r.cancelMessage!.isNotEmpty) _tile('취소 사유', r.cancelMessage!),
                  if (r.merchantUid != null && r.merchantUid!.isNotEmpty) _tile('주문번호', r.merchantUid!),
                  if (r.impUid != null && r.impUid!.isNotEmpty) _tile('아임포트 UID', r.impUid!),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('목록으로'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _d(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';
  String _2(int n) => n.toString().padLeft(2, '0');
  String _money(int w) => '${w.toString()}원';
}
