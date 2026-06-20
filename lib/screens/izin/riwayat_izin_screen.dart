import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_provider.dart';
import '../../core/utils/app_info_helper.dart'; // [TAMBAHAN BARU]

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Izin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<IzinProvider>(
        builder: (context, provider, child) {
          if (provider.listRiwayat.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(child: Text('Belum ada data pengajuan izin.')),
                ),
                AppInfoHelper.buildFooter(), // Menempel di bawah jika kosong
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.listRiwayat.length +
                1, // [UPDATE] +1 untuk item footer
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Jika ini index terakhir, render Footer
              if (index == provider.listRiwayat.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(child: AppInfoHelper.buildFooter()),
                );
              }

              final item = provider.listRiwayat[index];
              Color statusColor = Colors.orange;
              if (item['status'] == 'Approved') statusColor = Colors.green;
              if (item['status'] == 'Rejected') statusColor = Colors.red;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03), blurRadius: 10)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(item['jenis'],
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        Text(
                          item['status'],
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item['alasan'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      "${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}",
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const Divider(height: 24),
                    Text(
                      "Diajukan pada: ${item['created_at']}",
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontStyle: FontStyle.italic),
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
