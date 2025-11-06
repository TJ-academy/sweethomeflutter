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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('예약 상세 #${widget.reservationIdx}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: FutureBuilder<Reservation>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('에러: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          final r = snap.data!;

          return FutureBuilder<Home>(
            future: widget.api.fetchHomeBrief(r.reservedHomeId),
            builder: (context, hSnap) {
              if (hSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final home = hSnap.data;
              final thumb = (home?.thumbnail != null) ? widget.api.makeImgUrl(home!.thumbnail) : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단 카드 (이미지 + 기본정보)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이미지 (있으면 16:9, 없으면 회색 박스)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: thumb != null
                                ? AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                            )
                                : Container(
                              height: 140,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 작은 섬네일 왼쪽 (선택적)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: thumb != null
                                      ? Image.network(
                                    thumb,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.home_outlined, size: 36, color: Colors.grey),
                                    ),
                                  )
                                      : Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.home_outlined, size: 36, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        home?.title ?? '숙소 ${r.reservedHomeId}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      if (home?.address != null && home!.address!.isNotEmpty)
                                        Text(
                                          home.address!,
                                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '입실: ${_d(r.startDate)}  •  퇴실: ${_d(r.endDate)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '결제: ${r.payby}  •  ${_money(r.totalMoney)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 상세정보 카드
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '예약 상세 정보',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _tile('상태', r.reservationStatus ?? '-'),
                          _tile('예약 번호', widget.reservationIdx.toString()),
                          _tile('숙소 ID', r.reservedHomeId.toString()),
                          _tile('인원 (성인/아동/반려)', '${r.adult}/${r.child}/${r.pet}'),
                          _tile('입실 / 퇴실', '${_d(r.startDate)}  ~  ${_d(r.endDate)}'),
                          _tile('총 결제 금액', _money(r.totalMoney)),
                          _tile('결제 수단', r.payby ?? '-'),
                          if (r.bank != null && r.bank!.isNotEmpty) _tile('입금 은행', r.bank!),
                          if (r.account != null && r.account!.toString().isNotEmpty) _tile('계좌', r.account.toString()),
                          if (r.message != null && r.message!.isNotEmpty) _tile('요청 메시지', r.message!),
                          if (r.memoForCheckIn != null && r.memoForCheckIn!.isNotEmpty) _tile('체크인 메모', r.memoForCheckIn!),
                          if (r.memoForCheckOut != null && r.memoForCheckOut!.isNotEmpty) _tile('체크아웃 메모', r.memoForCheckOut!),
                          if (r.memoForHost != null && r.memoForHost!.isNotEmpty) _tile('호스트 메모', r.memoForHost!),
                          if (r.cancelMessage != null && r.cancelMessage!.isNotEmpty) _tile('취소 사유', r.cancelMessage!),
                          if (r.merchantUid != null && r.merchantUid!.isNotEmpty) _tile('주문번호', r.merchantUid!),
                          if (r.impUid != null && r.impUid!.isNotEmpty) _tile('아임포트 UID', r.impUid!),
                          if (r.reservedDate != null) _tile('예약일', _d(r.reservedDate!)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('목록으로 돌아가기'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4DB2FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _d(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';
  String _2(int n) => n.toString().padLeft(2, '0');
  String _money(int w) => '${w.toString()}원';
}
