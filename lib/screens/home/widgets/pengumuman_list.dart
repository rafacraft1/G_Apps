import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/pengumuman_provider.dart';

class PengumumanList extends StatelessWidget {
  const PengumumanList({super.key});

  Widget _buildShimmer({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(4))),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(width: 200, height: 20),
          const SizedBox(height: 12),
          _buildShimmer(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          _buildShimmer(width: 250, height: 14),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildShimmer(width: 80, height: 12),
            _buildShimmer(width: 100, height: 12)
          ]),
        ],
      ),
    );
  }

  void _tampilkanDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10)))),
                  Text(item['judul'] ?? 'Tanpa Judul',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3)),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(item['created_at']?.substring(0, 10) ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(
                          height: 1, thickness: 1, color: Colors.black12)),
                  Text(item['isi'] ?? '',
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Pengumuman Terbaru',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        const SizedBox(height: 12),
        Consumer<PengumumanProvider>(
          builder: (context, pengumumanProvider, child) {
            if (pengumumanProvider.isLoading) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => _buildShimmerCard(),
              );
            }

            if (pengumumanProvider.listPengumuman.isEmpty) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Belum ada pengumuman.',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 15))
                    ]),
              ));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 4),
              itemCount: pengumumanProvider.listPengumuman.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = pengumumanProvider.listPengumuman[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _tampilkanDetail(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['judul'] ?? 'Tanpa Judul',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(item['isi'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.4)),
                          const SizedBox(height: 12),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['created_at']?.substring(0, 10) ?? '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.w600)),
                                const Text('Baca selengkapnya',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold))
                              ]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
