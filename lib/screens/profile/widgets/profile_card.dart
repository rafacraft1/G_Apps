import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileCard extends StatelessWidget {
  final String namaSiswa;
  final String namaKelas;
  final String? fotoUrl;
  final bool isUploading;
  final VoidCallback onUploadTap;
  final String Function(String?) getValidUrl;

  const ProfileCard({
    super.key,
    required this.namaSiswa,
    required this.namaKelas,
    required this.fotoUrl,
    required this.isUploading,
    required this.onUploadTap,
    required this.getValidUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Kotak Putih Latar Belakang
        Container(
          margin: const EdgeInsets.only(top: 55),
          padding: const EdgeInsets.fromLTRB(20, 65, 20, 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                namaSiswa,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[100]!.withOpacity(0.5)),
                ),
                child: Text(
                  namaKelas != 'Siswa Aktif'
                      ? 'Kelas $namaKelas'
                      : 'Siswa Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Foto Profil Menumpuk di Atas Kotak
        Positioned(
          top: 0,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: 'profil_avatar',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ]),
                  child: CircleAvatar(
                    radius: 54, // Sedikit diperbesar
                    backgroundColor: Colors.blue[50],
                    backgroundImage: fotoUrl != null && fotoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(getValidUrl(fotoUrl))
                        : null,
                    child: fotoUrl == null || fotoUrl!.isEmpty
                        ? Text(
                            namaSiswa.isNotEmpty
                                ? namaSiswa.substring(0, 1).toUpperCase()
                                : 'S',
                            style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue[800]),
                          )
                        : null,
                  ),
                ),
              ),

              // Tombol Kamera / Indikator Loading
              isUploading
                  ? Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4)
                            ]),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.orange[600])),
                      ),
                    )
                  : GestureDetector(
                      onTap: onUploadTap,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4, right: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                Colors.orange[400]!,
                                Colors.orange[700]!
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
