import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../profile/profile_screen.dart';

class HomeHeader extends StatelessWidget {
  final String namaSiswa;
  final String? fotoUrl;
  final DateTime? waktuServer;
  final VoidCallback onRiwayatTap;
  final VoidCallback onLogoutTap;

  // PERBAIKAN: Tambahkan parameter callback untuk trigger refresh dari HomeScreen
  final VoidCallback onRefreshProfile;

  const HomeHeader({
    super.key,
    required this.namaSiswa,
    this.fotoUrl,
    required this.waktuServer,
    required this.onRiwayatTap,
    required this.onLogoutTap,
    required this.onRefreshProfile, // Wajibkan parameter ini
  });

  String _formatTanggalSingkat(DateTime dt) {
    List<String> bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return "${dt.day} ${bulan[dt.month - 1]} ${dt.year}";
  }

  String _getValidFotoUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return '';
    try {
      String baseUrlEnv = dotenv.env['BASE_URL'] ?? '';
      if (baseUrlEnv.isEmpty) return originalUrl;

      Uri apiUri = Uri.parse(baseUrlEnv);
      String validHost =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      Uri fotoUri = Uri.parse(originalUrl);

      return '$validHost${fotoUri.path}';
    } catch (e) {
      return originalUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waktuServer != null
                        ? _formatTanggalSingkat(waktuServer!)
                        : 'Memuat...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text('Geofence App',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ],
              ),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                        icon: const Icon(Icons.history_rounded,
                            color: Colors.white, size: 20),
                        onPressed: onRiwayatTap,
                        tooltip: 'Riwayat Absensi'),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 20),
                        onPressed: onLogoutTap,
                        tooltip: 'Keluar'),
                  ),
                ],
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  // PERBAIKAN: Pindah halaman, lalu jalankan fungsi refresh setelah kembali
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()));

                  // Panggil fungsi setState dari HomeScreen untuk memperbarui foto UI
                  onRefreshProfile();
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  backgroundImage: fotoUrl != null && fotoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(_getValidFotoUrl(fotoUrl))
                      : null,
                  child: fotoUrl == null || fotoUrl!.isEmpty
                      ? Text(
                          namaSiswa.isNotEmpty
                              ? namaSiswa.substring(0, 1).toUpperCase()
                              : 'S',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800]))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat Datang,',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(namaSiswa,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
