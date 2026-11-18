import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/services/order_service.dart';
import '../../../dashboard/presentation/order_payment.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  static const _tabs = ['Baru', 'Dikerjakan', 'Revisi', 'Selesai'];
  int _selectedTab = 0;

  final _orderStore = BuyerOrderStore.instance;
  List<OrderPayment> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderStore.markSellerNotificationsRead();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await OrderService.getSellerOrders();
      if (!mounted) return;
      setState(() {
        _orders = fetched;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = _orderStore.orders;
        _isLoading = false;
      });
    }
  }

  List<OrderPayment> _ordersForTab(int tabIndex) {
    return switch (tabIndex) {
      0 => _orders
          .where((o) => o.rawStatus == 'menunggu_konfirmasi')
          .toList(),
      1 => _orders
          .where(
            (o) =>
                o.rawStatus == 'diproses' ||
                o.rawStatus == 'menunggu_review',
          )
          .toList(),
      2 => _orders.where((o) => o.rawStatus == 'revisi').toList(),
      _ => _orders.where((o) => o.rawStatus == 'selesai').toList(),
    };
  }

  Future<void> _acceptOrder(OrderPayment order) async {
    if (order.dbId == null) return;
    final ok = await OrderService.updateOrderStatus(
      orderId: order.dbId!,
      status: 'diproses',
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan diterima dan masuk ke tab Dikerjakan.'),
        ),
      );
      setState(() => _selectedTab = 1);
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menerima pesanan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _openDeliverSheet(OrderPayment order, {bool isRevision = false}) {
    if (order.dbId == null) return;
    final noteController = TextEditingController(text: order.resultNote ?? '');
    Uint8List? pickedBytes;
    String? pickedFileName;
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRevision
                        ? 'Kirim Revisi Hasil Pekerjaan'
                        : 'Kirim Hasil Pekerjaan',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${order.transactionId ?? '-'} - ${order.service.title}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'CATATAN / LINK HASIL KERJA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Tulis catatan pengiriman atau tempel link Google Drive / GitHub...',
                      contentPadding: EdgeInsets.all(11),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: const [
                                'zip',
                                'pdf',
                                'doc',
                                'docx',
                                'jpg',
                                'jpeg',
                                'png',
                                'webp',
                              ],
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              if (file.bytes != null) {
                                setModalState(() {
                                  pickedBytes = file.bytes;
                                  pickedFileName = file.name;
                                });
                              }
                            }
                          },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      pickedFileName ??
                          'Lampirkan File Hasil (ZIP, PDF, DOCX, Gambar)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final note = noteController.text.trim();
                              if (note.isEmpty && pickedBytes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Isi catatan/link atau pilih file hasil terlebih dahulu.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              final res = await OrderService.deliverOrder(
                                orderId: order.dbId!,
                                resultNote: note,
                                fileBytes: pickedBytes,
                                fileName: pickedFileName,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              if (!mounted) return;
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Hasil pekerjaan berhasil dikirim ke pembeli!',
                                    ),
                                  ),
                                );
                                _loadOrders();
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal mengirim: ${res['message'] ?? 'Error server'}',
                                    ),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Kirim ke Pembeli',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _ordersForTab(_selectedTab);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Pesanan Masuk',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final selected = index == _selectedTab;
                final count = _ordersForTab(index).length;
                final label = count > 0
                    ? '${_tabs[index]} ($count)'
                    : _tabs[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _tabs.length - 1 ? 0 : 6,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 9,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleOrders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'Belum ada pesanan di tab ${_tabs[_selectedTab]}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                          itemCount: visibleOrders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = visibleOrders[index];
                            return _FigmaIncomingOrderCard(
                              order: order,
                              onChat: () => context.push(
                                '${Routes.chatDetail}/${Uri.encodeComponent(order.transactionId ?? order.service.id)}',
                                extra: order,
                              ),
                              onAccept: order.rawStatus == 'menunggu_konfirmasi'
                                  ? () => _acceptOrder(order)
                                  : null,
                              onDeliver: (order.rawStatus == 'diproses' ||
                                      order.rawStatus == 'menunggu_review')
                                  ? () => _openDeliverSheet(order)
                                  : null,
                              onDeliverRevision: order.rawStatus == 'revisi'
                                  ? () => _openDeliverSheet(
                                        order,
                                        isRevision: true,
                                      )
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pastikan mengirim hasil pekerjaan sebelum deadline agar dana dapat otomatis dicairkan ke saldo kamu.',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaIncomingOrderCard extends StatelessWidget {
  const _FigmaIncomingOrderCard({
    required this.order,
    required this.onChat,
    this.onAccept,
    this.onDeliver,
    this.onDeliverRevision,
  });

  final OrderPayment order;
  final VoidCallback onChat;
  final VoidCallback? onAccept;
  final VoidCallback? onDeliver;
  final VoidCallback? onDeliverRevision;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'PB';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = order.rawStatus == 'menunggu_konfirmasi';
    final isWorking = order.rawStatus == 'diproses' ||
        order.rawStatus == 'menunggu_review';
    final isRevision = order.rawStatus == 'revisi';
    final isCompleted = order.rawStatus == 'selesai';

    final (badgeText, badgeBg, badgeColor) = switch (order.rawStatus) {
      'menunggu_konfirmasi' => (
          'Butuh Konfirmasi',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
      'menunggu_review' => (
          'Menunggu Review Pembeli',
          const Color(0xFFEFF6FF),
          AppColors.primary,
        ),
      'revisi' => (
          'Revisi',
          const Color(0xFFEFF6FF),
          AppColors.primary,
        ),
      'selesai' => (
          'Selesai Dikerjakan',
          const Color(0xFFEFF6FF),
          AppColors.primary,
        ),
      _ => (
          'Sedang Dikerjakan',
          const Color(0xFFEFF6FF),
          AppColors.primary,
        ),
    };

    final double progressValue = switch (order.rawStatus) {
      'menunggu_konfirmasi' => 0.15,
      'diproses' => 0.65,
      'menunggu_review' => 0.85,
      'revisi' => 0.75,
      'selesai' => 1.0,
      _ => 0.0,
    };

    final dateLabel = order.paidAt != null
        ? Formatters.shortDate(order.paidAt!)
        : 'Hari ini';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isNew ? AppColors.primary : AppColors.border,
          width: isNew ? 1.3 : 1.0,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.transactionId ?? '-'} - $dateLabel',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: isNew
                    ? const Color(0xFFDCEAFF)
                    : const Color(0xFFFEF3C7),
                child: Text(
                  _initials(order.buyerName),
                  style: TextStyle(
                    color: isNew
                        ? AppColors.primary
                        : const Color(0xFFD97706),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: order.buyerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        children: const [
                          TextSpan(
                            text: ' (Pembeli)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isNew
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isNew) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brief: ${order.brief}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pendapatan: ${Formatters.currency(order.total)} (Sudah dibayar via ${order.paymentMethod})',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onChat,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'Chat Pembeli',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'Terima Pesanan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Brief: ${order.brief}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            if (isCompleted)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: FilledButton(
                      onPressed: onChat,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: FilledButton.icon(
                      onPressed: isRevision ? onDeliverRevision : onDeliver,
                      icon: isWorking
                          ? const Icon(Icons.arrow_upward, size: 16)
                          : const SizedBox.shrink(),
                      label: Text(
                        isRevision
                            ? 'Revisi Hasil Pekerjaan'
                            : (order.rawStatus == 'menunggu_review'
                                ? 'Kirim Ulang Hasil'
                                : 'Kirim Hasil Pekerjaan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}