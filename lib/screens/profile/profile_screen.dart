import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../core/utils/app_info_helper.dart';

import '../auth/login_screen.dart';
import '../izin/riwayat_izin_screen.dart';
import 'widgets/profile_card.dart';
import 'widgets/security_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _namaSiswa = 'Memuat...';
  String _namaKelas = 'Siswa Aktif';
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
    final kelas = await SecureStorageHelper.getUserKelas();

    if (!mounted) return;

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _fotoUrl = foto;
      _namaKelas = kelas ?? 'Siswa Aktif';
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

  // --- UI/UX UPDATE: Bottom Sheet bergaya modern (iOS Style) ---
  void _tampilkanPilihanFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                // Drag handle (Pill)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text(
                    'Pilih Sumber Foto',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87),
                  ),
                ),
                _buildBottomSheetTile(
                  icon: Icons.camera_alt_rounded,
                  color: Colors.blue,
                  title: 'Ambil dari Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _prosesUploadFoto(ImageSource.camera);
                  },
                ),
                _buildBottomSheetTile(
                  icon: Icons.photo_library_rounded,
                  color: Colors.orange,
                  title: 'Pilih dari Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _prosesUploadFoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetTile(
      {required IconData icon,
      required MaterialColor color,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
        child: Icon(icon, color: color.shade600, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Future<void> _prosesUploadFoto(ImageSource source) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final XFile? image =
          await _picker.pickImage(source: source, imageQuality: 70);
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Foto profil berhasil diperbarui!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- UI/UX UPDATE: Dialog konfirmasi yang lebih soft ---
  void _ajukanReset() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.orange[50], shape: BoxShape.circle),
                child: Icon(Icons.phonelink_erase_rounded,
                    color: Colors.orange[700], size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Reset Perangkat',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              Text(
                'Tindakan ini akan menghapus sesi lokal Anda. Untuk login di perangkat baru, Anda WAJIB meminta reset kunci perangkat (Device ID) ke Wali Kelas atau Admin.',
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text('Batal',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        Navigator.pop(dialogContext);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (loadContext) => Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                        );

                        try {
                          await authProvider.resetDeviceLokal();
                          if (!mounted) return;
                          Navigator.pop(context);

                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false);
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red[800]));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reset',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // --- UI/UX UPDATE: Premium Gradient Background Header ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 260,
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
                            color: Colors.white.withOpacity(0.05))),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -30,
                    child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04))),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(context)),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('Profil Siswa',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(width: 48), // Balancing width
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileCard(
                            namaSiswa: _namaSiswa,
                            namaKelas: _namaKelas,
                            fotoUrl: _fotoUrl,
                            isUploading: _isUploadingFoto,
                            onUploadTap: _tampilkanPilihanFoto,
                            getValidUrl: _getValidFotoUrl,
                          ),
                          const SizedBox(height: 36),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Kehadiran & Layanan',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87),
                            ),
                          ),
                          _AnimatedProfileMenu(
                            icon: Icons.assignment_turned_in_rounded,
                            title: 'Riwayat Izin & Sakit',
                            subtitle: 'Lihat status pengajuan Anda',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RiwayatIzinScreen())),
                          ),
                          const SizedBox(height: 28),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Keamanan Akun',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87),
                            ),
                          ),
                          SecurityMenu(onResetTap: _ajukanReset),
                          const SizedBox(height: 40),
                          Center(child: AppInfoHelper.buildFooter()),
                          const SizedBox(height: 30),
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
}

// --- UI/UX UPDATE: Menu dengan animasi pantulan (Bouncy Effect) ---
class _AnimatedProfileMenu extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MaterialColor color;
  final VoidCallback onTap;

  const _AnimatedProfileMenu(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  State<_AnimatedProfileMenu> createState() => _AnimatedProfileMenuState();
}

class _AnimatedProfileMenuState extends State<_AnimatedProfileMenu> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isPressed ? 0.04 : 0.08),
                blurRadius: _isPressed ? 10 : 20,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: widget.color.shade50, shape: BoxShape.circle),
                      child: Icon(widget.icon,
                          color: widget.color.shade600, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(widget.subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400], size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
