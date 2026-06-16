import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';

import '../../core/utils/location_helper.dart';
import '../../core/utils/secure_storage_helper.dart';
import 'widgets/face_overlay_painter.dart';
import 'widgets/preview_bottom_sheet.dart';

class CameraScreen extends StatefulWidget {
  final String tipeAbsen;
  final double latSekolah;
  final double lonSekolah;
  final double radius;
  final String namaZona;

  const CameraScreen({
    super.key,
    required this.tipeAbsen,
    required this.latSekolah,
    required this.lonSekolah,
    required this.radius,
    required this.namaZona,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _kameraDepan;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  Position? _posisi;
  bool _isFakeGpsDetected = false;

  FaceDetector? _faceDetector;
  bool _isProcessingPhoto = false;

  String _statusLoading = "Mencari Satelit GPS...";
  String _statusPesan = "Arahkan wajah Anda ke kamera";

  late bool isDispensasi;
  late bool isMasuk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    isDispensasi = widget.tipeAbsen.contains('dispensasi');
    isMasuk = widget.tipeAbsen.contains('masuk');

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    _initCameraAndLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _faceDetector?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.dispose();
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCameraOnly();
    }
  }

  Future<void> _initCameraOnly() async {
    try {
      final cameras = await availableCameras();
      _kameraDepan = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);

      _controller = CameraController(_kameraDepan!, ResolutionPreset.high,
          enableAudio: false);
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Gagal restart kamera: $e');
    }
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

      double jarak = Geolocator.distanceBetween(_posisi!.latitude,
          _posisi!.longitude, widget.latSekolah, widget.lonSekolah);

      if (jarak > widget.radius && !isDispensasi) {
        if (!mounted) {
          return;
        }
        setState(() => _isLoading = false);
        _tampilkanPesanLuarArea(jarak);
        return;
      }

      if (mounted) {
        setState(() => _statusLoading = "Menghubungkan ke Lensa Kamera...");
      }

