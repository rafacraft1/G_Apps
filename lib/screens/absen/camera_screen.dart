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
  bool _isFakeGpsDetected = false;
  String _statusLoading = "Mencari Satelit GPS...";

  // Detektor Mode Dispensasi & Jenis Absen
  late bool isDispensasi;
  late bool isMasuk;

  @override
  void initState() {
    super.initState();
    isDispensasi = widget.tipeAbsen.contains('dispensasi');
    isMasuk = widget.tipeAbsen.contains('masuk');
    _initCameraAndLocation();
  }

  Future<void> _initCameraAndLocation() async {
    try {
      if (mounted) {
        setState(() => _statusLoading = "Memindai Titik Koordinat Anda...");
      }

      Map<String, dynamic> locationData =
          await LocationHelper.getCurrentLocationWithMockStatus();
      _posisi = locationData['position'] as Position;
      _isFakeGpsDetected = locationData['is_mocked'] as bool;

      if (mounted) {
        setState(() => _statusLoading = "Menghitung Jarak Jangkauan...");
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      double jarak = Geolocator.distanceBetween(
        _posisi!.latitude,
        _posisi!.longitude,
        widget.latSekolah,
        widget.lonSekolah,
      );

      // =========================================================
      // BYPASS GEOFENCING: Jika Dispensasi, abaikan validasi jarak
      // =========================================================
      if (jarak > widget.radius && !isDispensasi) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _tampilkanPesanLuarArea(jarak);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error GPS: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _tampilkanPesanLuarArea(double jarak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.location_off_rounded,
                  color: Colors.red, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Di Luar Jangkauan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(
          "Tidak dapat melakukan absensi. Jarak Anda saat ini ${jarak.round()} meter dari sekolah (Maks: ${widget.radius.round()}m).",
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
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
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Kembali',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
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
    Color temaWarna = isMasuk
        ? (isDispensasi ? Colors.teal : Colors.blue[600]!)
        : Colors.orange[600]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text(
                isDispensasi
                    ? (isMasuk
                        ? 'Verifikasi Bukti Kehadiran'
                        : 'Verifikasi Selesai Tugas')
                    : (isMasuk
                        ? 'Verifikasi Absen Masuk'
                        : 'Verifikasi Absen Pulang'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: Image.file(foto,
                          width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: temaWarna.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(
                          isDispensasi
                              ? Icons.pin_drop_rounded
                              : Icons.my_location_rounded,
                          color: temaWarna),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              isDispensasi
                                  ? 'Lokasi Kegiatan Luar'
                                  : 'Data Lokasi (Terverifikasi)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Lat: $lat',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          Text('Lon: $lon',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Foto Ulang',
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
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

                        Navigator.pop(sheetContext);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          useRootNavigator: true,
                          builder: (BuildContext dialogContext) => Center(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 32),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          color: temaWarna),
                                      const SizedBox(height: 24),
                                      const Text('Mengirim Data...',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16))
                                    ]),
                              ),
                            ),
                          ),
                        );

                        try {
                          final sukses = await absenProvider.kirimAbsen(
                            foto: foto,
                            lat: lat,
                            lon: lon,
                            isMocked: _isFakeGpsDetected,
                            tipeAbsen: isMasuk ? 'masuk' : 'pulang',
                          );

                          navigatorRoot.pop();
                          if (sukses && mounted) {
                            navigatorLokal.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                // PERBAIKAN: Penambahan const di sini untuk mengatasi linter
                                content:
                                    const Text('Absen berhasil tersimpan!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          navigatorRoot.pop();
                          if (mounted) {
                            String pesanError = e.toString();
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
                                  content: Text(pesanError,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500)),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        navigatorLokal.pop();
                                      },
                                      child: const Text('Mengerti'),
                                    )
                                  ],
                                ),
                              );
                              return;
                            }
                            scaffoldMessenger.showSnackBar(SnackBar(
                                content: Text(pesanError),
                                backgroundColor: Colors.red));
                            if (pesanError.toLowerCase().contains('token') ||
                                pesanError.toLowerCase().contains('sesi')) {
                              await SecureStorageHelper.clearAll();
                              if (context.mounted) {
                                navigatorLokal.pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                    (route) => false);
                              }
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: temaWarna,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Kirim Absen',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannerCorner(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required Color frameColor}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? BorderSide(color: frameColor, width: 4)
                : BorderSide.none,
            bottom: bottom != null
                ? BorderSide(color: frameColor, width: 4)
                : BorderSide.none,
            left: left != null
                ? BorderSide(color: frameColor, width: 4)
                : BorderSide.none,
            right: right != null
                ? BorderSide(color: frameColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color temaWarna =
        isMasuk ? (isDispensasi ? Colors.teal : Colors.blue) : Colors.orange;
    String labelTop = isDispensasi
        ? (isMasuk ? 'Bukti Tiba di Lokasi' : 'Selesai Kegiatan')
        : (isMasuk ? 'Pindai Wajah (Masuk)' : 'Pindai Wajah (Pulang)');

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(labelTop,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle),
                    child: Lottie.asset(
                      'assets/animations/location_scan.json',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(_statusLoading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5))
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDispensasi
                        ? Colors.teal.withOpacity(0.2)
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDispensasi
                            ? Colors.teal.withOpacity(0.5)
                            : Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isDispensasi
                              ? Icons.rocket_launch_rounded
                              : Icons.gps_fixed_rounded,
                          color: isDispensasi
                              ? Colors.tealAccent
                              : Colors.greenAccent,
                          size: 16),
                      const SizedBox(width: 8),
                      Text(
                          isDispensasi
                              ? 'Akses Jarak Jauh Diizinkan'
                              : 'Lokasi Sesuai Zona Sekolah',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),

                AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
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
                                  child: Text('Memuat Lensa...',
                                      style: TextStyle(color: Colors.white54))),
                        ),
                      ),
                      _buildScannerCorner(
                          top: 10, left: 10, frameColor: temaWarna),
                      _buildScannerCorner(
                          top: 10, right: 10, frameColor: temaWarna),
                      _buildScannerCorner(
                          bottom: 10, left: 10, frameColor: temaWarna),
                      _buildScannerCorner(
                          bottom: 10, right: 10, frameColor: temaWarna),
                    ],
                  ),
                ),
                const Spacer(),

                // PERBAIKAN: Penambahan const di sini untuk mengatasi linter
                const Text('Posisikan wajah Anda di tengah layar',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: GestureDetector(
                    onTap: _ambilFoto,
                    child: Container(
                      height: 84,
                      width: 84,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 3),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: temaWarna,
                          boxShadow: [
                            BoxShadow(
                                color: temaWarna.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5)
                          ],
                        ),
                        child: const Icon(Icons.camera_rounded,
                            color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
