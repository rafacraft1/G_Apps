import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../../core/utils/secure_storage_helper.dart';

// Import Widget yang baru kita buat
import 'widgets/profile_card.dart';
import 'widgets/security_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _namaSiswa = 'Memuat...';
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

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _fotoUrl = foto;
    });
  }

  // === FUNGSI KONVERSI URL DARI .ENV ===
  String _getValidFotoUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return '';
    try {
      String baseUrlEnv = dotenv.env['BASE_URL'] ?? '';
      if (baseUrlEnv.isEmpty) return originalUrl;

      Uri apiUri = Uri.parse(baseUrlEnv);
      String validHost =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      Uri fotoUri = Uri.parse(originalUrl);

      return '$validHost${fotoUri.path}?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return originalUrl;
    }
  }

  // === FUNGSI UBAH FOTO PROFIL ===
  Future<void> _pilihDanUploadFoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (image == null) return;

      setState(() => _isUploadingFoto = true);
      File fileFoto = File(image.path);
      String urlBaru = await authProvider.uploadFotoProfil(fileFoto);

      if (!mounted) return;

      setState(() {
        _fotoUrl = urlBaru;
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
        SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // === FUNGSI RESET DEVICE ===
  void _ajukanReset() {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajukan Reset Device',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: alasanController,
          decoration: InputDecoration(
            hintText: 'Tuliskan alasan ganti HP...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (alasanController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Alasan tidak boleh kosong!',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red));
                return;
              }

              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.blue)),
              );

              try {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final sukses =
                    await authProvider.ajukanResetDevice(alasanController.text);

                if (!context.mounted) return;
                Navigator.pop(context);

                if (sukses) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Pengajuan berhasil dikirim! Menunggu persetujuan Admin.'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
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
          // Background Gradient
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[800]!, Colors.blue[500]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        'Profil Saya',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Konten Utama
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Memanggil Widget ProfileCard
                          ProfileCard(
                            namaSiswa: _namaSiswa,
                            fotoUrl: _fotoUrl,
                            isUploading: _isUploadingFoto,
                            onUploadTap: _pilihDanUploadFoto,
                            getValidUrl: _getValidFotoUrl,
                          ),
                          const SizedBox(height: 32),

                          // Memanggil Widget SecurityMenu
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
}
