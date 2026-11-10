import 'package:flutter/foundation.dart';

enum SellerServiceStatus { active, inactive, draft, underReview }

class SellerService {
  const SellerService({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.description,
    required this.deliverables,
    required this.status,
    this.coverName,
    this.coverBytes,
    this.packageName = '',
    this.deliveryDays = 2,
    this.revisions = 2,
    this.salesCount = 0,
    this.rating = '0.0',
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final String description;
  final List<String> deliverables;
  final SellerServiceStatus status;
  final String? coverName;
  final Uint8List? coverBytes;
  final String packageName;
  final int deliveryDays;
  final int revisions;
  final int salesCount;
  final String rating;

  SellerService copyWith({
    String? title,
    int? price,
    String? category,
    String? description,
    List<String>? deliverables,
    SellerServiceStatus? status,
    String? coverName,
    Uint8List? coverBytes,
    String? packageName,
    int? deliveryDays,
    int? revisions,
  }) {
    return SellerService(
      id: id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      deliverables: deliverables ?? this.deliverables,
      status: status ?? this.status,
      coverName: coverName ?? this.coverName,
      coverBytes: coverBytes ?? this.coverBytes,
      packageName: packageName ?? this.packageName,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      revisions: revisions ?? this.revisions,
      salesCount: salesCount,
      rating: rating,
    );
  }
}

class SellerServiceStore extends ChangeNotifier {
  SellerServiceStore._();

  static final SellerServiceStore instance = SellerServiceStore._();

  final List<SellerService> _services = [
    const SellerService(
      id: 'seller-web-react',
      title: 'Jasa Web React & UI',
      price: 50000,
      category: 'Coding',
      description: 'Pembuatan antarmuka web menggunakan React.',
      deliverables: ['Source code', 'Revisi 2x'],
      status: SellerServiceStatus.active,
      salesCount: 15,
      rating: '4.9',
    ),
    const SellerService(
      id: 'seller-figma-html',
      title: 'Bantu Slicing Figma ke HTML',
      price: 25000,
      category: 'Coding',
      description: 'Konversi desain Figma menjadi halaman HTML responsif.',
      deliverables: ['File HTML/CSS', 'Revisi 1x'],
      status: SellerServiceStatus.active,
      salesCount: 5,
      rating: '5.0',
    ),
    const SellerService(
      id: 'seller-banner',
      title: 'Desain Banner & Poster UI',
      price: 30000,
      category: 'Desain',
      description: 'Desain banner dan poster untuk kebutuhan kampus.',
      deliverables: ['File siap cetak', 'Revisi 2x'],
      status: SellerServiceStatus.underReview,
      salesCount: 8,
      rating: '4.8',
    ),
    const SellerService(
      id: 'seller-logo',
      title: 'Desain Logo',
      price: 15000,
      category: 'Desain',
      description: 'Desain logo sederhana sesuai kebutuhan.',
      deliverables: ['File PNG', 'Revisi 1x'],
      status: SellerServiceStatus.inactive,
      salesCount: 3,
      rating: '5.0',
    ),
  ];

  List<SellerService> get services => List.unmodifiable(_services);

  void add({
    required String title,
    required int price,
    required String category,
    required String description,
    required List<String> deliverables,
    required SellerServiceStatus status,
    String? coverName,
    Uint8List? coverBytes,
    required String packageName,
    required int deliveryDays,
    required int revisions,
  }) {
    _services.insert(
      0,
      SellerService(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        price: price,
        category: category,
        description: description,
        deliverables: List.unmodifiable(deliverables),
        status: status,
        coverName: coverName,
        coverBytes: coverBytes,
        packageName: packageName,
        deliveryDays: deliveryDays,
        revisions: revisions,
      ),
    );
    notifyListeners();
  }

  void update(SellerService updatedService) {
    final index =
        _services.indexWhere((service) => service.id == updatedService.id);
    if (index == -1) {
      throw StateError('Jasa yang akan diperbarui tidak ditemukan.');
    }
    _services[index] = updatedService;
    notifyListeners();
  }

  void setStatus(String id, SellerServiceStatus status) {
    final index = _services.indexWhere((service) => service.id == id);
    if (index == -1) {
      throw StateError('Jasa yang akan diperbarui tidak ditemukan.');
    }
    _services[index] = _services[index].copyWith(status: status);
    notifyListeners();
  }

  void delete(String id) {
    final index = _services.indexWhere((service) => service.id == id);
    if (index == -1) {
      throw StateError('Jasa yang akan dihapus tidak ditemukan.');
    }
    _services.removeAt(index);
    notifyListeners();
  }
}
