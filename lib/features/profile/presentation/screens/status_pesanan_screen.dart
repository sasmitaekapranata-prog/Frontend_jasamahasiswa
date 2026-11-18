import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/services/order_service.dart';
import '../../../auth/services/review_service.dart';
import '../../../dashboard/presentation/order_payment.dart';

class StatusPesananScreen extends StatefulWidget {
  const StatusPesananScreen({super.key});

  @override
  State<StatusPesananScreen> createState() => _StatusPesananScreenState();
}

class _StatusPesananScreenState extends State<StatusPesananScreen> {
  static const _tabs = ['Berjalan', 'Selesai', 'Dibatalkan'];
  int _selectedTab = 0;
  final _orderStore = BuyerOrderStore.instance;

  List<OrderPayment> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderStore.markBuyerNotificationsRead();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await OrderService.getBuyerOrders();
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

  Future<void> _updateStatus(
    OrderPayment order,
    String newStatus,
    String successMsg,
  ) async {
    if (order.dbId == null) return;
    final ok = await OrderService.updateOrderStatus(
      orderId: order.dbId!,
      status: newStatus,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status pesanan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final visibleOrders = switch (_selectedTab) {
      0 => orders
          .where(
            (order) =>
                order.progress != OrderProgress.completed &&
                order.progress != OrderProgress.cancelled,
          )
          .toList(),
      1 => orders
          .where((order) => order.progress == OrderProgress.completed)
          .toList(),
      _ => orders
          .where((order) => order.progress == OrderProgress.cancelled)
          .toList(),
    };

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final selected = index == _selectedTab;
                final count = switch (index) {
                  0 => orders
                      .where(
                        (order) =>
                            order.progress != OrderProgress.completed &&
                            order.progress != OrderProgress.cancelled,
                      )
                      .length,
                  1 => orders
                      .where(
                        (order) => order.progress == OrderProgress.completed,
                      )
                      .length,
                  _ => orders
                      .where(
                        (order) => order.progress == OrderProgress.cancelled,
                      )
                      .length,
                };
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _tabs.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color:
                                selected ? AppColors.primary : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_tabs[index]} ($count)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 44,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _selectedTab == 0
                                    ? 'Belum ada pesanan berjalan.'
                                    : 'Belum ada pesanan ${_tabs[_selectedTab].toLowerCase()}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (_selectedTab == 0) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => context.go(Routes.beranda),
                                  child: const Text('Cari Jasa'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                          itemCount: visibleOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = visibleOrders[index];
                            return _OrderCard(
                              order: order,
                              onDetails: () => _showOrderDetails(context, order),
                              onChat: () => context.push(
                                '${Routes.chatDetail}/${Uri.encodeComponent(order.transactionId ?? order.service.id)}',
                                extra: order,
                              ),
                              onCancel: order.progress ==
                                      OrderProgress.waitingSeller
                                  ? () => _updateStatus(
                                        order,
                                        'dibatalkan',
                                        'Pesanan dibatalkan.',
                                      )
                                  : null,
                              onRequestRevision: order.progress ==
                                      OrderProgress.revision
                                  ? () => _updateStatus(
                                        order,
                                        'revisi',
                                        'Permintaan revisi dikirim ke penjual.',
                                      )
                                  : null,
                              onReview: order.progress == OrderProgress.completed && !order.hasReview ? () => _openReviewSheet(order) : null,
                              onComplete: order.progress == OrderProgress.revision
                                  ? () => _updateStatus(
                                        order,
                                        'selesai',
                                        'Pesanan selesai. Terima kasih!',
                                      )
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

    void _openReviewSheet(OrderPayment order) {
    if (order.dbId == null) return;
    int selectedRating = 5;
    final commentController = TextEditingController();
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
                  const Text(
                    'Beri Ulasan & Rating Jasa',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.service.title} - ${order.service.seller}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (idx) {
                        final starVal = idx + 1;
                        return IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => setModalState(() => selectedRating = starVal),
                          icon: Icon(
                            starVal <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFF59E0B),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                  ),
                  Center(
                    child: Text(
                      switch (selectedRating) {
                        5 => 'Sangat Memuaskan (5/5)',
                        4 => 'Memuaskan (4/5)',
                        3 => 'Cukup Baik (3/5)',
                        2 => 'Kurang Memuaskan (2/5)',
                        _ => 'Sangat Kurang (1/5)',
                      },
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Ceritakan pengalamanmu menggunakan jasa ini (opsional)...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final res = await ReviewService.submitReview(
                                orderId: order.dbId!,
                                serviceId:
                                    int.tryParse(order.service.id) ?? 0,
                                sellerId: order.sellerId,
                                rating: selectedRating,
                                comment: commentController.text.trim(),
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              if (!mounted) return;
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Terima kasih! Ulasan kamu berhasil dikirim.',
                                    ),
                                  ),
                                );
                                _loadOrders();
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message']?.toString() ??
                                          'Gagal mengirim ulasan.',
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
                              'Kirim Ulasan',
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

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  void _showOrderDetails(BuildContext context, OrderPayment order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pesanan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow('Jasa', order.service.title),
              _DetailRow('Penjual', order.service.seller),
              _DetailRow('Brief', order.brief),
              if (order.resultNote != null && order.resultNote!.isNotEmpty)
                _DetailRow('Catatan Hasil', order.resultNote!),
              if (order.resultFileUrl != null) ...[
                const SizedBox(height: 4),
                const Text(
                  'File Hasil Pekerjaan:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (_isImageUrl(order.resultFileUrl!))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        order.resultFileUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: order.resultFileUrl!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Link file hasil disalin! Tempel di browser untuk mengunduh.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text(
                    'Salin Link Unduhan File Hasil',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _DetailRow('Metode pembayaran', order.paymentMethod),
              _DetailRow('Total', Formatters.currency(order.total)),
              _DetailRow('Status', order.progress.label),
              _DetailRow('Progres', '${order.progress.percentage}%'),
              _DetailRow('ID Transaksi', '#${order.transactionId ?? '-'}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onDetails,
    required this.onChat,
    this.onCancel,
    this.onRequestRevision,
    this.onComplete,
    this.onReview,
  });

  final VoidCallback? onReview;

  final OrderPayment order;
  final VoidCallback onDetails;
  final VoidCallback onChat;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestRevision;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final paidAt = order.paidAt;
    final hasResult =
        (order.resultNote != null && order.resultNote!.isNotEmpty) ||
            order.resultFileUrl != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.transactionId ?? '-'} - ${paidAt == null ? '' : Formatters.shortDate(paidAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.progress.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: order.service.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  order.service.icon,
                  color: order.service.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Penjual: ${order.service.seller}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '${Formatters.currency(order.total)} (${order.paymentMethod})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.progress.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${order.progress.percentage}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: order.progress.fraction,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              color: order.progress == OrderProgress.completed
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
          if (hasResult) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasil dari Penjual:',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order.resultNote != null && order.resultNote!.isNotEmpty)
                    Text(
                      order.resultNote!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                      ),
                    ),
                  if (order.resultFileUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: order.resultFileUrl!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Link file hasil disalin! Tempel di browser untuk mengunduh.',
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Salin Link File Hasil Pekerjaan',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(34),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Batalkan Pesanan',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
          if (onRequestRevision != null && onComplete != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequestRevision,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(34),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Minta Revisi',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(34),
                      backgroundColor: AppColors.success,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Konfirmasi Selesai',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
                    if (order.progress == OrderProgress.completed) ...[
            const SizedBox(height: 8),
            if (order.hasReview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Kamu memberi rating ${order.reviewRating ?? 5}/5 untuk pesanan ini',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (onReview != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(
                    Icons.star_outline,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  label: const Text(
                    'Beri Ulasan & Rating',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    minimumSize: const Size.fromHeight(34),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(68, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Detail', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 7),
              ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 13),
                label: const Text('Chat', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(70, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
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
        ],
      ),
    );
  }
}