import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class PengumumanProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _listPengumuman = [];
  List<dynamic> get listPengumuman => _listPengumuman;

  static const String _cacheKey = 'pengumuman_cache';

  /// Mengambil data pengumuman dengan prioritas Cache Lokal
  Future<void> fetchPengumuman() async {
    final prefs = await SharedPreferences.getInstance();

    String? cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      _listPengumuman = jsonDecode(cachedData);
      Future.microtask(() => notifyListeners());
    } else {
      _isLoading = true;
      Future.microtask(() => notifyListeners());
    }

    try {
      final response = await ApiClient().dio.get('/pengumuman');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['status'] == 200 ||
            response.data['status'] == 'success') {
          _listPengumuman = response.data['data'] ?? [];
          await prefs.setString(_cacheKey, jsonEncode(_listPengumuman));
        } else if (cachedData == null) {
          _listPengumuman = [];
        }
      } else if (cachedData == null) {
        _listPengumuman = [];
      }
    } catch (e) {
      debugPrint('Error fetch pengumuman: $e');
      if (cachedData == null) _listPengumuman = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
