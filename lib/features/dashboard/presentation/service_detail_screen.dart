import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/api_config.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/services/review_service.dart';
import 'order_payment.dart';
import 'service_catalog.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceDetail? _service;
  List<ServiceReviewItem> _reviews = [];
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
  }

  Future<void> _fetchServiceDetail() async {
    if (widget.serviceId == null) {
      setState(() => _isError = true);
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/services/${widget.serviceId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedReviews =
            await ReviewService.getServiceReviews(widget.serviceId!);
        if (!mounted) return;
        setState(() {
          _service = ServiceDetail.fromJson(data['data']);
          _reviews = fetchedReviews;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error get detail: $e');
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  ServiceInfo _toServiceInfo(ServiceDetail detail) {
    final kategori = detail.namaKategori.toLowerCase();
    final (color, iconColor, icon) = switch (kategori) {
      'coding' => (
          const Color(0xFFDCEAFF),
          AppColors.primary,
          Icons.code,
        ),
      'desain' => (
          const Color(0xFFFFF3C4),
          const Color(0xFFF59E0B),
          Icons.palette,
        ),
      _ => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          Icons.insert_chart,
        ),
    };

    return ServiceInfo(
      id: detail.id,
      title: detail.judul,
      seller: detail.namaPenjual,
      department: detail.jurusanPenjual,
      rating: detail.rating.toString(),
      reviews: detail.reviewCount,
      salesCount: detail.reviewCount,
      price: int.tryParse(detail.harga) ?? 0,
      category: detail.namaKategori,
      color: color,
      iconColor: iconColor,
      icon: icon,
      description: detail.deskripsi,
      includes: [
        'Paket: ${detail.namaPaket}',
        'Waktu Pengerjaan: ${detail.waktuPengerjaan} Hari',
        'Maksimal Revisi: ${detail.jumlahRevisi}x',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text('Detail Jasa'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError || _service == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text('Detail Jasa'),
        ),
        body: const Center(child: Text('Jasa tidak ditemukan.')),
      );
    }

    final service = _service!;
    final displayRating = _reviews.isNotEmpty
        ? (_reviews.map((e) => e.rating).reduce((a, b) => a + b) /
                _reviews.length)
            .toStringAsFixed(1)
        : service.rating.toString();
    final displayReviewCount =
        _reviews.isNotEmpty ? _reviews.length : service.reviewCount;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.beranda),
        title: const Text(
          'Detail Jasa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ServiceIllustration(service: service),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.judul,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rp${service.harga}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3C4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF59E0B),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$displayRating ($displayReviewCount Ulasan)',
                            style: const TextStyle(
                              color: Color(0xFF9A5A00),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: AppColors.border),
                _SellerCard(service: service),
                const SizedBox(height: 14),
                const _SectionLabel('DESKRIPSI JASA'),
                const SizedBox(height: 5),
                Text(
                  service.deskripsi,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('PAKET TERMASUK'),
                const SizedBox(height: 7),
                _CheckListItem(text: 'Paket: ${service.namaPaket}'),
                _CheckListItem(
                  text: 'Waktu Pengerjaan: ${service.waktuPengerjaan} Hari',
                ),
                _CheckListItem(
                  text: 'Maksimal Revisi: ${service.jumlahRevisi}x',
                ),
                const SizedBox(height: 14),
                _SectionLabel('ULASAN PEMBELI ($displayReviewCount)'),
                const SizedBox(height: 7),
                if (_reviews.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Belum ada ulasan untuk jasa ini.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  Column(
                    children: _reviews
                        .map(
                          (rev) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RealReviewCard(review: rev),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final preOrderContext = OrderPayment(
                    sellerId: service.sellerId,
                    service: _toServiceInfo(service),
                    brief: '',
                    paymentMethod: 'QRIS',
                    total: 0,
                  );
                  context.push(
                    '${Routes.chatDetail}/${service.sellerId}',
                    extra: preOrderContext,
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(88, 48),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(
                    Routes.orderCheckout,
                    extra: _toServiceInfo(service),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Pesan Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckListItem extends StatelessWidget {
  final String text;
  const _CheckListItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceIllustration extends StatelessWidget {
  const _ServiceIllustration({required this.service});

  final ServiceDetail service;

  Color _getDynamicBgColor() {
    final title = service.judul.toLowerCase();
    if (title.contains('web') || title.contains('coding')) {
      return const Color(0xFFEEF5FF);
    }
    if (title.contains('desain') || title.contains('ppt')) {
      return const Color(0xFFFFF3C4);
    }
    return const Color(0xFFDCFCE7);
  }

  Widget _buildDefaultIllustration() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Center(
        child: Container(
          width: 140,
          height: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF93C5FD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 92,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      color: _getDynamicBgColor(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (service.fullBannerUrl != null)
            Image.network(
              service.fullBannerUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultIllustration(),
            )
          else
            _buildDefaultIllustration(),
          Positioned(
            left: 16,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                service.namaKategori.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.service});

  final ServiceDetail service;

  Color _getDynamicIconColor() {
    final title = service.judul.toLowerCase();
    if (title.contains('web') || title.contains('coding')) {
      return AppColors.primary;
    }
    if (title.contains('desain') || title.contains('ppt')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final rawFoto = (service.fotoPenjual ?? '').trim();
              final hostBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
              final resolvedFoto = rawFoto.isEmpty
                  ? ''
                  : (rawFoto.startsWith('http') ? rawFoto : '$hostBase$rawFoto');
              return CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFDCEAFF),
                backgroundImage: resolvedFoto.isNotEmpty
                    ? NetworkImage(resolvedFoto) as ImageProvider
                    : null,
                child: resolvedFoto.isEmpty
                    ? Icon(Icons.person, color: _getDynamicIconColor(), size: 19)
                    : null,
              );
            },
          ),




          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.namaPenjual,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${service.jurusanPenjual} - Online 2 jam lalu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.push(
              '${Routes.sellerProfile}/${service.id}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(64, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cek Profil', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RealReviewCard extends StatelessWidget {
  const _RealReviewCard({required this.review});

  final ServiceReviewItem review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFDCEAFF),
                child: Text(
                  review.buyerName.isNotEmpty
                      ? review.buyerName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.buyerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              '"${review.comment}"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ServiceDetail {
  final String id;
  final String judul;
  final String deskripsi;
  final String harga;
  final String namaPaket;
  final int waktuPengerjaan;
  final int jumlahRevisi;
  final double rating;
  final int reviewCount;
  final String namaKategori;
  final int sellerId;
  final String namaPenjual;
  final String jurusanPenjual;
  final String? bannerUrl; final String? fotoPenjual;

  ServiceDetail({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.harga,
    required this.namaPaket,
    required this.waktuPengerjaan,
    required this.jumlahRevisi,
    required this.rating,
    required this.reviewCount,
    required this.namaKategori,
    required this.sellerId,
    required this.namaPenjual,
    required this.jurusanPenjual,
    this.bannerUrl, this.fotoPenjual,
  });

  String? get fullBannerUrl {
    if (bannerUrl == null || bannerUrl!.isEmpty) return null;
    if (bannerUrl!.startsWith('http')) return bannerUrl;
    final serverRoot = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$serverRoot$bannerUrl';
  }

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    String formatHarga(dynamic rawHarga) {
      if (rawHarga == null) return '0';
      double val = double.parse(rawHarga.toString());
      return val.toStringAsFixed(0);
    }

    return ServiceDetail(
      id: json['id']?.toString() ?? '0',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi',
      harga: formatHarga(json['harga']),
      namaPaket: json['nama_paket'] ?? 'Standar',
      waktuPengerjaan: json['waktu_pengerjaan'] ?? 1,
      jumlahRevisi: json['jumlah_revisi'] ?? 0,
      rating: json['rating'] != null
          ? double.parse(json['rating'].toString())
          : 0.0,
      reviewCount: json['review_count'] ?? 0,
      namaKategori: json['nama_kategori'] ?? 'Lainnya',
      sellerId: int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
      namaPenjual: json['nama_penjual'] ?? 'Anonim',
      jurusanPenjual: json['jurusan_penjual'] ?? 'Mahasiswa',
      bannerUrl: json['banner_url'], fotoPenjual: json['foto_penjual'],
    );
  }
}
