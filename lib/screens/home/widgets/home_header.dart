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

  // TAHAP 3: Variabel static untuk menyimpan URL agar tidak diproses berulang kali
  static String? _cachedHost;

  String _formatWaktuLengkap(DateTime dt) {
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

    String namaHari = hari[dt.weekday - 1];
    String jam = dt.hour.toString().padLeft(2, '0');
    String menit = dt.minute.toString().padLeft(2, '0');
    String detik = dt.second.toString().padLeft(2, '0');

    return "$namaHari, ${dt.day} ${bulan[dt.month - 1]} ${dt.year} • $jam:$menit:$detik";
  }

  String _getValidFotoUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    if (fileName.startsWith('http')) return fileName;

    // TAHAP 3: Cek apakah host sudah tersimpan di memori (cache)
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

    // Langsung gabungkan dengan cache, jauh lebih cepat!
    return '$_cachedHost/uploads/siswa/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 130),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[900]!, Colors.blue[600]!],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ValueListenableBuilder<DateTime?>(
                        valueListenable: waktuServerNotifier,
                        builder: (context, waktu, child) {
                          return Text(
                            waktu != null
                                ? _formatWaktuLengkap(waktu)
                                : 'Menghubungkan...',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionBtn(
                      Icons.history_rounded, onRiwayatTap, 'Riwayat'),
                  const SizedBox(width: 8),
                  _buildActionBtn(Icons.logout_rounded, onLogoutTap, 'Keluar'),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              fotoUrl != null && fotoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      _getValidFotoUrl(fotoUrl))
                                  : null,
                          child: fotoUrl == null || fotoUrl!.isEmpty
                              ? Text(
                                  namaSiswa.isNotEmpty
                                      ? namaSiswa.substring(0, 1).toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800]),
                                )
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
                        Text('Selamat Datang,',
                            style: TextStyle(
                                color: Colors.blue[100], fontSize: 14)),
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
                        Text(
                          namaKelas != 'Siswa Aktif'
                              ? 'Kelas $namaKelas'
                              : 'Siswa Aktif',
                          style: TextStyle(
                              color: Colors.blue[50]!.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
