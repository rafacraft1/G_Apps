import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/absensi_provider.dart';
import '../../core/utils/app_info_helper.dart'; // [TAMBAHAN BARU]

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final String _baseUrl = dotenv.env['BASE_URL']?.replaceAll('/api/v1', '') ??
      'http://192.168.0.105:8080';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AbsensiProvider>(context, listen: false).fetchRiwayatAbsen();
    });
  }

  Widget _buildStatusBadge(String? statusDb) {
    String text = 'Alpa';
    Color color = Colors.red[600]!;

    if (statusDb != null && statusDb.isNotEmpty) {
      if (statusDb.toLowerCase() == 'hadir' ||
          statusDb.toLowerCase() == 'hadir tepat waktu') {
        text = 'Hadir';
        color = Colors.green[600]!;
      } else if (statusDb.toLowerCase() == 'terlambat') {
        text = 'Terlambat';
        color = Colors.orange[600]!;
      } else if (statusDb.toLowerCase() == 'izin' ||
          statusDb.toLowerCase() == 'sakit') {
        text = statusDb;
        color = Colors.blue[600]!;
      } else {
        text = statusDb;
        color = Colors.grey[600]!;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailAbsen({
    required String title,
    required String? waktu,
    required String? foto,
    required String? lat,
    required String? lon,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            waktu ?? '--:--',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  (lat != null && lon != null)
                      ? '$lat\n$lon'
                      : 'Koordinat belum direkam',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600], height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: foto != null && foto.isNotEmpty
                  ? Image.network(
                      '$_baseUrl/uploads/absensi/$foto',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded,
                                color: Colors.grey[400], size: 24),
                            const SizedBox(height: 4),
                            Text('Gagal dimuat',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                          ],
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            color: Colors.grey[400], size: 24),
                        const SizedBox(height: 4),
                        Text('Belum ada foto',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Absensi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AbsensiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRiwayat) {
            return Column(
              children: [
                const Expanded(
                    child: Center(child: CircularProgressIndicator())),
                AppInfoHelper.buildFooter(),
              ],
            );
          }

          if (provider.listRiwayat.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat absensi',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                AppInfoHelper.buildFooter(),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.listRiwayat.length +
                1, // [UPDATE] +1 untuk item footer
            itemBuilder: (context, index) {
              // Render Footer jika index mencapai batas array data
              if (index == provider.listRiwayat.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(child: AppInfoHelper.buildFooter()),
                );
              }

              final item = provider.listRiwayat[index];
              String tanggalIndo = item['tanggal'] ?? '';
              if (tanggalIndo.isNotEmpty) {
                final parts = tanggalIndo.split('-');
                if (parts.length == 3) {
                  tanggalIndo = '${parts[2]}/${parts[1]}/${parts[0]}';
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tanggalIndo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusBadge(item['status']),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailAbsen(
                            title: 'Absen Masuk',
                            waktu: item['jam_masuk'],
                            foto: item['foto_masuk'],
                            lat: item['lat_masuk']?.toString(),
                            lon: item['long_masuk']?.toString(),
                            icon: Icons.login_rounded,
                            color: Colors.blue[600]!,
                          ),
                          Container(
                            width: 1,
                            height: 180,
                            color: Colors.grey[200],
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          _buildDetailAbsen(
                            title: 'Absen Pulang',
                            waktu: item['jam_pulang'],
                            foto: item['foto_pulang'],
                            lat: item['lat_pulang']?.toString(),
                            lon: item['long_pulang']?.toString(),
                            icon: Icons.logout_rounded,
                            color: Colors.orange[600]!,
                          ),
                        ],
                      ),
                      if (item['menit_telat'] != null &&
                          int.tryParse(item['menit_telat'].toString()) !=
                              null &&
                          int.parse(item['menit_telat'].toString()) > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 18, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Keterlambatan: ${item['menit_telat']} Menit',
                                style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
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
      ),
    );
  }
}
