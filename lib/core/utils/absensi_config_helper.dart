import 'package:flutter/material.dart';

class AbsensiConfigHelper {
  static Map<String, dynamic> getKonfigurasi({
    required DateTime? waktuSaatIni,
    required bool isMemuatWaktu,
    required bool isMemuatLokasi,
    required String jamBukaServer,
    required String jamPulangServer,
    required bool isLibur,
    required String namaLibur,
    required Map<String, dynamic>? dataAbsenHariIni,
    required double? jarakMeter,
    required double radius,
  }) {
    String statusHariIni = 'Memuat...';
    Color warnaStatus = Colors.grey;
    String labelTombol = 'Memuat...';
    String subLabel = 'Mohon tunggu...';
    Color warnaTombol = Colors.grey;
    IconData iconTombol = Icons.hourglass_empty;
    bool isTombolDisable = isMemuatWaktu || isMemuatLokasi;
    String tipeAbsen = 'masuk';

    if (!isTombolDisable && waktuSaatIni != null) {
      try {
        List<String> jp = jamPulangServer.split(':');
        List<String> jb = jamBukaServer.split(':');

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

        if (isLibur) {
          statusHariIni = 'Libur';
          warnaStatus = Colors.grey;
          labelTombol = 'Sekolah Libur';
          subLabel = namaLibur.isNotEmpty ? namaLibur : 'Libur Akhir Pekan';
          warnaTombol = Colors.grey;
          iconTombol = Icons.event_busy;
          isTombolDisable = true;
        } else if (dataAbsenHariIni == null) {
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
            } else if (jarakMeter == null) {
              labelTombol = 'Lokasi Tidak Valid';
              subLabel = 'Pastikan GPS perangkat Anda aktif';
              warnaTombol = Colors.red;
              iconTombol = Icons.gps_off;
              isTombolDisable = true;
            } else if (jarakMeter > radius) {
              labelTombol = 'Di Luar Zona';
              subLabel = 'Tidak bisa absen diluar zona lokasi absen';
              warnaTombol = Colors.redAccent;
              iconTombol = Icons.location_off;
              isTombolDisable = true;
            } else {
              labelTombol = 'Absen Masuk';
              subLabel = 'Ketuk untuk mulai';
              warnaTombol = Colors.blue;
              iconTombol = Icons.login;
              isTombolDisable = false;
            }
          }
        } else {
          String statusAbsenServer = dataAbsenHariIni['status'] ?? '';

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

            if (dataAbsenHariIni['jam_masuk'] == null) {
              tipeAbsen = 'masuk_dispensasi';
              labelTombol = 'Absen Lokasi Kegiatan';
              subLabel = 'Ketuk untuk kirim bukti tiba';
              warnaTombol = Colors.teal;
              iconTombol = Icons.pin_drop_rounded;
              isTombolDisable = false;
            } else if (dataAbsenHariIni['jam_pulang'] == null) {
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
          } else if (dataAbsenHariIni['jam_pulang'] == null) {
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
            } else if (jarakMeter == null) {
              labelTombol = 'Lokasi Tidak Valid';
              subLabel = 'Pastikan GPS perangkat Anda aktif';
              warnaTombol = Colors.red;
              iconTombol = Icons.gps_off;
              isTombolDisable = true;
            } else if (jarakMeter > radius) {
              labelTombol = 'Di Luar Zona';
              subLabel = 'Tidak bisa absen diluar zona lokasi absen';
              warnaTombol = Colors.redAccent;
              iconTombol = Icons.location_off;
              isTombolDisable = true;
            } else {
              labelTombol = 'Absen Pulang';
              subLabel = 'Ketuk untuk pulang';
              warnaTombol = Colors.orange;
              iconTombol = Icons.logout;
              isTombolDisable = false;
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
}
