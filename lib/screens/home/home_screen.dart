import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/absensi_config_helper.dart';
import '../../core/utils/app_info_helper.dart';
import '../../core/utils/dialog_helper.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.updateFCMToken();
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      homeProvider.loadProfileData();
      _animationController.forward();
      homeProvider.refreshSemuaData(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: Colors.blue[600],
            backgroundColor: Colors.white,
            onRefresh: () async {
              await provider.refreshSemuaData(context);
              _animationController.forward(from: 0.0);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 1. HEADER
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

                      // 2. KONTEN UTAMA
                      Transform.translate(
                        offset: const Offset(0, -45),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- STATUS KARTU ABSENSI ---
                                  ValueListenableBuilder<DateTime?>(
                                      valueListenable:
                                          provider.waktuServerNotifier,
                                      builder: (context, waktuSaatIni, child) {
                                        final config =
                                            AbsensiConfigHelper.getKonfigurasi(
                                          waktuSaatIni: waktuSaatIni,
                                          isMemuatWaktu: provider.isMemuatWaktu,
                                          isMemuatLokasi:
                                              provider.isMemuatLokasi,
                                          jamBukaServer: provider.jamBukaServer,
                                          jamPulangServer:
                                              provider.jamPulangServer,
                                          isLibur: provider.isLibur,
                                          namaLibur: provider.namaLibur,
                                          dataAbsenHariIni:
                                              provider.dataAbsenHariIni,
                                          jarakMeter: provider.jarakMeter,
                                          radius: provider.radius,
                                        );

                                        return StatusCard(
                                          isMemuat: provider.isMemuatWaktu,
                                          statusHadir: config['statusHariIni'],
                                          statusHadirColor:
                                              config['warnaStatus'],
                                          waktuServer: waktuSaatIni,
                                          jamMasukServer:
                                              provider.jamMasukServer,
                                          jamPulangServer:
                                              provider.jamPulangServer,
                                          jarakMeter: provider.jarakMeter,
                                          isMemuatLokasi:
                                              provider.isMemuatLokasi,
                                          namaZona: provider.namaZona,
                                          isTombolDisable:
                                              config['isTombolDisable'],
                                          warnaTombol: config['warnaTombol'],
                                          iconTombol: config['iconTombol'],
                                          labelTombol: config['labelTombol'],
                                          subLabel: config['subLabel'],
                                          onAbsenTap: () async {
                                            if (config['isTombolDisable']) {
                                              DialogHelper.showSnackBar(
                                                  "Belum memasuki jam presensi atau Anda sudah menyelesaikan presensi hari ini.");
                                              return;
                                            }
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        CameraScreen(
                                                          tipeAbsen: config[
                                                              'tipeAbsen'],
                                                          latSekolah: provider
                                                              .latSekolah,
                                                          lonSekolah: provider
                                                              .lonSekolah,
                                                          radius:
                                                              provider.radius,
                                                          namaZona:
                                                              provider.namaZona,
                                                        )));
                                            if (context.mounted) {
                                              provider
                                                  .refreshSemuaData(context);
                                            }
                                          },
                                        );
                                      }),

                                  const SizedBox(height: 32),

                                  // --- MENU LAYANAN SISWA ---
                                  const Text('Layanan Siswa',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AnimatedMenuCard(
                                          title: 'Ajukan Izin',
                                          subtitle: 'Sakit/Keperluan',
                                          icon: Icons.edit_document,
                                          color: Colors.orange,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AjukanIzinScreen())),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _AnimatedMenuCard(
                                          title: 'Status Izin',
                                          subtitle: 'Riwayat Pengajuan',
                                          icon: Icons
                                              .assignment_turned_in_rounded,
                                          color: Colors.blue,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const RiwayatIzinScreen())),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 36),

                                  // --- PENGUMUMAN SEKOLAH ---
                                  const Text('Informasi Sekolah',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 16),
                                  const PengumumanList(),

                                  const SizedBox(height: 32),
                                  Center(child: AppInfoHelper.buildFooter()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedMenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _AnimatedMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isPressed ? 0.04 : 0.12),
                blurRadius: _isPressed ? 10 : 24,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // --- Ikon Watermark di Background ---
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Icon(
                        widget.icon,
                        size: 90,
                        color: widget.color.withOpacity(0.04),
                      ),
                    ),

                    // --- Konten Utama Card ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.color[400]!,
                                      widget.color[700]!
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Icon(widget.icon,
                                    color: Colors.white, size: 24),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: Colors.grey[300]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
