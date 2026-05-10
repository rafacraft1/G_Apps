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

  // Variabel Hari Libur
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
    _loadProfileData();
    _refreshSemuaData();

    // Jalankan jam realtime setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waktuServer != null && mounted) {
        setState(() {
          _waktuServer = _waktuServer!.add(const Duration(seconds: 1));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    String? nama = await SecureStorageHelper.getUserName();
    String? foto = await SecureStorageHelper.getFotoProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _fotoUrl = foto;
    });
  }

  Future<void> _refreshSemuaData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isMemuatWaktu = true;
      _isMemuatLokasi = true;
    });

    // 1. Sinkronisasi Waktu & Konfigurasi dari Backend
    final serverData = await ApiClient.getServerData();

    // Guard untuk State.context menggunakan `mounted`
    if (!mounted) {
      return;
    }

    if (serverData != null) {
      setState(() {
        _waktuServer = serverData['waktu'];
        _isLibur = serverData['is_libur'] ?? false;
        _namaLibur = serverData['nama_libur'] ?? '';
        _jamMasukServer = serverData['jam_masuk'];
        _jamPulangServer = serverData['jam_pulang'];
        _latSekolah = serverData['lat_sekolah'];
        _lonSekolah = serverData['lon_sekolah'];
        _radius = serverData['radius'];
        _isMemuatWaktu = false;
      });
    } else {
      setState(() {
        _isMemuatWaktu = false;
      });
    }

    // 2. Periksa Status Absensi Hari Ini
    if (_waktuServer != null) {
      String tanggalHariIni =
          "${_waktuServer!.year}-${_waktuServer!.month.toString().padLeft(2, '0')}-${_waktuServer!.day.toString().padLeft(2, '0')}";

      try {
        if (!mounted) {
          return;
        }

        final absenHariIni =
            await Provider.of<AbsensiProvider>(context, listen: false)
                .cekAbsenHariIni(tanggalHariIni);

        if (!mounted) {
          return;
        }

        setState(() {
          _dataAbsenHariIni = absenHariIni;
        });
      } catch (e) {
        if (e.toString() == 'sesi_habis') {
          _prosesLogoutExpired();
        }
      }
    }

    // 3. Update Lokasi GPS & Tarik Pengumuman
    await _updateLokasiJarak();

    if (!mounted) {
      return;
    }

    Provider.of<PengumumanProvider>(context, listen: false).fetchPengumuman();
  }

  Future<void> _updateLokasiJarak() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) {
        return;
      }

      double jarak = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _latSekolah,
        _lonSekolah,
      );

      setState(() {
        _jarakMeter = jarak;
        _isMemuatLokasi = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _jarakMeter = null;
        _isMemuatLokasi = false;
      });
    }
  }

  void _prosesLogoutExpired() async {
    await SecureStorageHelper.clearAll();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Sesi Anda telah habis. Silakan login kembali.'),
          backgroundColor: Colors.red),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // === LOGIKA TOMBOL ABSENSI ===
    String labelTombol = 'Memuat Data...';
    Color warnaTombol = Colors.grey[600]!;
    IconData iconTombol = Icons.hourglass_empty;
    bool isTombolDisable = _isMemuatWaktu || _isMemuatLokasi;
    String tipeAbsen = 'masuk';

    if (!isTombolDisable) {
      if (_isLibur) {
        labelTombol =
            _namaLibur.isNotEmpty ? _namaLibur : 'Libur / Akhir Pekan';
        warnaTombol = Colors.grey[500]!;
        iconTombol = Icons.event_busy_rounded;
        isTombolDisable = true;
      } else if (_dataAbsenHariIni == null) {
        labelTombol = 'Absen Masuk';
        warnaTombol = Colors.blue[600]!;
        iconTombol = Icons.login_rounded;
        tipeAbsen = 'masuk';
      } else if (_dataAbsenHariIni!['jam_pulang'] == null) {
        labelTombol = 'Absen Pulang';
        warnaTombol = Colors.orange[600]!;
        iconTombol = Icons.logout_rounded;
        tipeAbsen = 'pulang';
      } else {
        labelTombol = 'Sudah Absen Hari Ini';
        warnaTombol = Colors.green[600]!;
        iconTombol = Icons.check_circle_outline;
        isTombolDisable = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshSemuaData,
        color: Colors.blue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: HomeHeader(
                namaSiswa: _namaSiswa,
                fotoUrl: _fotoUrl,
                waktuServer: _waktuServer,
                onRefreshProfile: _loadProfileData,
                onRiwayatTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RiwayatScreen()),
                  );
                },
                onLogoutTap: () async {
                  await SecureStorageHelper.clearAll();

                  // Guard untuk BuildContext parameter (local context) menggunakan context.mounted
                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),

            // CARD STATUS KEHADIRAN
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StatusCard(
                    isMemuat: _isMemuatWaktu,
                    statusHadir: _dataAbsenHariIni?['status'] ?? 'Belum Absen',
                    statusHadirColor: _dataAbsenHariIni != null
                        ? (_dataAbsenHariIni!['status'] == 'Hadir'
                            ? Colors.green
                            : Colors.orange)
                        : Colors.grey,
                    waktuServer: _waktuServer,
                    jamMasukServer: _jamMasukServer,
                    jamPulangServer: _jamPulangServer,
                    jarakMeter: _jarakMeter,
                    isMemuatLokasi: _isMemuatLokasi,
                  ),
                ),
              ),
            ),

            // LIST PENGUMUMAN
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Informasi Sekolah',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RiwayatScreen()));
                          },
                          child: const Text('Lihat Semua',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const PengumumanList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // TOMBOL AKSI UTAMA
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Hero(
          tag: 'btn_absen_hero',
          child: SizedBox(
            width: double.infinity,
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

                      // Guard untuk BuildContext parameter (local context) menggunakan context.mounted
                      if (!context.mounted) {
                        return;
                      }

                      _refreshSemuaData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: warnaTombol,
                foregroundColor: Colors.white,
                elevation: isTombolDisable ? 0 : 4,
                disabledBackgroundColor: warnaTombol.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isMemuatWaktu || _isMemuatLokasi
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconTombol, size: 24),
                        const SizedBox(width: 12),
                        Text(labelTombol,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
