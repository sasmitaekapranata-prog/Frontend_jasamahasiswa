import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/api_config.dart';
import '../../profile/controllers/seller_profile_store.dart';
import '../../profile/controllers/seller_wallet_store.dart';

class AuthService {
  Future<String?> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama': nama.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['token'] != null) {
        await _saveSession(data);
        return null; // null artinya sukses tanpa pesan error
      }
      return data['message']?.toString() ?? 'Registrasi gagal. Coba lagi.';
    } catch (e) {
      debugPrint('Error saat register: $e');
      return 'Terjadi kesalahan koneksi ke server.';
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _saveSession(data);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error saat login: $e');
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SellerProfileStore.instance.reset();
    SellerWalletStore.instance.clearSession();

    await prefs.setString('token', data['token'].toString());

    if (data['user'] != null) {
      final encodedUser = jsonEncode(data['user']);
      await prefs.setString('user_data', encodedUser);
      await prefs.setString('user', encodedUser);
      final rawId = data['user']['id'];
      final parsedId = int.tryParse(rawId?.toString() ?? '');
      if (parsedId != null && parsedId > 0) {
        await prefs.setInt('user_id', parsedId);
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SellerProfileStore.instance.reset();
    SellerWalletStore.instance.clearSession();
  }
}