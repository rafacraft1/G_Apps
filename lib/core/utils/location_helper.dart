import 'package:geolocator/geolocator.dart';

class LocationHelper {
  // =======================================================================
  // FUNGSI UTAMA: Ambil Lokasi + Status Fake GPS (Mengembalikan Map)
  // =======================================================================
  static Future<Map<String, dynamic>> getCurrentLocationWithMockStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'GPS Anda dinonaktifkan. Silakan nyalakan GPS terlebih dahulu.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak oleh pengguna.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak secara permanen. Anda harus mengizinkannya melalui Pengaturan HP.';
    }

    // Ambil koordinat saat ini
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // KUNCI KEAMANAN: Cek flag isMocked bawaan Geolocator
    bool isMocked = position.isMocked;

    return {
      'position': position,
      'is_mocked': isMocked,
    };
  }

  // Fungsi untuk mendapatkan titik koordinat HP saat ini (Bawaan Lama)
  static Future<Position> getCurrentLocation() async {
    Map<String, dynamic> data = await getCurrentLocationWithMockStatus();
    return data['position'] as Position;
  }

  // Fungsi untuk menghitung jarak antara 2 titik koordinat (dalam satuan Meter)
  static double hitungJarakMeter(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
