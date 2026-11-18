import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api_config.dart';
import 'order_service.dart';

class ServiceReviewItem {
  const ServiceReviewItem({
    required this.id,
    required this.orderId,
    required this.serviceId,
    required this.buyerName,
    required this.buyerDepartment,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final int id;
  final int orderId;
  final int serviceId;
  final String buyerName;
  final String buyerDepartment;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory ServiceReviewItem.fromJson(Map<String, dynamic> json) {
    return ServiceReviewItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      serviceId: int.tryParse(json['service_id']?.toString() ?? '0') ?? 0,
      buyerName: json['buyer_name']?.toString() ?? 'Pembeli',
      buyerDepartment: json['buyer_department']?.toString() ?? 'Mahasiswa',
      rating: int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ReviewService {
  static Future<Map<String, dynamic>> submitReview({
    required int orderId,
    required int serviceId,
    int? sellerId,
    required int rating,
    required String comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buyerId = await OrderService.getLoggedInUserId();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiConfig.baseUrl}/reviews');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'service_id': serviceId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': decoded['data']};
      }
      return {
        'success': false,
        'message': decoded['message'] ?? 'Gagal mengirim ulasan',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<ServiceReviewItem>> getServiceReviews(
    String serviceId,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/reviews/service/$serviceId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rows = decoded['data'] ?? [];
        return rows
            .map(
              (e) =>
                  ServiceReviewItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }
}