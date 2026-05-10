import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class PengumumanProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _listPengumuman = [];
  List<dynamic> get listPengumuman => _listPengumuman;

  Future<void> fetchPengumuman() async {
    _isLoading = true;
    // Beritahu UI kalau kita sedang loading
    Future.microtask(() => notifyListeners());

    try {
      // Panggil endpoint /pengumuman dari CodeIgniter
      final response = await ApiClient().dio.get('/pengumuman');

      if (response.data != null && response.data['status'] == 'success') {
        _listPengumuman = response.data['data']; // Simpan array pengumumannya
      } else {
        _listPengumuman = [];
      }
    } catch (e) {
      debugPrint('Error fetch pengumuman: $e');
      _listPengumuman = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Beritahu UI bahwa data sudah siap dan loading selesai
    }
  }
}
