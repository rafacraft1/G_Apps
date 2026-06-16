import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/secure_storage_helper.dart';
import '../repositories/server_repository.dart';
import '../services/location_service.dart';
import 'absensi_provider.dart';
import 'pengumuman_provider.dart';
import 'auth_provider.dart';
import '../screens/auth/login_screen.dart';

class HomeProvider extends ChangeNotifier {
  String namaSiswa = 'Siswa';
  String namaKelas = 'Siswa Aktif';
  String? fotoUrl;

  final ValueNotifier<DateTime?> waktuServerNotifier = ValueNotifier(null);
  Timer? _timer;

  bool isMemuatWaktu = true;
  bool isMemuatLokasi = true;
  Map<String, dynamic>? dataAbsenHariIni;

  bool isLibur = false;
  String namaLibur = '';

  String jamMasukServer = "07:00:00";
  String jamPulangServer = "15:00:00";
  String jamBukaServer = "06:00:00";
  double latSekolah = 0.0;
  double lonSekolah = 0.0;
  double radius = 50.0;
  String namaZona = 'Area Sekolah';

  double? jarakMeter;

  HomeProvider() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waktuServerNotifier.value != null) {
        waktuServerNotifier.value =
            waktuServerNotifier.value!.add(const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    waktuServerNotifier.dispose();
    super.dispose();
  }

  Future<void> loadProfileData() async {
    namaSiswa = await SecureStorageHelper.getUserName() ?? 'Siswa';
    fotoUrl = await SecureStorageHelper.getFotoProfile();
    namaKelas = await SecureStorageHelper.getUserKelas() ?? 'Siswa Aktif';
    notifyListeners();
  }

  Future<void> refreshSemuaData(BuildContext context) async {
    isMemuatWaktu = true;
    isMemuatLokasi = true;
    notifyListeners();

    try {
      final serverData = await ServerRepository.getServerData();

      if (serverData != null) {
        waktuServerNotifier.value = serverData['waktu'];
        isLibur = serverData['is_libur'] ?? false;
        namaLibur = serverData['nama_libur'] ?? serverData['keterangan'] ?? '';
        jamMasukServer = serverData['jam_masuk'] ?? "07:00:00";
        jamPulangServer = serverData['jam_pulang'] ?? "15:00:00";

        Map<String, dynamic>? pengaturan =
            serverData['pengaturan'] as Map<String, dynamic>?;
        jamBukaServer = pengaturan?['jam_buka'] ?? "06:00:00";

        latSekolah =
            double.tryParse(serverData['lat_sekolah']?.toString() ?? '0.0') ??
                0.0;
        lonSekolah =
            double.tryParse(serverData['lon_sekolah']?.toString() ?? '0.0') ??
                0.0;
        radius =
            double.tryParse(serverData['radius']?.toString() ?? '50.0') ?? 50.0;
        namaZona = serverData['nama_zona'] ?? 'Area Sekolah';
      }
      isMemuatWaktu = false;
      notifyListeners();

      if (waktuServerNotifier.value != null) {
        String tanggalHariIni =
            "${waktuServerNotifier.value!.year}-${waktuServerNotifier.value!.month.toString().padLeft(2, '0')}-${waktuServerNotifier.value!.day.toString().padLeft(2, '0')}";
        try {
          if (context.mounted) {
            dataAbsenHariIni =
                await Provider.of<AbsensiProvider>(context, listen: false)
                    .cekAbsenHariIni(tanggalHariIni);
            notifyListeners();
          }
        } catch (e) {
          if (e.toString().contains('sesi_habis') ||
              e.toString().contains('401')) {
            if (context.mounted) {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              }
            }
          }
        }
      }
    } catch (_) {
      isMemuatWaktu = false;
      notifyListeners();
    }

    await updateLokasiJarak();

    if (context.mounted) {
      Provider.of<PengumumanProvider>(context, listen: false).fetchPengumuman();
    }
  }

  Future<void> updateLokasiJarak() async {
    try {
      jarakMeter =
          await LocationService.getDistanceFrom(latSekolah, lonSekolah);
    } catch (_) {
      jarakMeter = null;
    } finally {
      isMemuatLokasi = false;
      notifyListeners();
    }
  }
}
