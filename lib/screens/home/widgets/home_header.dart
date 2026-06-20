import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../profile/profile_screen.dart';

class HomeHeader extends StatelessWidget {
  final String namaSiswa;
  final String namaKelas;
  final String? fotoUrl;
  final ValueNotifier<DateTime?> waktuServerNotifier;
  final VoidCallback onRiwayatTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onRefreshProfile;

  const HomeHeader({
    super.key,
    required this.namaSiswa,
    required this.namaKelas,
    this.fotoUrl,
    required this.waktuServerNotifier,
    required this.onRiwayatTap,
    required this.onLogoutTap,
    required this.onRefreshProfile,
  });

  static String? _cachedHost;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi,';
    if (hour >= 11 && hour < 15) return 'Selamat Siang,';
    if (hour >= 15 && hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  String _formatTanggal(DateTime dt) {
    List<String> hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
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
    return "${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}";
  }

  String _formatJam(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  String _getValidFotoUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    if (fileName.startsWith('http')) return fileName;

    if (_cachedHost == null) {
      try {
        String baseUrlEnv = dotenv.env['BASE_URL'] ?? '';
        if (baseUrlEnv.isEmpty) return fileName;
        Uri apiUri = Uri.parse(baseUrlEnv);
        _cachedHost =
            '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      } catch (e) {
        return fileName;
      }
    }
    return '$_cachedHost/uploads/siswa/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // [SOLUSI UTAMA] Padding bottom dipatok di 80px sebagai ruang biru.
      // Nantinya akan ditimpa oleh StatusCard sejauh 45px, menyisakan 35px batas biru dengan Avatar.
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[900]!, Colors.blue[600]!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: ValueListenableBuilder<DateTime?>(
                            valueListenable: waktuServerNotifier,
                            builder: (context, waktu, child) {
                              if (waktu == null) {
                                return const Text('Menghubungkan...',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600));
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatTanggal(waktu),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(_formatJam(waktu),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionBtn(
                          Icons.history_rounded, onRiwayatTap, 'Riwayat'),
                      const SizedBox(width: 8),
                      _buildActionBtn(
                          Icons.logout_rounded, onLogoutTap, 'Keluar',
                          isDanger: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()));
                          onRefreshProfile();
                        },
                        child: Hero(
                          tag: 'profil_avatar',
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  fotoUrl != null && fotoUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          _getValidFotoUrl(fotoUrl))
                                      : null,
                              child: fotoUrl == null || fotoUrl!.isEmpty
                                  ? Text(
                                      namaSiswa.isNotEmpty
                                          ? namaSiswa
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800]))
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(),
                                style: TextStyle(
                                    color: Colors.blue[100],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(
                              namaSiswa,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                namaKelas != 'Siswa Aktif'
                                    ? 'Kelas $namaKelas'
                                    : 'Siswa Aktif',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap, String tooltip,
      {bool isDanger = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDanger
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
            color: isDanger
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isDanger ? Colors.red[100] : Colors.white, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}
