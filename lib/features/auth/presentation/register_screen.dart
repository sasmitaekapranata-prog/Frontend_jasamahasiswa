import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../services/auth_service.dart';
import 'auth_form_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _isLoading) return;

    setState(() => _isLoading = true);

    final authService = AuthService();
    final errorMessage = await authService.register(
      nama: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Selamat datang.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(Routes.beranda);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Registrasi',
      isRegister: true,
      formKey: _formKey,
      footerText: 'Sudah punya akun?',
      footerAction: 'Login Sekarang',
      footerRoute: Routes.login,
      formFields: [
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: authInputDecoration('Nama Lengkap'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama lengkap wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
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
            if (value.length < 8) {
              return 'Password minimal 8 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: authInputDecoration('Konfirmasi Password').copyWith(
            suffixIcon: IconButton(
              tooltip: _isConfirmPasswordVisible
                  ? 'Sembunyikan password'
                  : 'Tampilkan password',
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Konfirmasi password wajib diisi';
            }
            if (value != _passwordController.text) {
              return 'Password tidak sama';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: authPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Daftar'),
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