      await _initCameraOnly();
      if (mounted) {
        setState(() => _isLoading = false);
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
                    color: Colors.red, size: 40)),
            const SizedBox(height: 16),
            const Text('Di Luar Jangkauan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(
            "Tidak dapat melakukan absensi. Jarak Anda saat ini ${jarak.round()} meter dari sekolah (Maks: ${widget.radius.round()}m).",
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: Colors.black87)),
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))))
        ],
      ),
    );
  }

  Future<File> _tambahkanWatermark(
      File imageFile, ui.Image decodedImage, bool needsRotation) async {
    try {
      final double imgW = decodedImage.width.toDouble();
      final double imgH = decodedImage.height.toDouble();
      final double finalW = needsRotation ? imgH : imgW;
      final double finalH = needsRotation ? imgW : imgH;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.save();
      if (needsRotation) {
        canvas.translate(finalW, 0);
        canvas.rotate(math.pi / 2);
        canvas.translate(imgW, 0);
        canvas.scale(-1.0, 1.0);
      } else {
        canvas.translate(finalW, 0);
        canvas.scale(-1.0, 1.0);
      }
      canvas.drawImage(decodedImage, Offset.zero, Paint());
      canvas.restore();

      String namaSiswa = await SecureStorageHelper.getUserName() ?? 'Siswa';
      String kelas = await SecureStorageHelper.getUserKelas() ?? 'Kelas';
      String tipe = isMasuk ? 'Masuk' : 'Pulang';

      if (isDispensasi) {
        tipe += ' (Dispensasi)';
      }

      final now = DateTime.now();
      final hari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ][now.weekday - 1];
      final bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ][now.month - 1];
      String tanggalWaktu =
          "$hari, ${now.day} $bulan ${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

      String watermarkText =
          "$namaSiswa\n$kelas\nAbsen $tipe - ${widget.namaZona}\n$tanggalWaktu";

      double fontSize = finalW * 0.030;
      final textStyle = ui.TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          const ui.Shadow(
              color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))
        ],
      );

      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.right,
        maxLines: 5,
      );

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(watermarkText);

      final double rightMargin = finalW * 0.03;
      final double topMargin = finalH * 0.03;
      final double textLayoutWidth = finalW - (rightMargin * 2);

      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: textLayoutWidth));

      final double textPadding = finalW * 0.02;
      final bgRect = RRect.fromLTRBR(
          finalW - rightMargin - paragraph.longestLine - textPadding,
          topMargin - (textPadding / 2),
          finalW - rightMargin + (textPadding / 2),
          topMargin + paragraph.height + (textPadding / 2),
          const Radius.circular(8));

      canvas.drawRRect(bgRect, Paint()..color = Colors.black.withOpacity(0.5));
      canvas.drawParagraph(paragraph, Offset(rightMargin, topMargin));

      final picture = recorder.endRecording();
      final img = await picture.toImage(finalW.toInt(), finalH.toInt());

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await imageFile.writeAsBytes(byteData.buffer.asUint8List());
      }

      return imageFile;
    } catch (e) {
      debugPrint("Error Watermark: $e");
      return imageFile;
    }
  }

  Future<void> _ambilFotoDanValidasi() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessingPhoto) {
      return;
    }

    setState(() {
      _isProcessingPhoto = true;
      _statusPesan = "Memproses foto & mendeteksi wajah...";
    });

    try {
      final XFile file = await _controller!.takePicture();
      File fotoFile = File(file.path);

      await _controller!.pausePreview();

      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        if (fotoFile.existsSync()) {
          fotoFile.deleteSync();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  'Wajah tidak terdeteksi! Pastikan area terang.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))));
          setState(() {
            _isProcessingPhoto = false;
            _statusPesan = "Arahkan wajah Anda ke kamera";
          });
          await _controller!.resumePreview();
        }
        return;
      }

      final bytes = await fotoFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      double imgW = decodedImage.width.toDouble();
      double imgH = decodedImage.height.toDouble();
      bool needsRotation = imgW > imgH;

      if (needsRotation) {
        double temp = imgW;
        imgW = imgH;
        imgH = temp;
      }

      int wajahSignifikan = 0;
      Face? wajahUtama;
      double maxArea = 0;

      for (var f in faces) {
        double widthRatio = f.boundingBox.width / imgW;
        double area = f.boundingBox.width * f.boundingBox.height;

        if (widthRatio > 0.12) {
          wajahSignifikan++;
        }

        if (area > maxArea) {
          maxArea = area;
          wajahUtama = f;
        }
      }

      if (wajahSignifikan > 1) {
        if (fotoFile.existsSync()) {
          fotoFile.deleteSync();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  'Terdeteksi lebih dari 1 wajah! Pastikan Anda memfoto sendirian.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))));
          setState(() {
            _isProcessingPhoto = false;
            _statusPesan = "Pastikan hanya Anda di dalam kamera";
          });
          await _controller!.resumePreview();
        }
        return;
      }

      final faceRect = wajahUtama!.boundingBox;

      final double safeLeft = imgW * 0.30;
      final double safeRight = imgW * 0.70;
      final double safeTop = imgH * 0.30;
      final double safeBottom = imgH * 0.70;

      final double faceCenterX = faceRect.center.dx;
      final double faceCenterY = faceRect.center.dy;

      if (faceCenterX < safeLeft ||
          faceCenterX > safeRight ||
          faceCenterY < safeTop ||
          faceCenterY > safeBottom) {
        if (fotoFile.existsSync()) {
          fotoFile.deleteSync();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  'Wajah tidak di tengah! Pastikan persis di dalam bingkai oval.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))));
          setState(() {
            _isProcessingPhoto = false;
            _statusPesan = "Geser wajah persis ke tengah oval";
          });
          await _controller!.resumePreview();
        }
        return;
      }

      if ((faceRect.width / imgW) < 0.25) {
        if (fotoFile.existsSync()) {
          fotoFile.deleteSync();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  'Terlalu jauh! Dekatkan kamera ke wajah Anda.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))));
          setState(() {
            _isProcessingPhoto = false;
            _statusPesan = "Dekatkan wajah ke kamera";
          });
          await _controller!.resumePreview();
        }
        return;
      }

      if (mounted) {
        setState(() => _statusPesan = "Menyematkan Watermark...");

        fotoFile =
            await _tambahkanWatermark(fotoFile, decodedImage, needsRotation);

        // PERBAIKAN: Menggunakan mounted milik class State agar linter patuh
        if (!mounted) {
          return;
        }

        setState(
            () => _statusPesan = "Wajah terverifikasi! Menyiapkan preview...");

        PreviewBottomSheet.show(
          context: context,
          foto: fotoFile,
          lat: _posisi!.latitude,
          lon: _posisi!.longitude,
          isMasuk: isMasuk,
          isDispensasi: isDispensasi,
          isFakeGpsDetected: _isFakeGpsDetected,
          accuracy: _posisi!.accuracy,
          onRetakeAction: () async {
            if (mounted) {
              setState(() {
                _isProcessingPhoto = false;
                _statusPesan = "Arahkan wajah Anda ke kamera";
              });
              await _controller!.resumePreview();
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPhoto = false;
          _statusPesan = "Gagal memproses gambar. Coba lagi.";
        });
        await _controller!.resumePreview();
      }
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle),
              child: Lottie.asset('assets/animations/location_scan.json',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                      child: CircularProgressIndicator(color: Colors.white)))),
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
    );
  }

  Widget _buildGpsStatusWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: _isFakeGpsDetected
              ? Colors.red.withOpacity(0.2)
              : (isDispensasi
                  ? Colors.teal.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _isFakeGpsDetected
                  ? Colors.red.withOpacity(0.5)
                  : (isDispensasi
                      ? Colors.teal.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3)))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              _isFakeGpsDetected
                  ? Icons.warning_rounded
                  : (isDispensasi
                      ? Icons.rocket_launch_rounded
                      : Icons.gps_fixed_rounded),
              color: _isFakeGpsDetected
                  ? Colors.redAccent
                  : (isDispensasi ? Colors.tealAccent : Colors.greenAccent),
              size: 16),
          const SizedBox(width: 8),
          Text(
              _isFakeGpsDetected
                  ? 'Peringatan: Fake GPS Terdeteksi!'
                  : (isDispensasi
                      ? 'Akses Jarak Jauh Diizinkan'
                      : 'Lokasi Sesuai Zona Sekolah'),
              style: TextStyle(
                  color: _isFakeGpsDetected ? Colors.redAccent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color temaWarna =
        isMasuk ? (isDispensasi ? Colors.teal : Colors.blue) : Colors.orange;
    String labelTop = isDispensasi
        ? (isMasuk ? 'Bukti Tiba' : 'Selesai Tugas')
        : (isMasuk ? 'Absen Masuk' : 'Absen Pulang');

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(labelTop,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          elevation: 0),
      body: _isLoading
          ? _buildLoadingWidget()
          : Column(
              children: [
                const SizedBox(height: 10),
                _buildGpsStatusWidget(),
                const SizedBox(height: 10),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _isProcessingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.face_rounded,
                              color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(_statusPesan,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))
                    ])),
                const Spacer(),
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: temaWarna.withOpacity(0.5), width: 3)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: _isCameraInitialized && _controller != null
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                double ratio = _controller!.value.aspectRatio;
                                if (ratio > 1.0) {
                                  ratio = 1.0 / ratio;
                                }

                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    OverflowBox(
                                      alignment: Alignment.center,
                                      maxWidth: double.infinity,
                                      maxHeight: double.infinity,
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        height: constraints.maxWidth / ratio,
                                        child: CameraPreview(_controller!),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: FaceOverlayPainter(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : const Center(
                              child: Text('Memuat Lensa...',
                                  style: TextStyle(color: Colors.white54))),
                    ),
                  ),
                ),
                const Spacer(),
                const Text('Silakan tekan tombol untuk mengambil foto.',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: GestureDetector(
                    onTap: _isProcessingPhoto ? null : _ambilFotoDanValidasi,
                    child: Opacity(
                        opacity: _isProcessingPhoto ? 0.5 : 1.0,
                        child: Container(
                            height: 84,
                            width: 84,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: temaWarna, width: 3)),
                            child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: temaWarna),
                                child: const Icon(Icons.camera_rounded,
                                    color: Colors.white, size: 36)))),
                  ),
                )
              ],
            ),
    );
  }
}
