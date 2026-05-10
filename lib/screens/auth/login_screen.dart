import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nisController = TextEditingController();
  final FocusNode _nisFocusNode = FocusNode();

  bool _isVisible = false;
  bool _isButtonPushed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _nisController.dispose();
    _nisFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _mintaSemuaIzin() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mohon aktifkan GPS/Lokasi Anda terlebih dahulu!'),
              backgroundColor: Colors.orange),
        );
      }
      return false;
    }

    Permission storagePermission = Permission.storage;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        storagePermission = Permission.photos;
      }
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      storagePermission,
    ].request();

    if (statuses[Permission.location] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Akses lokasi dasar ditolak. Login dibatalkan.'),
              backgroundColor: Colors.red),
        );
      }
      return false;
    }

    PermissionStatus statusBackground = await Permission.locationAlways.status;

    if (!statusBackground.isGranted) {
      statusBackground = await Permission.locationAlways.request();

      if (!statusBackground.isGranted) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('Akses Dibatasi',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ],
              ),
              content: const Text(
                  'Sistem keamanan mewajibkan izin lokasi "Izinkan Sepanjang Waktu" (Allow all the time) agar radar presensi berfungsi.\n\nSilakan buka Pengaturan HP Anda dan perbarui izin lokasi aplikasi ini.',
                  style: TextStyle(fontSize: 14, height: 1.5)),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  void _prosesLogin() async {
    final nis = _nisController.text.trim();

    if (nis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIS tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _nisFocusNode.unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorLokal = Navigator.of(context);

    bool diizinkan = await _mintaSemuaIzin();

    if (!diizinkan) {
      return;
    }

    try {
      final sukses = await authProvider.login(nis);

      if (sukses && mounted) {
        navigatorLokal.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content:
                Text(e.toString(), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Container(
            height: size.height * 0.45,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!,
                  Colors.blue[600]!,
                ],
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
                  bottom: -100,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Geofence App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistem Presensi Digital Berbasis Lokasi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: _isVisible ? 1.0 : 0.0,
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(
                            0, _isVisible ? 0 : 50, 0),
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Silakan masukkan Nomor Induk Siswa (NIS) Anda untuk melanjutkan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'NIS Siswa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nisController,
                              focusNode: _nisFocusNode,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: 2.0,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Misal: 10102030',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Icon(
                                    Icons.badge_rounded,
                                    color: _nisFocusNode.hasFocus
                                        ? Colors.blue[600]
                                        : Colors.grey[400],
                                    size: 24,
                                  ),
                                ),
                                filled: true,
                                fillColor: _nisFocusNode.hasFocus
                                    ? Colors.blue[50]
                                    : Colors.grey[50],
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.blue[600]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onTap: () => setState(() {}),
                            ),
                            const SizedBox(height: 32),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return Listener(
                                  onPointerDown: (_) {
                                    if (!authProvider.isLoading) {
                                      setState(() => _isButtonPushed = true);
                                    }
                                  },
                                  onPointerUp: (_) {
                                    if (!authProvider.isLoading) {
                                      setState(() => _isButtonPushed = false);
                                    }
                                  },
                                  child: AnimatedScale(
                                    scale: _isButtonPushed ? 0.95 : 1.0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : _prosesLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[600],
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.blue[300],
                                          elevation: 5,
                                          shadowColor: Colors.blue[600]!
                                              .withOpacity(0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 3,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Masuk Sistem',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: _isVisible ? 1.0 : 0.0,
                      child: Text(
                        'SMKN 1 TGB © 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
