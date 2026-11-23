import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import 'auth_form_layout.dart';
// Pastikan path import AuthService ini disesuaikan dengan struktur folder Anda
import '../services/auth_service.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Ubah fungsi _submit menjadi async untuk memanggil API
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Ubah state menjadi loading
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final isSuccess = await authService.login(
      _emailController.text,
      _passwordController.text,
    );

    // Cek apakah widget masih aktif sebelum melakukan update UI
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        // Arahkan ke beranda jika login berhasil
        context.go(Routes.beranda);
      } else {
        // Tampilkan pesan error jika gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Gagal! Periksa kembali email dan password Anda.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Login',
      isRegister: false,
      formKey: _formKey,
      footerText: 'Belum punya akun?',
      footerAction: 'Daftar Sekarang',
      footerRoute: Routes.register,
      formFields: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: authInputDecoration('Masukkan Email'),
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _submit(),
          decoration: authInputDecoration('Masukkan Password').copyWith(
            suffixIcon: IconButton(
              tooltip: _isPasswordVisible
                  ? 'Sembunyikan password'
                  : 'Tampilkan password',
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password wajib diisi';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(Routes.forgotPassword),
            style: TextButton.styleFrom(
              foregroundColor: authPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Lupa password?'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: FilledButton(
            // Nonaktifkan tombol saat sedang loading agar tidak diklik dua kali
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: authPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(fontSize: 11),
            ),
            // Tampilkan animasi loading atau teks 'Login'
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Login'),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Masukkan alamat email yang valid';
    }
    return null;
  }
}