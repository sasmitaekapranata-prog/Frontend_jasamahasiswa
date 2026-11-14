import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/seller_service_store.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class ServiceInfo {
  const ServiceInfo({
    required this.id,
    required this.title,
    required this.seller,
    required this.department,
    required this.rating,
    required this.reviews,
    required this.salesCount,
    required this.price,
    required this.category,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.description,
    required this.includes,
    this.coverBytes,
  });

  final String id;
  final String title;
  final String seller;
  final String department;
  final String rating;
  final int reviews;
  final int salesCount;
  final int price;
  final String category;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String description;
  final List<String> includes;
  final Uint8List? coverBytes;

  String get formattedPrice => Formatters.currency(price);
}

class ServiceCatalog {
  ServiceCatalog._();

  static const services = [
    ServiceInfo(
      id: 'web-react',
      title: 'Jasa Pembuatan Web React & Tailwind',
      seller: 'Andi Pratama',
      department: 'Informatika UI',
      rating: '4.9',
      reviews: 12,
      salesCount: 16,
      price: 50000,
      category: 'Coding',
      color: Color(0xFFDCEAFF),
      iconColor: AppColors.primary,
      icon: Icons.code,
      description:
          'Menerima jasa pembuatan landing page ataupun web responsif menggunakan React.js & Tailwind CSS. Cocok untuk tugas kuliah, awal startup, atau proyek personal.',
      includes: [
        'Source Code Lengkap (GitHub/ZIP)',
        'Gratis Revisi 2x',
        'Respon Layanan Mobile & Desktop',
      ],
    ),
    ServiceInfo(
      id: 'desain-ppt',
      title: 'Desain PPT & Poster Aesthetic',
      seller: 'Alval',
      department: 'Desain Komunikasi Visual',
      rating: '5.0',
      reviews: 18,
      salesCount: 18,
      price: 25000,
      category: 'Desain',
      color: Color(0xFFFFF3C4),
      iconColor: Color(0xFFF59E0B),
      icon: Icons.palette,
      description:
          'Desain presentasi dan poster yang rapi, menarik, dan disesuaikan dengan kebutuhan tugas atau acara kampus.',
      includes: [
        'File final siap presentasi/cetak',
        'Gratis revisi 2x',
        'Desain sesuai tema pilihan',
      ],
    ),
    ServiceInfo(
      id: 'olah-data',
      title: 'Olah Data SPSS & Skripsi',
      seller: 'Nabila',
      department: 'Statistika',
      rating: '4.8',
      reviews: 30,
      salesCount: 30,
      price: 75000,
      category: 'Tugas',
      color: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
      icon: Icons.insert_chart,
      description:
          'Bantuan pengolahan data penelitian menggunakan SPSS, termasuk penjelasan hasil yang mudah dipahami.',
      includes: [
        'File output dan data olahan',
        'Penjelasan hasil analisis',
        'Gratis revisi 1x',
      ],
    ),
  ];

  static ServiceInfo? byId(String? id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    for (final service in SellerServiceStore.instance.services) {
      if (service.id == id) return _fromSellerService(service);
    }
    return null;
  }

  static List<ServiceInfo> forSeller(ServiceInfo seller) {
    return [
      ...services.where((service) => service.seller == seller.seller),
      ...SellerServiceStore.instance.services
          .where(
            (service) =>
                service.sellerName == seller.seller &&
                (service.status == SellerServiceStatus.active ||
                    service.id == seller.id),
          )
          .map(_fromSellerService),
    ];
  }

  static ServiceInfo _fromSellerService(SellerService service) {
    final (color, iconColor, icon) = switch (service.category.toLowerCase()) {
      'coding' || 'pengembangan web & aplikasi' => (
          const Color(0xFFDCEAFF),
          AppColors.primary,
          Icons.code,
        ),
      'desain' || 'desain grafis & branding' => (
          const Color(0xFFFFF3C4),
          const Color(0xFFF59E0B),
          Icons.palette_outlined,
        ),
      _ => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          Icons.work_outline,
        ),
    };

    return ServiceInfo(
      id: service.id,
      title: service.title,
      seller: service.sellerName,
      department: service.sellerDepartment,
      rating: service.rating,
      reviews: 0,
      salesCount: service.salesCount,
      price: service.price,
      category: service.category,
      color: color,
      iconColor: iconColor,
      icon: icon,
      description: service.description,
      includes: service.deliverables,
      coverBytes: service.coverBytes,
    );
  }
}
