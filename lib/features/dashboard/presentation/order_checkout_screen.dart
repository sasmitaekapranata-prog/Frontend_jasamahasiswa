import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import 'service_catalog.dart';
import 'order_payment.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key, this.service});

  final ServiceInfo? service;

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _briefController = TextEditingController();
  static const _maxAttachmentBytes = 25 * 1024 * 1024;
  static const _attachmentExtensions = [
    'pdf',
    'doc',
    'docx',
    'zip',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  final List<OrderAttachment> _attachments = [];
  String _paymentMethod = 'QRIS';
  bool _isPickingAttachments = false;
  static const _serviceFee = 5000;

  @override
  void dispose() {
    _briefController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    if (_isPickingAttachments) return;
    setState(() => _isPickingAttachments = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _attachmentExtensions,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || !mounted) return;

      final selected = <OrderAttachment>[];
      for (final file in result.files) {
        final extension = file.extension?.toLowerCase();
        if (extension == null || !_attachmentExtensions.contains(extension)) {
          _showMessage('Format file ${file.name} belum didukung.');
          continue;
        }
        if (file.size > _maxAttachmentBytes) {
          _showMessage('${file.name} melebihi batas ukuran 25 MB.');
          continue;
        }
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          _showMessage('File ${file.name} tidak dapat dibaca. Silakan pilih ulang.');
          continue;
        }
        selected.add(
          OrderAttachment(name: file.name, bytes: bytes, size: file.size),
        );
      }

      if (selected.isNotEmpty && mounted) {
        setState(() {
          for (final attachment in selected) {
            if (!_attachments.any((item) => item.name == attachment.name)) {
              _attachments.add(attachment);
            }
          }
        });
      }
    } on Exception catch (error) {
      if (mounted) _showMessage('Gagal memilih file: $error');
    } finally {
      if (mounted) setState(() => _isPickingAttachments = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: Routes.beranda),
          title: const Text('Checkout Jasa'),
        ),
        body: const Center(child: Text('Data jasa tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.beranda),
        title: const Text(
          'Checkout Jasa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ServiceSummary(service: service),
            const SizedBox(height: 12),
            const _FieldLabel('BRIEF KEBUTUHAN / CATATAN', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _briefController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Isi detail kebutuhan/brief tugas kamu di sini...',
                contentPadding: EdgeInsets.all(11),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Brief kebutuhan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isPickingAttachments ? null : _pickAttachments,
              icon: _isPickingAttachments
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 20),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isPickingAttachments
                        ? 'Membuka file...'
                        : 'Unggah File / Foto',
                  ),
                  const Text(
                    'PDF, DOCX, ZIP, JPG, PNG • Maksimal 25 MB per file',
                    style:
                        TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(
                  color: Color(0xFFD8E2F0),
                  style: BorderStyle.solid,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (var index = 0; index < _attachments.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _AttachmentTile(
                    attachment: _attachments[index],
                    sizeLabel: _formatFileSize(_attachments[index].size),
                    onRemove: () => setState(() => _attachments.removeAt(index)),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            const _FieldLabel('METODE PEMBAYARAN'),
            const SizedBox(height: 7),
            _PaymentMethodCard(
              value: 'QRIS',
              groupValue: _paymentMethod,
              badge: 'Instant Pay',
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            _PaymentMethodCard(
              value: 'E-Wallet',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 14),
            _CostSummary(
              servicePrice: service.price,
              serviceFee: _serviceFee,
            ),
          ],
        ),
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
            child: ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.push(
                  Routes.qrisPayment,
                  extra: OrderPayment(
                    service: service,
                    brief: _briefController.text.trim(),
                    paymentMethod: _paymentMethod,
                    total: service.price + _serviceFee,
                    attachments: List.unmodifiable(_attachments),
                  ),
                );
              },
              child: const Text(
                'Bayar Sekarang',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service});

  final ServiceInfo service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(service.icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${service.seller} • ${service.department}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  service.formattedPrice,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.sizeLabel,
    required this.onRemove,
  });

  final OrderAttachment attachment;
  final String sizeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          if (attachment.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                attachment.bytes,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            )
          else
            const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sizeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Hapus ${attachment.name}',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 17),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.badge,
  });

  final String value;
  final String groupValue;
  final String? badge;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: groupValue == value
                      ? AppColors.primary
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: groupValue == value
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CostSummary extends StatelessWidget {
  const _CostSummary({required this.servicePrice, required this.serviceFee});

  final int servicePrice;
  final int serviceFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('RINCIAN BIAYA'),
          const SizedBox(height: 8),
          _PriceRow('Harga Jasa Utama', servicePrice),
          const SizedBox(height: 5),
          _PriceRow('Biaya Layanan', serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                Formatters.currency(servicePrice + serviceFee),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount);

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          Formatters.currency(amount),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
