import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/absensi_provider.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../auth/login_screen.dart';

class PreviewBottomSheet {
  static void show({
    required BuildContext context,
    required File foto,
    required double lat,
    required double lon,
    required bool isMasuk,
    required bool isDispensasi,
    required bool isFakeGpsDetected,
    required double accuracy,
    required VoidCallback onRetakeAction,
  }) {
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
                      onPressed: () {
                        if (foto.existsSync()) foto.deleteSync();
                        Navigator.pop(sheetContext);
                        onRetakeAction();
                      },
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

                        Navigator.pop(sheetContext); // Tutup bottomsheet

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
                            isMocked: isFakeGpsDetected,
                            accuracy: accuracy,
                            deviceTimestamp:
                                (DateTime.now().millisecondsSinceEpoch ~/ 1000),
                            tipeAbsen: isMasuk ? 'masuk' : 'pulang',
                          );

                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true)
                              .pop(); // Tutup Loading

                          if (sukses) {
                            if (!context.mounted) return;
                            Navigator.of(context)
                                .pop(); // Tutup Kamera (Kembali ke Dashboard)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
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
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true)
                              .pop(); // Tutup Loading jika error

                          String pesanError = e.toString();

                          if (pesanError.toLowerCase().contains('fake gps') ||
                              pesanError.toLowerCase().contains('diblokir')) {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Row(children: [
                                  Icon(Icons.warning_rounded,
                                      color: Colors.red, size: 28),
                                  SizedBox(width: 8),
                                  Text('Pelanggaran Keamanan',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16))
                                ]),
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
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Mengerti'),
                                  )
                                ],
                              ),
                            );
                            return;
                          }

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(pesanError),
                              backgroundColor: Colors.red));

                          if (pesanError.toLowerCase().contains('token') ||
                              pesanError.toLowerCase().contains('sesi')) {
                            await SecureStorageHelper.clearAll();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false);
                          } else {
                            onRetakeAction();
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
}
