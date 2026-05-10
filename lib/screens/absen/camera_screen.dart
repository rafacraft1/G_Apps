import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../core/utils/location_helper.dart';
import '../../providers/absensi_provider.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../auth/login_screen.dart';

class CameraScreen extends StatefulWidget {
  final String tipeAbsen;
  final double latSekolah;
  final double lonSekolah;
  final double radius;

  const CameraScreen({
    super.key,
    required this.tipeAbsen,
    required this.latSekolah,
    required this.lonSekolah,
    required this.radius,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  Position? _posisi;

  String _statusLoading = "Mencari Satelit GPS...";

  @override
  void initState() {
    super.initState();
    _initCameraAndLocation();
  }

  Future<void> _initCameraAndLocation() async {
    try {
      if (mounted) {
        setState(() => _statusLoading = "Memindai Titik Koordinat Anda...");
      }
      _posisi = await LocationHelper.getCurrentLocation();

      if (mounted) {
        setState(() => _statusLoading = "Menghitung Jarak ke Sekolah...");
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      double jarak = Geolocator.distanceBetween(
        _posisi!.latitude,
        _posisi!.longitude,
        widget.latSekolah,
        widget.lonSekolah,
      );

      if (jarak > widget.radius) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.location_off_rounded,
                      color: Colors.red, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('Di Luar Jangkauan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            content: Text(
              "Tidak dapat melakukan absensi. Jarak Anda saat ini ${jarak.round()} meter dari batas sekolah (Maksimal: ${widget.radius.round()}m).",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Kembali ke Home
                  },
                  child: const Text('Mengerti',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        );
        return;
      }

      if (mounted) {
        setState(() => _statusLoading = "Menghubungkan ke Lensa Kamera...");
      }
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium,
          enableAudio: false);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _ambilFoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;

      _tampilkanPreviewAbsen(
          File(file.path), _posisi!.latitude, _posisi!.longitude);
    } catch (e) {
      debugPrint('Error ambil foto: $e');
    }
  }

  void _tampilkanPreviewAbsen(File foto, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.tipeAbsen == 'masuk'
                    ? 'Konfirmasi Absen Masuk'
                    : 'Konfirmasi Absen Pulang',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: Image.file(foto,
                        width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Koordinat Anda:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Lat: $lat\nLon: $lon',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Foto Ulang'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final absenProvider = Provider.of<AbsensiProvider>(
                            context,
                            listen: false);

                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigatorRoot =
                            Navigator.of(context, rootNavigator: true);
                        final navigatorLokal = Navigator.of(context);

                        // 1. Tutup BottomSheet Preview Foto
                        Navigator.pop(sheetContext);

                        // 2. Tampilkan Dialog Loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          useRootNavigator: true,
                          builder: (BuildContext dialogContext) => Center(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 24),
                                      Text('Mengirim Data...',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))
                                    ]),
                              ),
                            ),
                          ),
                        );

                        try {
                          // === PERBAIKAN: Menambahkan argumen isMocked di sini ===
                          final sukses = await absenProvider.kirimAbsen(
                            foto: foto,
                            lat: lat,
                            lon: lon,
                            isMocked:
                                _posisi?.isMocked ?? false, // Deteksi Fake GPS
                            tipeAbsen: widget.tipeAbsen,
                          );

                          // 3. Tutup Dialog Loading secara aman
                          navigatorRoot.pop();

                          if (sukses && mounted) {
                            // 4. Tutup CameraScreen
                            navigatorLokal.pop();

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Absen ${widget.tipeAbsen} berhasil tersimpan!'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          // Tutup Dialog Loading secara aman JIKA TERJADI ERROR
                          navigatorRoot.pop();

                          if (mounted) {
                            String pesanError = e.toString();

                            // === TAMBAHAN: Tampilkan Peringatan Khusus Jika Fake GPS Terdeteksi ===
                            if (pesanError.toLowerCase().contains('fake gps') ||
                                pesanError.toLowerCase().contains('diblokir')) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning_rounded,
                                          color: Colors.red, size: 28),
                                      SizedBox(width: 8),
                                      Text('Pelanggaran Keamanan',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                  content: Text(
                                    pesanError,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white),
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Tutup dialog peringatan
                                        navigatorLokal
                                            .pop(); // Keluar dari layar kamera kembali ke Home
                                      },
                                      child: const Text('Mengerti'),
                                    )
                                  ],
                                ),
                              );
                              return; // Hentikan eksekusi setelah menampilkan dialog
                            }

                            // Jika error biasa (bukan Fake GPS), tampilkan SnackBar
                            scaffoldMessenger.showSnackBar(SnackBar(
                                content: Text(pesanError),
                                backgroundColor: Colors.red));

                            // Auto-Logout jika Sesi Expired
                            if (pesanError.toLowerCase().contains('token') ||
                                pesanError.toLowerCase().contains('sesi')) {
                              await SecureStorageHelper.clearAll();

                              if (mounted) {
                                navigatorLokal.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: widget.tipeAbsen == 'masuk'
                            ? Colors.blue[600]
                            : Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          'Kirim Absen ${widget.tipeAbsen == 'masuk' ? 'Masuk' : 'Pulang'}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.tipeAbsen == 'masuk'
            ? 'Foto Absen Masuk'
            : 'Foto Absen Pulang'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Lottie.asset(
                      'assets/animations/location_scan.json',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.blue));
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _statusLoading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: widget.tipeAbsen == 'masuk'
                                    ? Colors.blue
                                    : Colors.orange,
                                width: 3)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: _isCameraInitialized && _controller != null
                              ? SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                        width: 100,
                                        height: 100 *
                                            _controller!.value.aspectRatio,
                                        child: CameraPreview(_controller!)),
                                  ),
                                )
                              : const Center(
                                  child: Text('Kamera tidak tersedia',
                                      style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  child: GestureDetector(
                    onTap: _ambilFoto,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: (widget.tipeAbsen == 'masuk'
                                  ? Colors.blue
                                  : Colors.orange)
                              .withOpacity(0.8)),
                      child: const Center(
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 36)),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
