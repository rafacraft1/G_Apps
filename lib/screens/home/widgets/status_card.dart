import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class StatusCard extends StatelessWidget {
  final bool isMemuat;
  final String statusHadir;
  final Color statusHadirColor;
  final DateTime? waktuServer;
  final String jamMasukServer;
  final String jamPulangServer;

  // Parameter Lokasi
  final double? jarakMeter;
  final bool isMemuatLokasi;

  const StatusCard({
    super.key,
    required this.isMemuat,
    required this.statusHadir,
    required this.statusHadirColor,
    required this.waktuServer,
    required this.jamMasukServer,
    required this.jamPulangServer,
    required this.jarakMeter,
    required this.isMemuatLokasi,
  });

  String _formatJamMenit(String jamLengkap) {
    try {
      final parts = jamLengkap.split(':');
      return "${parts[0]}:${parts[1]}";
    } catch (e) {
      return jamLengkap;
    }
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(4))),
    );
  }

  Widget _buildInfoJam(
      IconData icon, String label, String waktu, MaterialColor color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color[700], size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jam $label',
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(waktu,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Hari Ini',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      isMemuat
                          ? _buildShimmer(width: 100, height: 24)
                          : Text(statusHadir,
                              style: TextStyle(
                                  color: statusHadirColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Waktu Server',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    isMemuat || waktuServer == null
                        ? _buildShimmer(width: 60, height: 24)
                        : Text(
                            "${waktuServer!.hour.toString().padLeft(2, '0')}:${waktuServer!.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1, color: Colors.black12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoJam(
                    Icons.login_rounded,
                    'Masuk',
                    isMemuat ? '--:--' : _formatJamMenit(jamMasukServer),
                    Colors.blue),
                Container(width: 1, height: 40, color: Colors.black12),
                _buildInfoJam(
                    Icons.logout_rounded,
                    'Pulang',
                    isMemuat ? '--:--' : _formatJamMenit(jamPulangServer),
                    Colors.orange),
              ],
            ),

            // === INDIKATOR JARAK LOKASI (MINIMALIS) ===
            const SizedBox(height: 16),
            isMemuatLokasi
                ? _buildShimmer(width: 120, height: 12)
                : Text(
                    jarakMeter != null
                        ? 'Jarak perangkat dari sekolah: ${jarakMeter!.toStringAsFixed(1)} meter'
                        : 'Gagal mendeteksi lokasi Anda',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: jarakMeter == null ? Colors.red : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
            // ===========================================
          ],
        ),
      ),
    );
  }
}
