import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/api_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/services/order_service.dart';
import '../../profile/controllers/seller_profile_store.dart';
import 'service_catalog.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchSellerProfile();
  }

  Future<void> _fetchSellerProfile() async {
    final id = widget.serviceId;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil penjual tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/public-profile/by-service/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>?;
        if (mounted && data != null) {
          final seller = Map<String, dynamic>.from(data['seller'] ?? {});
          final loggedInUserId = await OrderService.getLoggedInUserId();
          final localStore = SellerProfileStore.instance;

          // Jika penjual adalah akun yang sedang login dan field di DB masih kosong,
          // lengkapi tampilan dengan data yang tersimpan di SellerProfileStore
          if ('${seller['id']}' == '$loggedInUserId') {
            if (_isEmptyVal(seller['universitas']) && localStore.university.trim().isNotEmpty) {
              seller['universitas'] = localStore.university.trim();
            }
            if (_isEmptyVal(seller['jurusan']) && localStore.program.trim().isNotEmpty) {
              seller['jurusan'] = localStore.program.trim();
            }
            if (_isEmptyVal(seller['nim']) && localStore.nim.trim().isNotEmpty) {
              seller['nim'] = localStore.nim.trim();
            }
            if (_isEmptyVal(seller['ipk']) && localStore.gpa.trim().isNotEmpty) {
              seller['ipk'] = localStore.gpa.trim();
            }
            if (_isEmptyVal(seller['bio']) && localStore.bio.trim().isNotEmpty) {
              seller['bio'] = localStore.bio.trim();
            }
            if (_isEmptyVal(seller['keahlian'])) {
              final combinedSkills = [...localStore.skills, ...localStore.customSkills];
              if (combinedSkills.isNotEmpty) {
                seller['keahlian'] = combinedSkills.join(', ');
              }
            }
          }

          setState(() {
            _profileData = {
              'seller': seller,
              'services': data['services'] ?? [],
            };
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetch public seller profile: $e');
    }

    final fallbackService = ServiceCatalog.byId(id);
    if (mounted) {
      if (fallbackService != null) {
        final sellerServices = ServiceCatalog.forSeller(fallbackService);
        setState(() {
          _profileData = {
            'seller': {
              'id': 0,
              'nama': fallbackService.seller,
              'universitas': '-',
              'jurusan': fallbackService.department,
              'nim': '-',
              'ipk': '-',
              'bio': fallbackService.description,
              'keahlian': fallbackService.category,
            },
            'services': sellerServices
                .map((s) => {
                      'id': s.id,
                      'judul': s.title,
                      'harga': s.price,
                      'nama_kategori': s.category,
                      'rating': s.rating,
                      'banner_url': null,
                    })
                .toList(),
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Profil penjual tidak ditemukan.';
        });
      }
    }
  }

  bool _isEmptyVal(dynamic val) {
    final s = (val ?? '').toString().trim();
    return s.isEmpty || s == '-';
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'M' : parts;
  }

  String _resolveBannerUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final hostBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$hostBase$normalizedPath';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F7FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text(
            'Profil Penjual',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null || _errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F7FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text('Profil Penjual'),
        ),
        body: Center(
          child: Text(_errorMessage ?? 'Profil penjual tidak ditemukan.'),
        ),
      );
    }

    final seller = (_profileData!['seller'] as Map<String, dynamic>?) ?? {};
    final services = (_profileData!['services'] as List<dynamic>?) ?? [];

    final sellerName = (seller['nama'] ?? '-').toString();
    final university = (seller['universitas'] ?? '-').toString();
    final department = (seller['jurusan'] ?? '-').toString();
    final nim = (seller['nim'] ?? '-').toString();
    final rawIpk = (seller['ipk'] ?? '-').toString().trim();
    final ipkDisplay = (rawIpk.isEmpty || rawIpk == '-')
        ? '-'
        : (rawIpk.contains('/') ? rawIpk : '$rawIpk / 4.00');
    final bio = (seller['bio'] ?? '-').toString();
    final rawSkills = (seller['keahlian'] ?? '').toString().trim();
    final skills = rawSkills.isEmpty
        ? <String>[]
        : rawSkills
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final initials = _getInitials(sellerName);
    final rawFotoUrl = (seller['foto_url'] ?? '').toString().trim();
    final resolvedFotoUrl = _resolveBannerUrl(rawFotoUrl);
    final localPhotoBytes = SellerProfileStore.instance.photoBytes;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: const AppBackButton(fallbackLocation: Routes.beranda),
        title: const Text(
          'Profil Penjual',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, thickness: 1.5, color: AppColors.primary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSellerProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            // Avatar Inisial Tengah
            Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.primary,
                backgroundImage: resolvedFotoUrl.isNotEmpty
                    ? NetworkImage(resolvedFotoUrl) as ImageProvider
                    : (localPhotoBytes != null ? MemoryImage(localPhotoBytes) : null),
                child: (resolvedFotoUrl.isEmpty && localPhotoBytes == null)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 22),

            // Kartu Utama Data Pribadi & Skill
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATA PRIBADI',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InlineInfoRow(label: 'Nama Lengkap:', value: sellerName),
                  const SizedBox(height: 12),
                  _InlineInfoRow(label: 'Nama Universitas:', value: university),
                  const SizedBox(height: 12),
                  _InlineInfoRow(
                      label: 'Fakultas / Program Studi:', value: department),
                  const SizedBox(height: 12),
                  _InlineInfoRow(label: 'NIM / Angkatan:', value: nim),
                  const SizedBox(height: 12),
                  _InlineInfoRow(label: 'IPK Terakhir:', value: ipkDisplay),
                  const SizedBox(height: 14),
                  const Text(
                    'Bio / Deskripsi Singkat Jasa:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    bio,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'KATEGORI / SKILL UTAMA:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (skills.isEmpty)
                    const Text(
                      '-',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                    color: const Color(0xFFBFDBFE)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Jasa yang Ditawarkan (${services.length})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (services.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Belum ada jasa aktif yang ditawarkan.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              )
            else
              for (final rawItem in services)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BackendSellerServiceCard(
                    item: rawItem as Map<String, dynamic>,
                    bannerUrl:
                        _resolveBannerUrl(rawItem['banner_url']?.toString()),
                    onTap: () => context.push(
                      '${Routes.serviceDetail}/${rawItem['id']}',
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfoRow extends StatelessWidget {
  const _InlineInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.4,
          fontFamily: 'PlusJakartaSans',
        ),
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendSellerServiceCard extends StatelessWidget {
  const _BackendSellerServiceCard({
    required this.item,
    required this.bannerUrl,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String bannerUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (item['judul'] ?? 'Jasa Mahasiswa').toString();
    final category = (item['nama_kategori'] ?? 'Jasa').toString();
    final price = double.tryParse('${item['harga'] ?? 0}')?.round() ?? 0;
    final rating = (item['rating'] ?? '5.0').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: bannerUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFDCEAFF),
                          child: Icon(
                            Icons.work_outline,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        )
                      : Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFDCEAFF),
                            child: Icon(
                              Icons.work_outline,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.currency(price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $category • ★ $rating',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}