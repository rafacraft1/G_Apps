import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/izin_provider.dart';
import '../../core/utils/app_info_helper.dart';

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
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tglMulai = picked;
          // Auto-adjust tanggal selesai jika lebih kecil dari tanggal mulai
          if (_tglSelesai != null && _tglSelesai!.isBefore(_tglMulai!)) {
            _tglSelesai = _tglMulai;
          }
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Mohon pilih rentang tanggal!'),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_fotoBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Mohon lampirkan foto bukti!'),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<IzinProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Pengajuan berhasil dikirim!'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Form Pengajuan',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.3)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KATEGORI IZIN ---
              const Text('Pilih Kategori',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTypeChip('Sakit', Icons.medical_services_outlined),
                    const SizedBox(width: 12),
                    _buildTypeChip('Izin', Icons.assignment_outlined),
                    const SizedBox(width: 12),
                    _buildTypeChip('Dispensasi', Icons.verified_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- KARTU DETAIL FORM ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rentang Waktu',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTile('Tgl Mulai', _tglMulai,
                              () => _pilihTanggal(context, true)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateTile('Tgl Selesai', _tglSelesai,
                              () => _pilihTanggal(context, false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text('Keterangan / Alasan',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alasanController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan secara detail...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.blue[300]!, width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Keterangan terlalu pendek'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    const Text('Lampiran Bukti (Foto)',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _ambilFoto,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _fotoBukti != null
                              ? Colors.black
                              : Colors.blue[50]?.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _fotoBukti != null
                                  ? Colors.transparent
                                  : Colors.blue[200]!,
                              style: BorderStyle.solid,
                              width: 1.5),
                        ),
                        child: _fotoBukti != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(_fotoBukti!,
                                        fit: BoxFit.cover,
                                        color: Colors.black.withOpacity(0.2),
                                        colorBlendMode: BlendMode.darken),
                                  ),
                                  const Center(
                                    child: Icon(Icons.autorenew_rounded,
                                        color: Colors.white, size: 32),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]),
                                    child: Icon(Icons.add_a_photo_rounded,
                                        size: 28, color: Colors.blue[600]),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Ketuk untuk memotret surat',
                                      style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // --- TOMBOL SUBMIT ---
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Kirim Pengajuan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 32),
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
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
                  : "Pilih Tanggal",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: date != null ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon) {
    bool isSelected = _jenisIzin == type;
    return GestureDetector(
      onTap: () => setState(() => _jenisIzin = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[300]!),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
