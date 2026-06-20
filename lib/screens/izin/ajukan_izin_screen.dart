import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/izin_provider.dart';
import '../../core/utils/app_info_helper.dart'; // [TAMBAHAN BARU]

class AjukanIzinScreen extends StatefulWidget {
  const AjukanIzinScreen({super.key});

  @override
  State<AjukanIzinScreen> createState() => _AjukanIzinScreenState();
}

class _AjukanIzinScreenState extends State<AjukanIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _alasanController = TextEditingController();

  DateTime? _tglMulai;
  DateTime? _tglSelesai;
  String _jenisIzin = 'Sakit';
  File? _fotoBukti;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[700]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tglMulai = picked;
        } else {
          _tglSelesai = picked;
        }
      });
    }
  }

  Future<void> _ambilFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() => _fotoBukti = File(image.path));
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tglMulai == null || _tglSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon pilih rentang tanggal!'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_fotoBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon lampirkan foto bukti!'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final provider = Provider.of<IzinProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final sukses = await provider.ajukanIzin(
        tanggalMulai:
            "${_tglMulai!.year}-${_tglMulai!.month.toString().padLeft(2, '0')}-${_tglMulai!.day.toString().padLeft(2, '0')}",
        tanggalSelesai:
            "${_tglSelesai!.year}-${_tglSelesai!.month.toString().padLeft(2, '0')}-${_tglSelesai!.day.toString().padLeft(2, '0')}",
        jenis: _jenisIzin,
        alasan: _alasanController.text,
        buktiFoto: _fotoBukti!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (sukses) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengajuan berhasil dikirim!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Form Pengajuan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Keterangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                        'Mulai', _tglMulai, () => _pilihTanggal(context, true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTile('Selesai', _tglSelesai,
                        () => _pilihTanggal(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Kategori',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTypeChip('Sakit'),
                  _buildTypeChip('Izin'),
                  _buildTypeChip('Dispensasi'),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Alasan / Nama Kegiatan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan secara detail...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.length < 5)
                    ? 'Keterangan terlalu pendek'
                    : null,
              ),
              const SizedBox(height: 24),

              const Text('Lampiran Bukti (Surat/Undangan)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _ambilFoto,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _fotoBukti != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_fotoBukti!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Ketuk untuk ambil foto',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Kirim Pengajuan',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
              // [TAMBAHAN BARU] Footer diletakkan di akhir layar pengajuan izin
              Center(child: AppInfoHelper.buildFooter()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? "${date.day}/${date.month}/${date.year}"
                  : "-- / -- / --",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    bool isSelected = _jenisIzin == type;
    return GestureDetector(
      onTap: () => setState(() => _jenisIzin = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          type,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
