import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final bool isMemuat;
  final String statusHadir;
  final Color statusHadirColor;
  final DateTime? waktuServer;
  final String jamMasukServer;
  final String jamPulangServer;
  final double? jarakMeter;
  final bool isMemuatLokasi;
  final String namaZona;

  // [TAMBAHAN BARU] Parameter untuk Tombol Absen terintegrasi
  final bool isTombolDisable;
  final Color warnaTombol;
  final IconData iconTombol;
  final String labelTombol;
  final String subLabel;
  final VoidCallback onAbsenTap;

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
    required this.namaZona,
    required this.isTombolDisable,
    required this.warnaTombol,
    required this.iconTombol,
    required this.labelTombol,
    required this.subLabel,
    required this.onAbsenTap,
  });

  @override
  Widget build(BuildContext context) {
    bool diDalamArea = jarakMeter != null && jarakMeter! <= 50.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Hari Ini',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
                isMemuat
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusHadirColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusHadirColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            statusHadir,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusHadirColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    icon: Icons.login_rounded,
                    title: 'Jam Masuk',
                    time: jamMasukServer.substring(0, 5),
                    color: Colors.blue[600]!,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                Expanded(
                  child: _buildTimeInfo(
                    icon: Icons.logout_rounded,
                    title: 'Jam Pulang',
                    time: jamPulangServer.substring(0, 5),
                    color: Colors.orange[600]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Indikator Radar Lokasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMemuatLokasi
                          ? Colors.grey[200]
                          : (diDalamArea ? Colors.green[100] : Colors.red[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      size: 20,
                      color: isMemuatLokasi
                          ? Colors.grey[500]
                          : (diDalamArea ? Colors.green[700] : Colors.red[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaZona,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        isMemuatLokasi
                            ? const Text('Mencari sinyal satelit...',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black54))
                            : Text(
                                jarakMeter != null
                                    ? '${jarakMeter!.toStringAsFixed(1)} m dari pusat zona'
                                    : 'Akses GPS ditolak',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: diDalamArea
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w600),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // [TAMBAHAN BARU] Tombol Presensi terintegrasi di dalam Card
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onAbsenTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaTombol,
                  foregroundColor: Colors.white,
                  elevation: isTombolDisable ? 0 : 2,
                  shadowColor: warnaTombol.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iconTombol,
                        color: isTombolDisable ? Colors.white70 : Colors.white),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(labelTombol,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isTombolDisable
                                    ? Colors.white70
                                    : Colors.white)),
                        Text(subLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: isTombolDisable
                                    ? Colors.white60
                                    : Colors.white70)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
      {required IconData icon,
      required String title,
      required String time,
      required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
              Text(time,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }
}
