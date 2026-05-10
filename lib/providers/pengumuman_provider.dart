import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class PengumumanProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _listPengumuman = [];
  List<dynamic> get listPengumuman => _listPengumuman;

  Future<void> fetchPengumuman() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final response = await ApiClient().dio.get('/pengumuman');

      if (response.statusCode == 200 && response.data != null) {
        // PERBAIKAN: Menambahkan pengecekan key 'status' dan null safety '?? []'
        if (response.data['status'] == 200 ||
            response.data['status'] == 'success') {
          _listPengumuman = response.data['data'] ?? [];
        } else {
          _listPengumuman = [];
        }
      } else {
        _listPengumuman = [];
      }
    } catch (e) {
      debugPrint('Error fetch pengumuman: $e');
      _listPengumuman = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
