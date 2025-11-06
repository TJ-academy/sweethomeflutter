import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models/reservation.dart';
import '../models/home.dart'; // ✅ 홈 모델 임포트 필수

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
      appBar: AppBar(title: const Text('내 예약 내역')),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('에러: ${snap.error}'));

          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('예약 내역이 없습니다.'));

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = items[i];

              return FutureBuilder<Home>(
                future: widget.api.fetchHomeBrief(r.reservedHomeId),
                builder: (context, hSnap) {
                  final home = hSnap.data;
                  final thumb = (home?.thumbnail != null)
                      ? widget.api.makeImgUrl(home!.thumbnail)
                      : null;

                  return ListTile(
                    leading: SizedBox(
                      width: 56, height: 56,
                      child: thumb == null
                          ? const Icon(Icons.home_outlined, size: 32)
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.home_outlined),
                        ),
                      ),
                    ),
                    title: Text(home?.title ?? '숙소 ${r.reservedHomeId}'),
                    subtitle: Text([
                      if (home?.address?.isNotEmpty == true) home!.address!,
                      '입실 ${_d(r.startDate)} ~ 퇴실 ${_d(r.endDate)}',
                      '결제: ${r.payby} • ${_money(r.totalMoney)}',
                    ].join('\n')),
                    trailing: Text(r.reservedDate != null ? _d(r.reservedDate!) : '-'),
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
