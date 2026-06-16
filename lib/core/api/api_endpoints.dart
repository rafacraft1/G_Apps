class ApiEndpoints {
  static const String login = 'auth/login';
  static const String refresh = 'auth/refresh';
  static const String updateFcm = 'fcm/updateToken';
  static const String riwayatAbsen = 'absen/riwayat';
  static const String waktuServer = '/waktu_server';
  static const String updateLokasi = 'tracking/updateLokasi';

  static String absen(String tipe) => 'absen/$tipe';
}
