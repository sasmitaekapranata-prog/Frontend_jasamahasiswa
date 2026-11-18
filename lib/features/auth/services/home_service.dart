import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_config.dart'; // Sesuaikan path ini jika error

// 1. Model untuk menampung data dari Backend
class ServiceItem {
  final int id;
  final String judul;
  final String harga;
  final double rating;
  final int reviewCount;
  final String namaPenjual;
  final String? jurusanPenjual;

  ServiceItem({
    required this.id,
    required this.judul,
    required this.harga,
    required this.rating,
    required this.reviewCount,
    required this.namaPenjual,
    this.jurusanPenjual,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      // Konversi harga dan rating menjadi string/double yang aman
      harga: json['harga'] != null ? json['harga'].toString() : '0',
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : 0.0,
      reviewCount: json['review_count'] ?? 0,
      namaPenjual: json['nama_penjual'] ?? 'Anonim',
      jurusanPenjual: json['jurusan_penjual'],
    );
  }
}

// 2. Service untuk menembak API Backend
class HomeService {
  Future<List<ServiceItem>> getServices() async {
    // Karena ApiConfig.baseUrl Anda adalah 'http://localhost:3000/api'
    final url = Uri.parse('${ApiConfig.baseUrl}/services');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> servicesJson = data['data']; // Mengambil array dari bungkus 'data'
        
        // Mengubah array JSON menjadi List<ServiceItem>
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