import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../../core/utils/secure_storage_helper.dart';

import '../auth/login_screen.dart';
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

    if (!mounted) {
      return;
    }

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _fotoUrl = foto;
    });
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

  Future<void> _pilihDanUploadFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingFoto = true;
      });

      if (!mounted) {
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newUrl = await authProvider.uploadFotoProfil(File(image.path));

      if (!mounted) {
        return;
      }

      setState(() {
        _fotoUrl = newUrl;
        _isUploadingFoto = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingFoto = false;
      });

      if (!mounted) {
        return;
      }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                if (!mounted) {
                  return;
                }

                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                final sukses = await authProvider.ajukanResetDevice(alasan);

                if (!mounted) {
                  return;
                }

                Navigator.pop(context);

                if (sukses) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Pengajuan berhasil dikirim! Silakan hubungi admin.'),
                        backgroundColor: Colors.green),
                  );

                  await SecureStorageHelper.clearAll();

                  if (!mounted) {
                    return;
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (!mounted) {
                  return;
                }

                Navigator.pop(context);

                if (!mounted) {
                  return;
                }

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
                  bottomRight: Radius.circular(40),
                ),
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Profil Siswa',
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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          ProfileCard(
                            namaSiswa: _namaSiswa,
                            fotoUrl: _fotoUrl,
                            isUploading: _isUploadingFoto,
                            onUploadTap: _pilihDanUploadFoto,
                            getValidUrl: _getValidFotoUrl,
                          ),
                          const SizedBox(height: 32),
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
