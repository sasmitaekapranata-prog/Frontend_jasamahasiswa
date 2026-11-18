import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/api_config.dart';
import '../../dashboard/presentation/order_payment.dart';
import '../../dashboard/presentation/service_catalog.dart';

class OrderService {
  static Future<int> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final directInt = prefs.getInt('user_id');
    if (directInt != null) return directInt;

    final directStr = prefs.getString('user_id');
    if (directStr != null && int.tryParse(directStr) != null) {
      return int.parse(directStr);
    }

    final userJsonStr = prefs.getString('user');
    if (userJsonStr != null) {
      try {
        final userMap = jsonDecode(userJsonStr);
        if (userMap is Map && userMap['id'] != null) {
          return int.tryParse(userMap['id'].toString()) ?? 1;
        }
      } catch (_) {}
    }
    return 1;
  }

  static Future<Map<String, dynamic>> createOrder({
    required String serviceId,
    required int totalHarga,
    String catatan = '',
    String metodePembayaran = 'QRIS / Transfer',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final buyerId = await getLoggedInUserId();
    final token = prefs.getString('token');

    final url = Uri.parse('${ApiConfig.baseUrl}/orders');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'service_id': int.tryParse(serviceId) ?? 1,
        'buyer_id': buyerId,
        'catatan': catatan,
        'total_harga': totalHarga,
        'metode_pembayaran': metodePembayaran,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return {'success': true, 'data': body['data']};
    }
    return {
      'success': false,
      'message': body['message'] ?? 'Gagal membuat pesanan',
    };
  }

  static Future<List<OrderPayment>> getBuyerOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final buyerId = await getLoggedInUserId();
    final token = prefs.getString('token');

    final url = Uri.parse('${ApiConfig.baseUrl}/orders/buyer/$buyerId');
    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded['data'] ?? [];
      return rows
          .map((item) => fromBackendJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  static Future<List<OrderPayment>> getSellerOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = await getLoggedInUserId();
    final token = prefs.getString('token');

    final url = Uri.parse('${ApiConfig.baseUrl}/orders/seller/$sellerId');
    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded['data'] ?? [];
      return rows
          .map((item) => fromBackendJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  static Future<bool> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> deliverOrder({
    required int orderId,
    required String resultNote,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String? base64Payload;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        base64Payload =
            'data:application/octet-stream;base64,${base64Encode(fileBytes)}';
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/deliver');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'result_note': resultNote,
          'result_file_base64': base64Payload,
          'result_file_name': fileName,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      String msg = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = '${decoded['message']} (${response.statusCode})';
        }
      } catch (_) {}
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static OrderProgress _mapStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'diproses':
      case 'revisi':
        return OrderProgress.inProgress;
      case 'menunggu_review':
        return OrderProgress.revision;
      case 'selesai':
        return OrderProgress.completed;
      case 'dibatalkan':
        return OrderProgress.cancelled;
      case 'menunggu_konfirmasi':
      default:
        return OrderProgress.waitingSeller;
    }
  }

  static String? _resolveFullFileUrl(dynamic rawPath) {
    final pathStr = rawPath?.toString().trim();
    if (pathStr == null || pathStr.isEmpty) return null;
    if (pathStr.startsWith('http')) return pathStr;
    final serverRoot = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$serverRoot$pathStr';
  }

  static OrderPayment fromBackendJson(Map<String, dynamic> json) {
    final totalHarga =
        double.tryParse(json['total_harga']?.toString() ?? '0')?.round() ?? 0;
    final rawStatus =
        (json['status']?.toString() ?? 'menunggu_konfirmasi').toLowerCase();

    final service = ServiceInfo(
      id: json['service_id']?.toString() ?? '0',
      title: json['judul_jasa']?.toString() ?? 'Layanan Jasa',
      seller: json['nama_penjual']?.toString() ?? 'Penjual',
      department: json['jurusan_pembeli']?.toString() ?? 'Mahasiswa',
      rating: '5.0',
      reviews: 0,
      salesCount: 0,
      price: totalHarga,
      category: 'Jasa',
      color: const Color(0xFFDCEAFF),
      iconColor: AppColors.primary,
      icon: Icons.work_outline,
      description: '',
      includes: const [],
    );

    return OrderPayment(
      dbId: int.tryParse(json['id']?.toString() ?? ''),
      buyerId: int.tryParse(json['buyer_id']?.toString() ?? ''),
      sellerId: int.tryParse(json['seller_id']?.toString() ?? ''),
      rawStatus: rawStatus,
      resultNote: json['result_note']?.toString(),
      resultFileUrl: _resolveFullFileUrl(json['result_file_url']),
      service: service,
      brief: json['catatan']?.toString() ?? '-',
      paymentMethod: json['metode_pembayaran']?.toString() ?? 'QRIS',
      total: totalHarga,
      buyerName: json['nama_pembeli']?.toString() ?? 'Pembeli',
      transactionId: json['order_code']?.toString() ?? 'ORD-${json['id']}',
      paidAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      progress: _mapStatus(rawStatus),
      hasReview: (int.tryParse(json['has_review']?.toString() ?? '0') ?? 0) > 0,
      reviewRating: int.tryParse(json['review_rating']?.toString() ?? ''),
    );
  }
}