import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../providers/pengumuman_provider.dart';
import '../../providers/absensi_provider.dart';

import '../auth/login_screen.dart';
import '../absen/camera_screen.dart';
import '../absen/riwayat_screen.dart';

import 'widgets/home_header.dart';
import 'widgets/status_card.dart';
import 'widgets/pengumuman_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _namaSiswa = 'Siswa';
  String? _fotoUrl;
  Timer? _timer;

  DateTime? _waktuServer;
  bool _isMemuatWaktu = true;
  Map<String, dynamic>? _dataAbsenHariIni;

  // Variabel Libur
  bool _isLibur = false;
  String _namaLibur = '';

  String _jamMasukServer = "07:00:00";
  String _jamPulangServer = "15:00:00";
  double _latSekolah = 0.0;
  double _lonSekolah = 0.0;
  double _radius = 50.0;

  double? _jarakMeter;
  bool _isMemuatLokasi = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSemuaData();
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_waktuServer != null && mounted) {
        setState(() {
          _waktuServer = _waktuServer!.add(const Duration(minutes: 1));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadUserData() async {
    final nama = await SecureStorageHelper.getUserName();
    final foto = await SecureStorageHelper.getFotoProfile();
    if (mounted) {
      setState(() {
        if (nama != null) _namaSiswa = nama;
        _fotoUrl = foto;
      });
    }
  }

  Future<void> _refreshSemuaData() async {
    if (!mounted) return;
    Provider.of<PengumumanProvider>(context, listen: false).fetchPengumuman();

    _loadUserData();
    await _sinkronisasiDataServer();
    await _cekLokasiDanJarak();
  }

  Future<void> _cekLokasiDanJarak() async {
    if (!mounted) return;
    setState(() => _isMemuatLokasi = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isMemuatLokasi = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) setState(() => _isMemuatLokasi = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (_latSekolah != 0.0 && _lonSekolah != 0.0) {
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _latSekolah,
          _lonSekolah,
        );

        if (mounted) {
          setState(() {
            _jarakMeter = distanceInMeters;
            _isMemuatLokasi = false;
          });
        }
      } else {
        if (mounted) setState(() => _isMemuatLokasi = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isMemuatLokasi = false);
    }
  }

  Future<void> _sinkronisasiDataServer() async {
    if (!mounted) return;
    setState(() => _isMemuatWaktu = true);

    final serverData = await ApiClient.getServerData();
    DateTime waktuAkurat = DateTime.now();

    if (serverData != null) {
      waktuAkurat = serverData['waktu'];

      // --- UPDATE VARIABEL LIBUR & JAM DARI SERVER ---
      _isLibur = serverData['is_libur'] ?? false;
      _namaLibur = serverData['nama_libur'] ?? '';
      _jamMasukServer = serverData['jam_masuk'] ?? "00:00:00";
      _jamPulangServer = serverData['jam_pulang'] ?? "00:00:00";
      // ------------------------------------------------

      _latSekolah = serverData['lat_sekolah'] ?? 0.0;
      _lonSekolah = serverData['lon_sekolah'] ?? 0.0;
      _radius = serverData['radius'] ?? 50.0;
    }

    final tanggalHariIni =
        "${waktuAkurat.year}-${waktuAkurat.month.toString().padLeft(2, '0')}-${waktuAkurat.day.toString().padLeft(2, '0')}";

    if (!mounted) return;
    final absenProvider = Provider.of<AbsensiProvider>(context, listen: false);

    try {
      final dataAbsen = await absenProvider.cekAbsenHariIni(tanggalHariIni);
      if (mounted) {
        setState(() {
          _waktuServer = waktuAkurat;
          _dataAbsenHariIni = dataAbsen;
          _isMemuatWaktu = false;
        });
      }
    } catch (e) {
      if (e.toString() == 'sesi_habis') {
        _logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sesi Anda telah berakhir. Silakan login ulang.'),
                backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) setState(() => _isMemuatWaktu = false);
      }
    }
  }

  void _logout() async {
    await SecureStorageHelper.clearAll();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTombolDisable = true;
    String labelTombol = 'Memeriksa Data...';
    IconData iconTombol = Icons.sync;
    Color warnaTombol = Colors.grey[500]!;
    String tipeAbsen = 'masuk';
    String statusHadir = 'Belum Absen Masuk';
    Color statusHadirColor = Colors.red[600]!;

    if (_waktuServer != null && !_isMemuatWaktu) {
      // =======================================================
      // LOGIKA UTAMA: JIKA HARI INI LIBUR
      // =======================================================
      if (_isLibur) {
        statusHadir = _namaLibur;
        statusHadirColor = Colors.blue[600]!;

        isTombolDisable = true;
        labelTombol = 'Sedang Libur';
        iconTombol = Icons.event_available_rounded;
        warnaTombol = Colors.blue[300]!;
      }
      // =======================================================
      // JIKA BUKAN HARI LIBUR, JALANKAN LOGIKA NORMAL
      // =======================================================
      else {
        final now = _waktuServer!;

        final partsMasuk = _jamMasukServer.split(':');
        final jamMasukHariIni = DateTime(now.year, now.month, now.day,
            int.tryParse(partsMasuk[0]) ?? 7, int.tryParse(partsMasuk[1]) ?? 0);
        final bukaMasukHariIni =
            jamMasukHariIni.subtract(const Duration(minutes: 45));

        final partsPulang = _jamPulangServer.split(':');
        final jamPulangHariIni = DateTime(
            now.year,
            now.month,
            now.day,
            int.tryParse(partsPulang[0]) ?? 15,
            int.tryParse(partsPulang[1]) ?? 0);

        final tutupMasukHariIni =
            jamPulangHariIni.subtract(const Duration(minutes: 60));
        final tutupPulangHariIni =
            DateTime(now.year, now.month, now.day, 23, 45);

        bool sudahAbsenMasuk = _dataAbsenHariIni != null &&
            _dataAbsenHariIni!['jam_masuk'] != null;
        bool sudahAbsenPulang = _dataAbsenHariIni != null &&
            _dataAbsenHariIni!['jam_pulang'] != null;

        if (sudahAbsenMasuk) {
          try {
            String strWaktuMasuk = _dataAbsenHariIni!['jam_masuk'];
            final parts = strWaktuMasuk.split(':');
            DateTime dtWaktuMasuk = DateTime(now.year, now.month, now.day,
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

            if (dtWaktuMasuk.isAfter(jamMasukHariIni)) {
              int telatMenit =
                  dtWaktuMasuk.difference(jamMasukHariIni).inMinutes;
              statusHadir = 'Terlambat $telatMenit Menit';
              statusHadirColor = Colors.orange[600]!;
            } else {
              statusHadir = 'Hadir Tepat Waktu';
              statusHadirColor = Colors.green[600]!;
            }
          } catch (e) {
            statusHadir = 'Hadir';
            statusHadirColor = Colors.green[600]!;
          }
        } else {
          statusHadir =
              now.isAfter(tutupMasukHariIni) ? 'Alpa' : 'Belum Absen Masuk';
          statusHadirColor = Colors.red[600]!;
        }

        if (now.isBefore(bukaMasukHariIni)) {
          isTombolDisable = true;
          labelTombol = 'Belum Dibuka';
          iconTombol = Icons.lock_clock;
          warnaTombol = Colors.grey[400]!;
        } else if (now.isAfter(bukaMasukHariIni) &&
            now.isBefore(tutupMasukHariIni)) {
          if (sudahAbsenMasuk) {
            isTombolDisable = true;
            labelTombol = 'Sudah Absen';
            iconTombol = Icons.check_circle;
            warnaTombol = Colors.green[600]!;
          } else {
            isTombolDisable = false;
            labelTombol = 'Silahkan Absen';
            iconTombol = Icons.fingerprint_rounded;
            warnaTombol = Colors.blue[600]!;
            tipeAbsen = 'masuk';
          }
        } else if (now.isAfter(tutupMasukHariIni) &&
            now.isBefore(jamPulangHariIni)) {
          isTombolDisable = true;
          if (!sudahAbsenMasuk) {
            labelTombol = 'Alpa';
            iconTombol = Icons.cancel;
            warnaTombol = Colors.red[600]!;
          } else {
            labelTombol = 'Menunggu Jam Pulang';
            iconTombol = Icons.hourglass_top_rounded;
            warnaTombol = Colors.orange[400]!;
          }
        } else if (now.isAfter(jamPulangHariIni) &&
            now.isBefore(tutupPulangHariIni)) {
          if (!sudahAbsenMasuk) {
            isTombolDisable = true;
            labelTombol = 'Alpa';
            iconTombol = Icons.cancel;
            warnaTombol = Colors.red[600]!;
          } else if (sudahAbsenPulang) {
            isTombolDisable = true;
            labelTombol = 'Sudah Absen';
            iconTombol = Icons.check_circle;
            warnaTombol = Colors.green[600]!;
          } else {
            isTombolDisable = false;
            labelTombol = 'Silahkan Absen';
            iconTombol = Icons.exit_to_app_rounded;
            warnaTombol = Colors.orange[600]!;
            tipeAbsen = 'pulang';
          }
        } else {
          isTombolDisable = true;
          labelTombol = 'Sistem Ditutup';
          iconTombol = Icons.block;
          warnaTombol = Colors.grey[400]!;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[800]!, Colors.blue[500]!]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshSemuaData,
              color: Colors.blue[600],
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(
                      namaSiswa: _namaSiswa,
                      fotoUrl: _fotoUrl,
                      waktuServer: _waktuServer,
                      onRiwayatTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RiwayatScreen())),
                      onLogoutTap: _logout,
                    ),
                    const SizedBox(height: 10),
                    StatusCard(
                      isMemuat: _isMemuatWaktu,
                      statusHadir: statusHadir,
                      statusHadirColor: statusHadirColor,
                      waktuServer: _waktuServer,
                      jamMasukServer: _jamMasukServer,
                      jamPulangServer: _jamPulangServer,
                      jarakMeter: _jarakMeter,
                      isMemuatLokasi: _isMemuatLokasi,
                    ),
                    const SizedBox(height: 24),
                    const PengumumanList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isTombolDisable
                    ? null
                    : () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraScreen(
                                      tipeAbsen: tipeAbsen,
                                      latSekolah: _latSekolah,
                                      lonSekolah: _lonSekolah,
                                      radius: _radius,
                                    )));
                        if (mounted) _refreshSemuaData();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaTombol,
                  foregroundColor: Colors.white,
                  elevation: isTombolDisable ? 0 : 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isMemuatWaktu
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconTombol, size: 24),
                          const SizedBox(width: 12),
                          Text(labelTombol,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
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
