import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/api_config.dart';
import '../../profile/controllers/user_role_controller.dart';
import '../controllers/chat_activity_store.dart';
import 'order_payment.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  // 1. Variabel penampung data dinamis dari Backend
  List<ServiceItem> _services = [];
  bool _isLoading = true;

  static const _categories = ['Semua', 'Coding', 'Desain', 'Tugas', 'Tutor', 'Ketik'];

  @override
  void initState() {
    super.initState();
    _fetchServices(); // Ambil data saat halaman dimuat
  }

  // 2. Fungsi untuk mengambil data dari Backend
  Future<void> _fetchServices() async {
    final services = await HomeService().getServices();
    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNotifications() {
    final role = UserRoleController.instance.selectedRole;
    final orders = BuyerOrderStore.instance;
    if (role == UserRole.penjual && orders.sellerUnreadCount > 0) {
      context.go(Routes.incomingOrders);
    } else if (role == UserRole.pembeli && orders.buyerUnreadCount > 0) {
      context.go(Routes.statusPesanan);
    } else {
      context.go(Routes.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Logika Filter Pencarian
    final visibleServices = _services.where((service) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          service.judul.toLowerCase().contains(query) ||
          service.namaPenjual.toLowerCase().contains(query);
      return matchesSearch;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _BrandHeader(onNotificationsPressed: _openNotifications),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2864F0), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diskon 20% Tugas Akhir!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gunakan kode: MAHASISWABISA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Klaim Promo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Mau cari jasa apa hari ini?',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('KATEGORI POPULER'),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('REKOMENDASI JASA'),
            const SizedBox(height: 8),

            // 4. Menampilkan Status Loading atau Daftar Jasa
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'Jasa tidak ditemukan.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...visibleServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ServiceCard(
                    service: service,
                    onTap: () => context.go(
                      '${Routes.serviceDetail}/${service.id}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onNotificationsPressed});

  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jasa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              'Mahasiswa',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: Listenable.merge([
            UserRoleController.instance,
            BuyerOrderStore.instance,
            ChatActivityStore.instance,
          ]),
          builder: (context, _) {
            final role = UserRoleController.instance.selectedRole;
            final orderStore = BuyerOrderStore.instance;
            final orderCount = role == UserRole.penjual
                ? orderStore.sellerUnreadCount
                : orderStore.buyerUnreadCount;
            final count = orderCount +
                ChatActivityStore.instance.unreadCount(role);

            return IconButton(
              onPressed: onNotificationsPressed,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppColors.primary,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 15, minHeight: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Notifikasi',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEAF2FF),
                minimumSize: const Size(38, 38),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  IconData _getDynamicIcon() {
    final title = service.judul.toLowerCase();
    if (title.contains('web') || title.contains('coding') || title.contains('react')) {
      return Icons.code;
    }
    if (title.contains('desain') || title.contains('ppt') || title.contains('poster')) {
      return Icons.palette;
    }
    return Icons.insert_chart;
  }

  Color _getDynamicIconColor() {
    final title = service.judul.toLowerCase();
    if (title.contains('web') || title.contains('coding')) return AppColors.primary;
    if (title.contains('desain') || title.contains('ppt')) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  Color _getDynamicBgColor() {
    final title = service.judul.toLowerCase();
    if (title.contains('web') || title.contains('coding')) return const Color(0xFFEEF5FF);
    if (title.contains('desain') || title.contains('ppt')) return const Color(0xFFFFF3C4);
    return const Color(0xFFDCFCE7);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // BAGIAN 1: Thumbnail Foto Sampul (atau Ikon Default jika null)
              Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _getDynamicBgColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: service.fullBannerUrl != null
                    ? Image.network(
                        service.fullBannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _getDynamicIcon(),
                          color: _getDynamicIconColor(),
                          size: 30,
                        ),
                      )
                    : Icon(
                        _getDynamicIcon(),
                        color: _getDynamicIconColor(),
                        size: 30,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Penjual: ${service.namaPenjual}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          '${service.rating} (${service.reviewCount} ulasan)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rp${service.harga}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// MODEL & SERVICE BACKEND
// -------------------------------------------------------------

class ServiceItem {
  final String id;
  final String judul;
  final String harga;
  final double rating;
  final int reviewCount;
  final String namaPenjual;
  final String? bannerUrl; // BAGIAN 2: Field bannerUrl ditambahkan di sini

  ServiceItem({
    required this.id,
    required this.judul,
    required this.harga,
    required this.rating,
    required this.reviewCount,
    required this.namaPenjual,
    this.bannerUrl,
  });

  // Menggabungkan domain server dengan path '/uploads/...'
  String? get fullBannerUrl {
    if (bannerUrl == null || bannerUrl!.isEmpty) return null;
    if (bannerUrl!.startsWith('http')) return bannerUrl;
    final serverRoot = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$serverRoot$bannerUrl';
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    String formatHarga(dynamic rawHarga) {
      if (rawHarga == null) return '0';
      double val = double.parse(rawHarga.toString());
      return val.toStringAsFixed(0);
    }

    return ServiceItem(
      id: json['id']?.toString() ?? '0',
      judul: json['judul'] ?? '',
      harga: formatHarga(json['harga']),
      rating: json['rating'] != null
          ? double.parse(json['rating'].toString())
          : 0.0,
      reviewCount: json['review_count'] ?? 0,
      namaPenjual: json['nama_penjual'] ?? 'Anonim',
      bannerUrl: json['banner_url'],
    );
  }
}

class HomeService {
  Future<List<ServiceItem>> getServices() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/services');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> servicesJson = data['data'];

        return servicesJson.map((json) => ServiceItem.fromJson(json)).toList();
      } else {
        debugPrint('Gagal mengambil data. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error saat getServices: $e');
      return [];
    }
  }
}