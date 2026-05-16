import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../../core/utils/secure_storage_helper.dart';

import '../auth/login_screen.dart';
import '../izin/riwayat_izin_screen.dart'; // Import layar riwayat izin
import 'widgets/profile_card.dart';
import 'widgets/security_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _namaSiswa = 'Memuat...';
  String _namaKelas =
      'Siswa Aktif'; // PENAMBAHAN: State untuk menampung nama kelas
  String? _fotoUrl;
  bool _isUploadingFoto = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final nama = await SecureStorageHelper.getUserName();
    final foto = await SecureStorageHelper.getFotoProfile();
    final kelas = await SecureStorageHelper
        .getUserKelas(); // PENAMBAHAN: Ambil data kelas dari storage

    if (!mounted) return;

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _fotoUrl = foto;
      _namaKelas = kelas ?? 'Siswa Aktif'; // PENAMBAHAN: Set state kelas
    });
  }

  String _getValidFotoUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    if (fileName.startsWith('http')) return fileName;
    try {
      String baseUrlEnv = dotenv.env['BASE_URL'] ?? '';
      if (baseUrlEnv.isEmpty) return fileName;

      Uri apiUri = Uri.parse(baseUrlEnv);
      String validHost =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';

      return '$validHost/uploads/siswa/$fileName';
    } catch (e) {
      return fileName;
    }
  }

  Future<void> _pilihDanUploadFoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      if (!mounted) return;
      setState(() => _isUploadingFoto = true);

      final newUrl = await authProvider.uploadFotoProfil(File(image.path));

      if (!mounted) return;
      setState(() {
        _fotoUrl = newUrl;
        _isUploadingFoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _ajukanReset() {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Penguncian HP?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fitur ini digunakan jika Anda berganti HP. Admin akan mereview permohonan Anda sebelum disetujui.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alasanController,
              decoration: InputDecoration(
                labelText: 'Alasan Ganti HP',
                hintText: 'Contoh: HP lama rusak',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final alasan = alasanController.text.trim();
              if (alasan.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan wajib diisi!')),
                );
                return;
              }

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);

              Navigator.pop(dialogContext);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final sukses = await authProvider.ajukanResetDevice(alasan);

                if (!mounted) return;
                Navigator.pop(context);

                if (sukses) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Pengajuan berhasil dikirim! Silakan hubungi admin.'),
                        backgroundColor: Colors.green),
                  );
                  await SecureStorageHelper.clearAll();

                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false);
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white),
            child: const Text('Kirim Pengajuan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      const Text('Profil Siswa',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileCard(
                            namaSiswa: _namaSiswa,
                            namaKelas:
                                _namaKelas, // PENAMBAHAN: Lempar parameter nama kelas ke widget ProfileCard
                            fotoUrl: _fotoUrl,
                            isUploading: _isUploadingFoto,
                            onUploadTap: _pilihDanUploadFoto,
                            getValidUrl: _getValidFotoUrl,
                          ),
                          const SizedBox(height: 32),

                          // --- TAMBAHAN: MENU PERIZINAN ---
                          const Text(
                            'Kehadiran & Izin',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            icon: Icons.assignment_turned_in_rounded,
                            title: 'Riwayat Izin & Sakit',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RiwayatIzinScreen())),
                          ),
                          const SizedBox(height: 32),
                          // -------------------------------

                          SecurityMenu(onResetTap: _ajukanReset),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk menu item agar kode tetap bersih (Clean Code)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.blue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.grey, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
