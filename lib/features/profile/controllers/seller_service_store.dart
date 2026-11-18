import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_config.dart';
import '../../auth/services/order_service.dart';

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
    this.sellerName = '',
    this.sellerDepartment = '',
    this.coverName,
    this.coverBytes,
    this.bannerUrl = '',
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
  final String sellerName;
  final String sellerDepartment;
  final String? coverName;
  final Uint8List? coverBytes;
  final String bannerUrl;
  final String packageName;
  final int deliveryDays;
  final int revisions;
  final int salesCount;
  final String rating;

  static SellerServiceStatus _parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'aktif':
      case 'active':
        return SellerServiceStatus.active;
      case 'nonaktif':
      case 'inactive':
        return SellerServiceStatus.inactive;
      case 'draft':
        return SellerServiceStatus.draft;
      case 'ditinjau':
      case 'under_review':
      case 'underreview':
        return SellerServiceStatus.underReview;
      default:
        return SellerServiceStatus.active;
    }
  }

  static String toBackendStatus(SellerServiceStatus status) {
    switch (status) {
      case SellerServiceStatus.active:
        return 'aktif';
      case SellerServiceStatus.inactive:
        return 'nonaktif';
      case SellerServiceStatus.draft:
        return 'draft';
      case SellerServiceStatus.underReview:
        return 'ditinjau';
    }
  }

  factory SellerService.fromJson(Map<String, dynamic> json) {
    final rawDesc = (json['deskripsi'] ?? '').toString();
    String baseDesc = rawDesc;
    List<String> deliverables = [];
    const marker = '\n\nYang termasuk dalam paket:\n';
    if (rawDesc.contains(marker)) {
      final parts = rawDesc.split(marker);
      baseDesc = parts[0].trim();
      deliverables = parts[1]
          .split('\n')
          .map((line) => line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    final rawHarga = json['harga'];
    final parsedPrice = rawHarga is num
        ? rawHarga.toInt()
        : (double.tryParse(rawHarga?.toString() ?? '0')?.toInt() ?? 0);

    final rawRating = json['rating'];
    final ratingVal = rawRating != null
        ? (double.tryParse(rawRating.toString())?.toStringAsFixed(1) ?? '0.0')
        : '0.0';

    return SellerService(
      id: (json['id'] ?? '').toString(),
      title: (json['judul'] ?? '').toString(),
      price: parsedPrice,
      category: (json['nama_kategori'] ?? 'Coding').toString(),
      description: baseDesc,
      deliverables: deliverables,
      status: _parseStatus(json['status']?.toString()),
      sellerName: (json['nama_penjual'] ?? '').toString(),
      sellerDepartment: (json['jurusan_penjual'] ?? '').toString(),
      bannerUrl: (json['banner_url'] ?? '').toString(),
      packageName: (json['nama_paket'] ?? '').toString(),
      deliveryDays: int.tryParse(json['waktu_pengerjaan']?.toString() ?? '2') ?? 2,
      revisions: int.tryParse(json['jumlah_revisi']?.toString() ?? '2') ?? 2,
      salesCount: int.tryParse(json['sales_count']?.toString() ?? '0') ?? 0,
      rating: ratingVal,
    );
  }

  SellerService copyWith({
    String? title,
    int? price,
    String? category,
    String? description,
    List<String>? deliverables,
    SellerServiceStatus? status,
    String? sellerName,
    String? sellerDepartment,
    String? coverName,
    Uint8List? coverBytes,
    String? bannerUrl,
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
      sellerName: sellerName ?? this.sellerName,
      sellerDepartment: sellerDepartment ?? this.sellerDepartment,
      coverName: coverName ?? this.coverName,
      coverBytes: coverBytes ?? this.coverBytes,
      bannerUrl: bannerUrl ?? this.bannerUrl,
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

  final List<SellerService> _services = [];
  bool isLoading = false;
  String? errorMessage;

  List<SellerService> get services => List.unmodifiable(_services);

  Future<void> syncFromBackend() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sellerId = await OrderService.getLoggedInUserId();
      if (sellerId <= 0) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/services/seller/$sellerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = (decoded['data'] as List<dynamic>?) ?? [];
        _services
          ..clear()
          ..addAll(
            rawList.map(
              (item) => SellerService.fromJson(item as Map<String, dynamic>),
            ),
          );
      } else {
        errorMessage = 'Gagal memuat daftar jasa (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = 'Gagal terhubung ke server: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void add({
    required String title,
    required int price,
    required String category,
    required String description,
    required List<String> deliverables,
    required SellerServiceStatus status,
    String sellerName = '',
    String sellerDepartment = '',
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
        sellerName: sellerName,
        sellerDepartment: sellerDepartment,
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
    if (index != -1) {
      _services[index] = updatedService;
      notifyListeners();
    }
  }

  Future<bool> toggleStatusRemote(String id, SellerServiceStatus nextStatus) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/services/$id/status');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': SellerService.toBackendStatus(nextStatus)}),
      );
      if (response.statusCode == 200) {
        final index = _services.indexWhere((s) => s.id == id);
        if (index != -1) {
          _services[index] = _services[index].copyWith(status: nextStatus);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> deleteRemote(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/services/$id');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _services.removeWhere((s) => s.id == id);
        notifyListeners();
        return null;
      }
      final decoded = jsonDecode(response.body);
      return decoded['message']?.toString() ?? 'Gagal menghapus jasa.';
    } catch (e) {
      return 'Gagal terhubung ke server: $e';
    }
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