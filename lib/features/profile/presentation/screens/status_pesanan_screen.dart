import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/utils/formatters.dart';
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

  @override
  void initState() {
    super.initState();
    _orderStore.markBuyerNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: AnimatedBuilder(
        animation: _orderStore,
        builder: (context, _) {
          final orders = _orderStore.orders;
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

          return Column(
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
                            (order) =>
                                order.progress == OrderProgress.completed,
                          )
                          .length,
                      _ => orders
                          .where(
                            (order) =>
                                order.progress == OrderProgress.cancelled,
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
                              color:
                                  selected ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
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
                child: visibleOrders.isEmpty
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
                    : ListView.separated(
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
                            onRequestRevision: order.progress ==
                                    OrderProgress.revision
                                ? () {
                                    _orderStore.requestOrderRevision(
                                      order.transactionId,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Permintaan revisi dikirim ke penjual.',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            onComplete: order.progress == OrderProgress.revision
                                ? () {
                                    _orderStore.completeOrder(
                                      order.transactionId,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pesanan selesai. Terima kasih!',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderPayment order) {
    showModalBottomSheet<void>(
      context: context,
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
              if (order.attachments.isNotEmpty)
                _DetailRow(
                  'File terlampir',
                  order.attachments.map((file) => file.name).join(', '),
                ),
              if (order.resultFiles.isNotEmpty)
                _DetailRow(
                  'Hasil pekerjaan',
                  order.resultFiles.map((file) => file.name).join(', '),
                ),
              if (order.resultFiles.isNotEmpty)
                for (final file in order.resultFiles)
                  if (file.isImage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          file.bytes,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            alignment: Alignment.center,
                            color: AppColors.background,
                            child: Text(
                              file.name,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
    this.onRequestRevision,
    this.onComplete,
  });

  final OrderPayment order;
  final VoidCallback onDetails;
  final VoidCallback onChat;
  final VoidCallback? onRequestRevision;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final paidAt = order.paidAt;
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
                  '#${order.transactionId ?? '-'} • ${paidAt == null ? '' : Formatters.shortDate(paidAt)}',
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
                  style: TextStyle(
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
                      'Penjual: ${order.service.seller} (${order.service.department})',
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
              backgroundColor: Color(0xFFE2E8F0),
              color: order.progress == OrderProgress.completed
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            order.progress == OrderProgress.completed
                ? 'Pesanan telah diselesaikan.'
                : order.progress == OrderProgress.revision
                    ? 'Penjual sudah mengirimkan hasil. Periksa lalu selesaikan atau minta revisi.'
                : 'Estimasi selesai mengikuti konfirmasi penjual.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
          if (order.resultFiles.isNotEmpty) ...[
            const SizedBox(height: 7),
            for (final file in order.resultFiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      file.isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
