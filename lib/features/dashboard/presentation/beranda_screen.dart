import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
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

  static const _categories = ['Semua', 'Coding', 'Desain', 'Tugas', 'Tutor', 'Ketik'];
  static const _services = [
    _Service(
      id: 'web-react',
      title: 'Jasa Web React & UI Tailwind',
      seller: 'Arief (Informatika)',
      rating: '4.9',
      reviews: 24,
      price: 'Rp50.000',
      category: 'Coding',
      color: Color(0xFFEEF5FF),
      iconColor: AppColors.primary,
      icon: Icons.code,
    ),
    _Service(
      id: 'desain-ppt',
      title: 'Desain PPT & Poster Aesthetic',
      seller: 'Alval (DKV)',
      rating: '5.0',
      reviews: 18,
      price: 'Rp25.000',
      category: 'Desain',
      color: Color(0xFFFFF3C4),
      iconColor: Color(0xFFF59E0B),
      icon: Icons.palette,
    ),
    _Service(
      id: 'olah-data',
      title: 'Olah Data SPSS & Skripsi',
      seller: 'Nabila (Statistika)',
      rating: '4.8',
      reviews: 30,
      price: 'Rp75.000',
      category: 'Tugas',
      color: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
      icon: Icons.insert_chart,
    ),
  ];

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
    final visibleServices = _services.where((service) {
      final matchesCategory =
          _selectedCategory == 'Semua' || service.category == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          service.title.toLowerCase().contains(query) ||
          service.seller.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
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
            if (visibleServices.isEmpty)
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

  final _Service service;
  final VoidCallback onTap;

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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(service.icon, color: service.iconColor, size: 30),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
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
                      'Penjual: ${service.seller}',
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
                          '${service.rating} (${service.reviews} ulasan)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      service.price,
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

class _Service {
  const _Service({
    required this.id,
    required this.title,
    required this.seller,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.category,
    required this.color,
    required this.iconColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String seller;
  final String rating;
  final int reviews;
  final String price;
  final String category;
  final Color color;
  final Color iconColor;
  final IconData icon;
}
