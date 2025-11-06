import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models/reservation.dart';
import '../models/home.dart';
import 'my_reservation_detail.dart';

class MyReservationListPage extends StatefulWidget {
  final ApiClient api;
  const MyReservationListPage({super.key, required this.api});

  @override
  State<MyReservationListPage> createState() => _MyReservationListPageState();
}

class _MyReservationListPageState extends State<MyReservationListPage> {
  late Future<List<Reservation>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchMyReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          '내 예약 내역',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('에러 발생: ${snap.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                '예약 내역이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];

              return FutureBuilder<Home>(
                future: widget.api.fetchHomeBrief(r.reservedHomeId),
                builder: (context, hSnap) {
                  final home = hSnap.data;
                  final thumb = (home?.thumbnail != null)
                      ? widget.api.makeImgUrl(home!.thumbnail)
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyReservationDetailPage(
                            api: widget.api,
                            reservationIdx: r.reservationIdx,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ 이미지 영역 (비율 & 둥근 모서리 개선)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: thumb == null
                                ? Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.home_outlined, size: 50, color: Colors.grey),
                              ),
                            )
                                : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.home_outlined, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ✅ 텍스트 영역
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  home?.title ?? '숙소 ${r.reservedHomeId}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (home?.address?.isNotEmpty == true)
                                  Text(
                                    home!.address!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                Text('입실: ${_d(r.startDate)}',
                                    style: const TextStyle(fontSize: 13)),
                                Text('퇴실: ${_d(r.endDate)}',
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(
                                  '결제: ${r.payby} | ${_money(r.totalMoney)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    r.reservedDate != null ? _d(r.reservedDate!) : '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _d(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';
  String _2(int n) => n.toString().padLeft(2, '0');
  String _money(int w) => '${w.toString()}원';
}
