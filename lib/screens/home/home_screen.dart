import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/absensi_config_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/notification_service.dart';

import '../auth/login_screen.dart';
import '../absen/camera_screen.dart';
import '../absen/riwayat_screen.dart';
import '../izin/ajukan_izin_screen.dart';
import '../izin/riwayat_izin_screen.dart';

import 'widgets/home_header.dart';
import 'widgets/status_card.dart';
import 'widgets/pengumuman_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.updateFCMToken();
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      homeProvider.loadProfileData();
      homeProvider.refreshSemuaData(context);
    });
  }

  Widget _buildActionMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(color: color[50], shape: BoxShape.circle),
                  child: Icon(icon, color: color[700], size: 24),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refreshSemuaData(context),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          HomeHeader(
                            namaSiswa: provider.namaSiswa,
                            namaKelas: provider.namaKelas,
                            fotoUrl: provider.fotoUrl,
                            waktuServerNotifier: provider.waktuServerNotifier,
                            onRefreshProfile: provider.loadProfileData,
                            onRiwayatTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RiwayatScreen())),
                            onLogoutTap: () async {
                              await Provider.of<AuthProvider>(context,
                                      listen: false)
                                  .logout();
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (r) => false);
                            },
                          ),
                          Positioned(
                            bottom: -120,
                            left: 20,
                            right: 20,
                            child: ValueListenableBuilder<DateTime?>(
                                valueListenable: provider.waktuServerNotifier,
                                builder: (context, waktuSaatIni, child) {
                                  final config =
                                      AbsensiConfigHelper.getKonfigurasi(
                                    waktuSaatIni: waktuSaatIni,
                                    isMemuatWaktu: provider.isMemuatWaktu,
                                    isMemuatLokasi: provider.isMemuatLokasi,
                                    jamBukaServer: provider.jamBukaServer,
                                    jamPulangServer: provider.jamPulangServer,
                                    isLibur: provider.isLibur,
                                    namaLibur: provider.namaLibur,
                                    dataAbsenHariIni: provider.dataAbsenHariIni,
                                    jarakMeter: provider.jarakMeter,
                                    radius: provider.radius,
                                  );

                                  return StatusCard(
                                    isMemuat: provider.isMemuatWaktu,
                                    statusHadir: config['statusHariIni'],
                                    statusHadirColor: config['warnaStatus'],
                                    waktuServer: waktuSaatIni,
                                    jamMasukServer: provider.jamMasukServer,
                                    jamPulangServer: provider.jamPulangServer,
                                    jarakMeter: provider.jarakMeter,
                                    isMemuatLokasi: provider.isMemuatLokasi,
                                    namaZona: provider.namaZona,
                                  );
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Layanan Siswa',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildActionMenu(
                                    context: context,
                                    title: 'Ajukan Izin',
                                    subtitle: 'Sakit/Keperluan',
                                    icon: Icons.edit_document,
                                    color: Colors.orange,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AjukanIzinScreen())))),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildActionMenu(
                                    context: context,
                                    title: 'Status Izin',
                                    subtitle: 'Riwayat Pengajuan',
                                    icon: Icons.assignment_turned_in_rounded,
                                    color: Colors.blue,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RiwayatIzinScreen())))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text('Informasi Sekolah',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        const PengumumanList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return ValueListenableBuilder<DateTime?>(
            valueListenable: provider.waktuServerNotifier,
            builder: (context, waktuSaatIni, child) {
              final config = AbsensiConfigHelper.getKonfigurasi(
                waktuSaatIni: waktuSaatIni,
                isMemuatWaktu: provider.isMemuatWaktu,
                isMemuatLokasi: provider.isMemuatLokasi,
                jamBukaServer: provider.jamBukaServer,
                jamPulangServer: provider.jamPulangServer,
                isLibur: provider.isLibur,
                namaLibur: provider.namaLibur,
                dataAbsenHariIni: provider.dataAbsenHariIni,
                jarakMeter: provider.jarakMeter,
                radius: provider.radius,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: config['isTombolDisable']
                        ? null
                        : () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CameraScreen(
                                          tipeAbsen: config['tipeAbsen'],
                                          latSekolah: provider.latSekolah,
                                          lonSekolah: provider.lonSekolah,
                                          radius: provider.radius,
                                          namaZona: provider.namaZona,
                                        )));
                            if (context.mounted) {
                              provider.refreshSemuaData(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config['warnaTombol'],
                      disabledBackgroundColor:
                          (config['warnaTombol'] as Color).withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(config['iconTombol'], color: Colors.white),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(config['labelTombol'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text(config['subLabel'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
