import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/api_config.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    // URL diubah menjadi /auth/login sesuai dengan app.ts di backend
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['token'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          
          // 1. Simpan Token
          await prefs.setString('token', data['token']);
          
          // 2. Simpan Data User (diubah menjadi string JSON agar bisa disimpan)
          if (data['user'] != null) {
            await prefs.setString('user_data', jsonEncode(data['user']));
          }
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error saat login: $e');
      return false;
    }
  }
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Menghapus token dan data user dari memori HP
    await prefs.remove('token');
    await prefs.remove('user_data');
  }
}