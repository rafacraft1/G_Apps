import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/pengumuman_provider.dart';

class PengumumanList extends StatelessWidget {
  const PengumumanList({super.key});

  // Fungsi untuk menampilkan popup detail pengumuman
  void _tampilkanDetailPengumuman(BuildContext context, dynamic item) {
    bool isPenting = item['tipe']?.toString().toLowerCase() == 'penting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Tinggi awal 60% layar
          minChildSize: 0.4,
          maxChildSize: 0.9, // Maksimal tinggi 90% layar jika teksnya panjang
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Garis Drag Handle di atas modal
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header: Ikon, Tanggal, Tipe
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPenting ? Colors.red[50] : Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPenting
                              ? Icons.campaign_rounded
                              : Icons.info_outline_rounded,
                          color: isPenting ? Colors.red[600] : Colors.blue[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPenting
                                  ? 'Informasi Penting'
                                  : 'Informasi Sekolah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPenting
                                    ? Colors.red[600]
                                    : Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['created_at']?.substring(0, 10) ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Judul Pengumuman
                  Text(
                    item['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1.3),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),

                  // Isi Pengumuman (Bisa di-scroll jika panjang)
                  Expanded(
                    child: ListView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Text(
                          item['isi'] ?? '',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.6,
                              letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // Tombol Tutup di bawah
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 24, top: 12),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Tutup Pengumuman',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(6))),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmer(width: 44, height: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    _buildShimmer(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmer(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          _buildShimmer(width: 200, height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PengumumanProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Column(
            children: List.generate(3, (index) => _buildShimmerCard()),
          );
        }

        if (provider.listPengumuman.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.grey[200]!, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Belum ada informasi terbaru',
                    style: TextStyle(
                        color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: provider.listPengumuman.length,
          itemBuilder: (context, index) {
            final item = provider.listPengumuman[index];
            bool isPenting =
                item['tipe']?.toString().toLowerCase() == 'penting';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  // PERBAIKAN: Fungsi klik sekarang aktif dan memanggil Popup
                  onTap: () => _tampilkanDetailPengumuman(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isPenting
                                    ? Colors.red[50]
                                    : Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPenting
                                    ? Icons.campaign_rounded
                                    : Icons.info_outline_rounded,
                                color: isPenting
                                    ? Colors.red[600]
                                    : Colors.blue[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['judul'] ?? 'Tanpa Judul',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['created_at']?.substring(0, 10) ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['isi'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Baca selengkapnya',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: Colors.blue[600]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
