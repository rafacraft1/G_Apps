import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_provider.dart';
import '../../core/utils/app_info_helper.dart';

class RiwayatIzinScreen extends StatefulWidget {
  const RiwayatIzinScreen({super.key});

  @override
  State<RiwayatIzinScreen> createState() => _RiwayatIzinScreenState();
}

class _RiwayatIzinScreenState extends State<RiwayatIzinScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<IzinProvider>(context, listen: false).fetchRiwayatIzin());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Riwayat Izin',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.3)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<IzinProvider>(
        builder: (context, provider, child) {
          if (provider.listRiwayat.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.blue[50], shape: BoxShape.circle),
                  child: Icon(Icons.folder_open_rounded,
                      size: 64, color: Colors.blue[300]),
                ),
                const SizedBox(height: 16),
                const Text('Belum ada riwayat pengajuan.',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: AppInfoHelper.buildFooter(),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: provider.listRiwayat.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == provider.listRiwayat.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Center(child: AppInfoHelper.buildFooter()),
                );
              }

              final item = provider.listRiwayat[index];

              // Styling Dinamis Berdasarkan Status
              Color statusBgColor = Colors.orange[50]!;
              Color statusTextColor = Colors.orange[800]!;
              IconData statusIcon = Icons.hourglass_empty_rounded;

              if (item['status'] == 'Approved') {
                statusBgColor = Colors.green[50]!;
                statusTextColor = Colors.green[700]!;
                statusIcon = Icons.check_circle_rounded;
              } else if (item['status'] == 'Rejected') {
                statusBgColor = Colors.red[50]!;
                statusTextColor = Colors.red[700]!;
                statusIcon = Icons.cancel_rounded;
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kategori Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['jenis'] == 'Sakit'
                                    ? Icons.medical_services_outlined
                                    : (item['jenis'] == 'Izin'
                                        ? Icons.assignment_outlined
                                        : Icons.verified_outlined),
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(item['jenis'],
                                  style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 14, color: statusTextColor),
                              const SizedBox(width: 4),
                              Text(
                                item['status'],
                                style: TextStyle(
                                    color: statusTextColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(item['alasan'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.3)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          "${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}",
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          "Diajukan: ${item['created_at']}",
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
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
}
