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
          // [UI/UX UPDATE] Bayangan lebih soft dan modern
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusHadirColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusHadirColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusHadir,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: statusHadirColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18.0),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
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
                Container(width: 1, height: 45, color: Colors.grey[200]),
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
            const SizedBox(height: 24),

            // Indikator Radar Lokasi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: diDalamArea ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        diDalamArea ? Colors.green[200]! : Colors.grey[200]!),
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
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
            const SizedBox(height: 24),

            // [UI/UX UPDATE] Tombol Absen dengan Efek Gradient dan Bayangan
            Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isTombolDisable
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[400]!])
                    : LinearGradient(
                        colors: [warnaTombol, warnaTombol.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  if (!isTombolDisable)
                    BoxShadow(
                      color: warnaTombol.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isTombolDisable ? onAbsenTap : onAbsenTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconTombol, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labelTombol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.5)),
                          Text(subLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70)),
                        ],
                      )
                    ],
                  ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(time,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87),
                  maxLines: 1),
            ],
          ),
        )
      ],
    );
  }
}
