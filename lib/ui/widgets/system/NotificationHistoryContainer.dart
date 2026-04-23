import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

class NotificationHistoryContainer extends StatefulWidget {
  const NotificationHistoryContainer({super.key});

  @override
  State<NotificationHistoryContainer> createState() =>
      _NotificationHistoryContainerState();
}

class _NotificationHistoryContainerState
    extends State<NotificationHistoryContainer> {
  // Dummy data notifikasi (manual, lebih banyak biar bisa scroll)
  final List<Map<String, String>> _notifications = [
    {
      "title": "Pengumuman Ujian",
      "message": "Ujian tengah semester akan dimulai Senin depan.",
      "time": "10:30"
    },
    {
      "title": "Tugas Baru",
      "message": "Matematika: Kerjakan soal halaman 45-47.",
      "time": "09:15"
    },
    {
      "title": "Absensi",
      "message": "Hari ini kamu hadir tepat waktu.",
      "time": "07:00"
    },
    {
      "title": "Pengumuman Libur",
      "message": "Sekolah akan diliburkan pada tanggal 25 September.",
      "time": "16:45"
    },
    {
      "title": "Kegiatan Ekstrakurikuler",
      "message": "Latihan basket akan diadakan pukul 15:00 di lapangan.",
      "time": "14:20"
    },
    {
      "title": "Tagihan SPP",
      "message": "Segera lakukan pembayaran SPP bulan ini sebelum tanggal 10.",
      "time": "12:00"
    },
    {
      "title": "Pengumpulan Tugas",
      "message": "Deadline pengumpulan tugas IPA sampai hari Jumat.",
      "time": "11:40"
    },
    {
      "title": "Rapat Orang Tua",
      "message": "Undangan rapat orang tua pada Sabtu, 28 September.",
      "time": "08:50"
    },
    {
      "title": "Jadwal Ulangan Harian",
      "message": "Ulangan harian Bahasa Inggris akan diadakan besok.",
      "time": "17:10"
    },
    {
      "title": "Prestasi Siswa",
      "message": "Selamat kepada tim olimpiade yang meraih juara 1!",
      "time": "19:00"
    },
  ];

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              "Riwayat Notifikasi",
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, String> notif) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(2, 2),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active_rounded, // pakai icon bawaan
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif["title"] ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif["message"] ?? "",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Text(
            notif["time"] ?? "",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return const Center(child: Text("Belum ada notifikasi"));
    }
    return Column(
      children:
          _notifications.map((notif) => _buildNotificationItem(notif)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 140, bottom: 80),
          child: _buildNotificationList(),
        ),
        _buildAppBar(),
      ],
    );
  }
}
