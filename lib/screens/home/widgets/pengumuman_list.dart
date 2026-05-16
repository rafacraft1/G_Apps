import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../providers/pengumuman_provider.dart';
import 'pdf_viewer_screen.dart';

class PengumumanList extends StatelessWidget {
  const PengumumanList({super.key});

  String _getValidFileUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    if (fileName.startsWith('http')) return fileName;
    try {
      String baseUrlEnv = dotenv.env['BASE_URL'] ?? '';
      if (baseUrlEnv.isEmpty) return fileName;
      Uri apiUri = Uri.parse(baseUrlEnv);
      String validHost =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      return '$validHost/uploads/pengumuman/$fileName';
    } catch (e) {
      return fileName;
    }
  }

  bool _isImage(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  void _bukaPratinjauGambar(
      BuildContext context, String imageUrl, String judul) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 20),
                color: Colors.black38,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        judul,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanDetailPengumuman(BuildContext context, dynamic item) {
    bool isPenting = item['tipe']?.toString().toLowerCase() == 'penting';
    String? namaLampiran = item['gambar'];
    String judul = item['judul'] ?? 'Pengumuman';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

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

                  Text(
                    judul,
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

                  // LAMPIRAN INTERAKTIF
                  if (namaLampiran != null && namaLampiran.isNotEmpty)
                    _isImage(namaLampiran)
                        ? GestureDetector(
                            onTap: () => _bukaPratinjauGambar(
                                context, _getValidFileUrl(namaLampiran), judul),
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              margin: const EdgeInsets.only(bottom: 16),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  SizedBox.expand(
                                    child: CachedNetworkImage(
                                      imageUrl: _getValidFileUrl(namaLampiran),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.broken_image,
                                              color: Colors.grey),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.fullscreen_rounded,
                                        color: Colors.white, size: 20),
                                  )
                                ],
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(
                                    url: _getValidFileUrl(namaLampiran),
                                    judul: judul,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(color: Colors.blue[100]!),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.picture_as_pdf_rounded,
                                        color: Colors.blue[700]),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Lampiran Dokumen (PDF)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87)),
                                        SizedBox(height: 4),
                                        Text('Ketuk untuk membuka langsung',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      color: Colors.blue[600], size: 16),
                                ],
                              ),
                            ),
                          ),

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
              offset: const Offset(0, 4)),
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
              children: List.generate(3, (index) => _buildShimmerCard()));
        }

        if (provider.listPengumuman.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
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
            bool adaLampiran =
                item['gambar'] != null && item['gambar'].toString().isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
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
                                        color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 16),
                        Text(
                          item['isi'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            adaLampiran
                                ? Row(
                                    children: [
                                      Icon(Icons.attach_file_rounded,
                                          size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text('Ada Lampiran',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500])),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            Row(
                              children: [
                                Text('Baca selengkapnya',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: Colors.blue[600]),
                              ],
                            ),
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
