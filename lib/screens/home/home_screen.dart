import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pengumuman_provider.dart';
import '../../providers/absensi_provider.dart';
import '../../repositories/server_repository.dart';

import '../auth/login_screen.dart';
import '../absen/camera_screen.dart';
import '../absen/riwayat_screen.dart';
import '../izin/ajukan_izin_screen.dart';
import '../izin/riwayat_izin_screen.dart';

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
  String _namaKelas = 'Siswa Aktif';
  String? _fotoUrl;
  Timer? _timer;

  final ValueNotifier<DateTime?> _waktuServerNotifier = ValueNotifier(null);

  bool _isMemuatWaktu = true;
  Map<String, dynamic>? _dataAbsenHariIni;

  bool _isLibur = false;
  String _namaLibur = '';

  String _jamMasukServer = "07:00:00";
  String _jamPulangServer = "15:00:00";
  String _jamBukaServer = "06:00:00";
  double _latSekolah = 0.0;
  double _lonSekolah = 0.0;
  double _radius = 50.0;

  // PENAMBAHAN: Variabel untuk menyimpan Nama Zona
  String _namaZona = 'Area Sekolah';

  double? _jarakMeter;
  bool _isMemuatLokasi = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _updateFCMToken();
    _refreshSemuaData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waktuServerNotifier.value != null) {
        _waktuServerNotifier.value =
            _waktuServerNotifier.value!.add(const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waktuServerNotifier.dispose();
    super.dispose();
  }

  Future<void> _updateFCMToken() async {
    try {
      String? token = await SecureStorageHelper.getToken();
      if (token == null || token.isEmpty) return;

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        FormData formData = FormData.fromMap({'fcm_token': fcmToken});
        await ApiClient().dio.post('fcm/updateToken', data: formData);
      }
    } catch (e) {
      debugPrint('Gagal sinkronisasi token FCM: $e');
    }
  }

  Future<void> _loadProfileData() async {
    String? nama = await SecureStorageHelper.getUserName();
    String? foto = await SecureStorageHelper.getFotoProfile();
    String? kelas = await SecureStorageHelper.getUserKelas();

    if (!mounted) return;

    setState(() {
      _namaSiswa = nama ?? 'Siswa';
      _namaKelas = kelas ?? 'Siswa Aktif';
      _fotoUrl = foto;
    });
  }

  Future<void> _refreshSemuaData() async {
    if (!mounted) return;

    setState(() {
      _isMemuatWaktu = true;
      _isMemuatLokasi = true;
    });

    try {
      final serverData = await ServerRepository.getServerData();

      if (!mounted) return;

      if (serverData != null) {
        _waktuServerNotifier.value = serverData['waktu'];

        setState(() {
          _isLibur = serverData['is_libur'] ?? false;
          _namaLibur =
              serverData['nama_libur'] ?? serverData['keterangan'] ?? '';
          _jamMasukServer = serverData['jam_masuk'] ?? "07:00:00";
          _jamPulangServer = serverData['jam_pulang'] ?? "15:00:00";

          Map<String, dynamic>? pengaturan =
              serverData['pengaturan'] as Map<String, dynamic>?;
          _jamBukaServer = pengaturan?['jam_buka'] ?? "06:00:00";

          _latSekolah =
              double.tryParse(serverData['lat_sekolah']?.toString() ?? '0.0') ??
                  0.0;
          _lonSekolah =
              double.tryParse(serverData['lon_sekolah']?.toString() ?? '0.0') ??
                  0.0;
          _radius =
              double.tryParse(serverData['radius']?.toString() ?? '50.0') ??
                  50.0;

          // PENAMBAHAN: Menangkap nama_zona dari JSON Response (Bisa ganti key "nama_zona" sesuai di BE)
          _namaZona = serverData['nama_zona'] ?? 'Area Sekolah';

          _isMemuatWaktu = false;
        });
      } else {
        setState(() => _isMemuatWaktu = false);
      }

      if (_waktuServerNotifier.value != null) {
        String tanggalHariIni =
            "${_waktuServerNotifier.value!.year}-${_waktuServerNotifier.value!.month.toString().padLeft(2, '0')}-${_waktuServerNotifier.value!.day.toString().padLeft(2, '0')}";
        try {
          final absenHariIni =
              await Provider.of<AbsensiProvider>(context, listen: false)
                  .cekAbsenHariIni(tanggalHariIni);
          if (!mounted) return;
          setState(() => _dataAbsenHariIni = absenHariIni);
        } catch (e) {
          if (e.toString().contains('sesi_habis') ||
              e.toString().contains('401')) {
            _prosesLogoutExpired();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetch waktu server: $e');
      if (!mounted) return;
      setState(() => _isMemuatWaktu = false);
    }

    await _updateLokasiJarak();

    if (!mounted) return;
    Provider.of<PengumumanProvider>(context, listen: false).fetchPengumuman();
  }

  Future<void> _updateLokasiJarak() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi diblokir permanen');
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      double jarak = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, _latSekolah, _lonSekolah);
      setState(() {
        _jarakMeter = jarak;
        _isMemuatLokasi = false;
      });
    } catch (e) {
      debugPrint('Error lokasi: $e');
      if (!mounted) return;
      setState(() {
        _jarakMeter = null;
        _isMemuatLokasi = false;
      });
    }
  }

  void _prosesLogoutExpired() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false);
  }

  Map<String, dynamic> _getKonfigurasiAbsen(DateTime? waktuSaatIni) {
    String statusHariIni = 'Memuat...';
    Color warnaStatus = Colors.grey;
    String labelTombol = 'Memuat...';
    String subLabel = 'Mohon tunggu...';
    Color warnaTombol = Colors.grey;
    IconData iconTombol = Icons.hourglass_empty;
    bool isTombolDisable = _isMemuatWaktu || _isMemuatLokasi;
    String tipeAbsen = 'masuk';

    if (!isTombolDisable && waktuSaatIni != null) {
      try {
        List<String> jp = _jamPulangServer.split(':');
        List<String> jb = _jamBukaServer.split(':');

        DateTime jamPulang = DateTime(
            waktuSaatIni.year,
            waktuSaatIni.month,
            waktuSaatIni.day,
            int.parse(jp[0]),
            int.parse(jp[1]),
            int.parse(jp[2]));

        DateTime batasAwalMasuk = DateTime(
            waktuSaatIni.year,
            waktuSaatIni.month,
            waktuSaatIni.day,
            int.parse(jb[0]),
            int.parse(jb[1]),
            int.parse(jb[2]));
        DateTime batasAkhirMasuk =
            jamPulang.subtract(const Duration(minutes: 30));
        DateTime batasAkhirPulang = DateTime(
            waktuSaatIni.year, waktuSaatIni.month, waktuSaatIni.day, 23, 0, 0);

        if (_isLibur) {
          statusHariIni = 'Libur';
          warnaStatus = Colors.grey;
          labelTombol = 'Sekolah Libur';
          subLabel = _namaLibur.isNotEmpty ? _namaLibur : 'Libur Akhir Pekan';
          warnaTombol = Colors.grey;
          iconTombol = Icons.event_busy;
          isTombolDisable = true;
        } else if (_dataAbsenHariIni == null) {
          tipeAbsen = 'masuk';
          if (waktuSaatIni.isAfter(batasAkhirMasuk)) {
            statusHariIni = 'Alpa';
            warnaStatus = Colors.red;
            labelTombol = 'Waktu Habis';
            subLabel = 'Anda tidak absen masuk';
            warnaTombol = Colors.red;
            iconTombol = Icons.close;
            isTombolDisable = true;
          } else {
            statusHariIni = 'Belum Absen';
            warnaStatus = Colors.orange;
            if (waktuSaatIni.isBefore(batasAwalMasuk)) {
              labelTombol = 'Belum Waktunya';
              subLabel =
                  'Dibuka pukul ${batasAwalMasuk.hour.toString().padLeft(2, '0')}:${batasAwalMasuk.minute.toString().padLeft(2, '0')}';
              warnaTombol = Colors.grey;
              iconTombol = Icons.lock;
              isTombolDisable = true;
            } else {
              labelTombol = 'Absen Masuk';
              subLabel = 'Ketuk untuk mulai';
              warnaTombol = Colors.blue;
              iconTombol = Icons.login;
            }
          }
        } else {
          String statusAbsenServer = _dataAbsenHariIni!['status'] ?? '';

          if (statusAbsenServer == 'Sakit' || statusAbsenServer == 'Izin') {
            statusHariIni = statusAbsenServer;
            warnaStatus =
                statusAbsenServer == 'Sakit' ? Colors.purple : Colors.indigo;
            labelTombol = 'Anda Sedang $statusAbsenServer';
            subLabel = statusAbsenServer == 'Sakit'
                ? 'Semoga lekas sembuh!'
                : 'Semoga urusan Anda lancar!';
            warnaTombol = warnaStatus;
            iconTombol = statusAbsenServer == 'Sakit'
                ? Icons.medical_services_rounded
                : Icons.info_outline_rounded;
            isTombolDisable = true;
          } else if (statusAbsenServer == 'Dispensasi') {
            statusHariIni = 'Dispensasi Luar';
            warnaStatus = Colors.teal;

            if (_dataAbsenHariIni!['jam_masuk'] == null) {
              tipeAbsen = 'masuk_dispensasi';
              labelTombol = 'Absen Lokasi Kegiatan';
              subLabel = 'Ketuk untuk kirim bukti tiba';
              warnaTombol = Colors.teal;
              iconTombol = Icons.pin_drop_rounded;
              isTombolDisable = false;
            } else if (_dataAbsenHariIni!['jam_pulang'] == null) {
              tipeAbsen = 'pulang_dispensasi';
              labelTombol = 'Absen Pulang Kegiatan';
              subLabel = 'Ketuk jika acara selesai';
              warnaTombol = Colors.orange;
              iconTombol = Icons.directions_run_rounded;
              isTombolDisable = false;
            } else {
              statusHariIni = 'Hadir (Dispensasi)';
              labelTombol = 'Tugas Selesai';
              subLabel = 'Terima kasih atas dedikasinya!';
              warnaTombol = Colors.green;
              iconTombol = Icons.verified_rounded;
              isTombolDisable = true;
            }
          } else if (_dataAbsenHariIni!['jam_pulang'] == null) {
            tipeAbsen = 'pulang';
            statusHariIni = 'Belum Absen Pulang';
            warnaStatus = Colors.blue;
            if (waktuSaatIni.isBefore(jamPulang)) {
              labelTombol = 'Belum Jam Pulang';
              subLabel =
                  'Pulang pukul ${jamPulang.hour.toString().padLeft(2, '0')}:${jamPulang.minute.toString().padLeft(2, '0')}';
              warnaTombol = Colors.grey;
              iconTombol = Icons.lock;
              isTombolDisable = true;
            } else if (waktuSaatIni.isAfter(batasAkhirPulang)) {
              labelTombol = 'Sesi Berakhir';
              subLabel = 'Batas absen 23:00';
              warnaTombol = Colors.red;
              isTombolDisable = true;
            } else {
              labelTombol = 'Absen Pulang';
              subLabel = 'Ketuk untuk pulang';
              warnaTombol = Colors.orange;
              iconTombol = Icons.logout;
            }
          } else {
            statusHariIni = 'Hadir';
            warnaStatus = Colors.green;
            labelTombol = 'Selesai';
            subLabel = 'Terima kasih hari ini!';
            warnaTombol = Colors.green;
            iconTombol = Icons.check_circle;
            isTombolDisable = true;
          }
        }
      } catch (e) {
        statusHariIni = 'Error';
      }
    }

    return {
      'statusHariIni': statusHariIni,
      'warnaStatus': warnaStatus,
      'labelTombol': labelTombol,
      'subLabel': subLabel,
      'warnaTombol': warnaTombol,
      'iconTombol': iconTombol,
      'isTombolDisable': isTombolDisable,
      'tipeAbsen': tipeAbsen,
    };
  }

  Widget _buildActionMenu(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required IconData icon,
      required MaterialColor color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(color: color[50], shape: BoxShape.circle),
                  child: Icon(icon, color: color[700], size: 24),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _getKonfigurasiAbsen(_waktuServerNotifier.value);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshSemuaData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      HomeHeader(
                        namaSiswa: _namaSiswa,
                        namaKelas: _namaKelas,
                        fotoUrl: _fotoUrl,
                        waktuServerNotifier: _waktuServerNotifier,
                        onRefreshProfile: _loadProfileData,
                        onRiwayatTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RiwayatScreen())),
                        onLogoutTap: () async {
                          await Provider.of<AuthProvider>(context,
                                  listen: false)
                              .logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (r) => false);
                        },
                      ),
                      Positioned(
                        bottom: -120,
                        left: 20,
                        right: 20,
                        child: StatusCard(
                          isMemuat: _isMemuatWaktu,
                          statusHadir: config['statusHariIni'],
                          statusHadirColor: config['warnaStatus'],
                          waktuServer: _waktuServerNotifier.value,
                          jamMasukServer: _jamMasukServer,
                          jamPulangServer: _jamPulangServer,
                          jarakMeter: _jarakMeter,
                          isMemuatLokasi: _isMemuatLokasi,
                          // PENAMBAHAN: Mengirim namaZona ke StatusCard
                          namaZona: _namaZona,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Layanan Siswa',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionMenu(
                            context: context,
                            title: 'Ajukan Izin',
                            subtitle: 'Sakit/Keperluan',
                            icon: Icons.edit_document,
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AjukanIzinScreen())),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionMenu(
                            context: context,
                            title: 'Status Izin',
                            subtitle: 'Riwayat Pengajuan',
                            icon: Icons.assignment_turned_in_rounded,
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RiwayatIzinScreen())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Informasi Sekolah',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    const PengumumanList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 65,
          child: ElevatedButton(
            onPressed: config['isTombolDisable']
                ? null
                : () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CameraScreen(
                                  tipeAbsen: config['tipeAbsen'],
                                  latSekolah: _latSekolah,
                                  lonSekolah: _lonSekolah,
                                  radius: _radius,
                                )));
                    _refreshSemuaData();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: config['warnaTombol'],
              disabledBackgroundColor:
                  (config['warnaTombol'] as Color).withOpacity(0.8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(config['iconTombol'], color: Colors.white),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(config['labelTombol'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(config['subLabel'],
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
