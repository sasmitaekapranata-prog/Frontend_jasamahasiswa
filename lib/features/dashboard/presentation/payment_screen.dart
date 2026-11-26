import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/services/order_service.dart';
import 'order_payment.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.payment});

  final OrderPayment? payment;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _maxProofBytes = 10 * 1024 * 1024;
  static const _proofExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const _sandboxPaymentAmount = 55000;
  static final _sandboxPaymentUri = Uri.parse(
    'https://app.sandbox.midtrans.com/payment-links/007b3635-35d1-44f3-b8e7-64e6f6b7ed6a-XxNmlzS3',
  );

  bool _isSubmitting = false;
  bool _isPickingProof = false;
  bool _isUploadingProof = false;
  bool _paymentOpened = false;
  bool _proofSubmitted = false;
  int? _orderId;
  PlatformFile? _proofFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final order = widget.payment;
      if (mounted && order != null) {
        _startOrOpenPayment(order);
      }
    });
  }

  Future<void> _startOrOpenPayment(OrderPayment order) async {
    if (_isSubmitting) return;

    if (order.total != _sandboxPaymentAmount) {
      _showMessage(
        'Payment Link Sandbox ini bernilai Rp55.000. Total pesanan harus sama.',
        isError: true,
      );
      return;
    }

    if (_orderId != null) {
      await _openPaymentLink();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await OrderService.createOrder(
        serviceId: order.service.id,
        totalHarga: order.total,
        catatan: order.brief,
        metodePembayaran: 'Midtrans',
      );

      if (!mounted) return;
      if (result['success'] != true) {
        _showMessage(
          result['message']?.toString() ?? 'Gagal membuat pesanan.',
          isError: true,
        );
        return;
      }

      final data = result['data'];
      if (data is! Map) {
        _showMessage(
          'Respons backend tidak berisi data pesanan yang valid.',
          isError: true,
        );
        return;
      }

      final orderId = int.tryParse(data['id']?.toString() ?? '');

      if (orderId == null || orderId <= 0) {
        _showMessage(
          'Backend harus mengembalikan ID pesanan pada data.id.',
          isError: true,
        );
        return;
      }
      setState(() => _orderId = orderId);

      await _openPaymentLink();
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal memulai pembayaran: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openPaymentLink() async {
    try {
      final opened = await launchUrl(
        _sandboxPaymentUri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        _showMessage('Browser tidak dapat membuka halaman Midtrans.',
            isError: true);
        return;
      }
      setState(() => _paymentOpened = true);
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal membuka halaman Midtrans: $error', isError: true);
      }
    }
  }

  Future<void> _pickPaymentProof() async {
    if (_isPickingProof) return;
    setState(() => _isPickingProof = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _proofExtensions,
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null) return;

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();
      if (extension == null || !_proofExtensions.contains(extension)) {
        _showMessage('Pilih bukti berupa JPG, PNG, atau WEBP.', isError: true);
        return;
      }
      if (file.size > _maxProofBytes) {
        _showMessage('Ukuran bukti maksimal 10 MB.', isError: true);
        return;
      }
      if (file.bytes == null || file.bytes!.isEmpty) {
        _showMessage('File bukti tidak dapat dibaca. Silakan pilih ulang.',
            isError: true);
        return;
      }
      setState(() => _proofFile = file);
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Gagal memilih bukti pembayaran: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPickingProof = false);
    }
  }

  Future<void> _uploadPaymentProof() async {
    final orderId = _orderId;
    final proofFile = _proofFile;
    final proofBytes = proofFile?.bytes;
    if (_isUploadingProof ||
        orderId == null ||
        proofFile == null ||
        proofBytes == null) {
      return;
    }

    setState(() => _isUploadingProof = true);
    try {
      final result = await OrderService.uploadPaymentProof(
        orderId: orderId,
        proofBytes: proofBytes,
        proofName: proofFile.name,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _proofSubmitted = true);
        return;
      }
      _showMessage(
        result['message']?.toString() ?? 'Gagal mengirim bukti pembayaran.',
        isError: true,
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal mengirim bukti pembayaran: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingProof = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.payment;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text('Pembayaran E-Wallet'),
        ),
        body: const Center(child: Text('Data pembayaran tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.beranda),
        title: const Text(
          'Pembayaran E-Wallet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(
            icon: Icons.open_in_browser,
            text: order.total == _sandboxPaymentAmount
                ? 'Link Sandbox ini bernilai tetap Rp55.000 dan tidak terhubung otomatis ke order backend. Admin perlu memeriksa bukti secara manual.'
                : 'Payment Link Sandbox hanya menerima nominal Rp55.000.',
            isError: order.total != _sandboxPaymentAmount,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RINGKASAN PESANAN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.service.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.brief,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Divider(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total pembayaran',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      Formatters.currency(order.total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StepCard(
            number: '1',
            title: 'Bayar di browser Midtrans',
            subtitle: 'Gunakan metode pembayaran yang tersedia pada link ini.',
            isComplete: _paymentOpened,
          ),
          const SizedBox(height: 8),
          _StepCard(
            number: '2',
            title: 'Kembali ke aplikasi dan unggah bukti',
            subtitle: 'Admin akan memeriksa bukti pembayaran yang dikirim.',
            isComplete: _proofSubmitted,
          ),
          if (_orderId != null) ...[
            const SizedBox(height: 10),
            Text(
              'ID pesanan: $_orderId',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          if (_paymentOpened && !_proofSubmitted) ...[
            const SizedBox(height: 16),
            _buildProofUpload(),
          ],
          if (_proofSubmitted) ...[
            const SizedBox(height: 16),
            const _InfoBanner(
              icon: Icons.hourglass_top,
              text:
                  'Bukti berhasil dikirim. Status pembayaran menunggu verifikasi admin.',
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proofSubmitted
                  ? () => context.go(Routes.beranda)
                  : _isSubmitting
                      ? null
                      : () => _startOrOpenPayment(order),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _proofSubmitted
                          ? 'Kembali ke Beranda'
                          : _orderId == null
                              ? 'Lanjut ke Pembayaran Midtrans'
                              : 'Buka Kembali Midtrans',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProofUpload() {
    final proofBytes = _proofFile?.bytes;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UNGGAH BUKTI PEMBAYARAN',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ambil screenshot bukti dari halaman/aplikasi pembayaran, lalu kirim untuk diperiksa admin.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (proofBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                proofBytes,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Preview gambar tidak tersedia.')),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _isPickingProof ? null : _pickPaymentProof,
              icon: _isPickingProof
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                _isPickingProof ? 'Memilih file...' : 'Pilih Screenshot',
              ),
            ),
          if (_proofFile != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_proofFile!.name} • Maksimal 10 MB',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isUploadingProof ? null : _pickPaymentProof,
              child: const Text('Ganti Screenshot'),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isUploadingProof ? null : _uploadPaymentProof,
                child: _isUploadingProof
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Bukti ke Admin'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background =
        isError ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final foreground = isError ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: isError ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor:
                isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFEEF5FF),
            child: isComplete
                ? const Icon(Icons.check, color: AppColors.success, size: 18)
                : Text(
                    number,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
