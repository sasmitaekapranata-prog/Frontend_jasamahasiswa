import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../dashboard/presentation/order_payment.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  final _orderStore = BuyerOrderStore.instance;

  @override
  void initState() {
    super.initState();
    _orderStore.markSellerNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text('Pesanan Masuk'),
      ),
      body: AnimatedBuilder(
        animation: _orderStore,
        builder: (context, _) {
          final orders = _orderStore.orders;
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Belum ada pesanan masuk. Notifikasi akan muncul saat ada pesanan baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _IncomingOrderCard(
                order: order,
                onAdvance: () => _advanceOrder(order),
              );
            },
          );
        },
      ),
    );
  }

  void _advanceOrder(OrderPayment order) {
    final nextProgress = switch (order.progress) {
      OrderProgress.waitingSeller => OrderProgress.inProgress,
      OrderProgress.inProgress => OrderProgress.revision,
      OrderProgress.revision => OrderProgress.completed,
      OrderProgress.completed || OrderProgress.cancelled => null,
    };
    if (nextProgress != null) {
      _orderStore.updateProgress(order.transactionId, nextProgress);
    }
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({
    required this.order,
    required this.onAdvance,
  });

  final OrderPayment order;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final nextLabel = switch (order.progress) {
      OrderProgress.waitingSeller => 'Mulai pengerjaan',
      OrderProgress.inProgress => 'Kirim untuk revisi',
      OrderProgress.revision => 'Tandai selesai',
      OrderProgress.completed || OrderProgress.cancelled => null,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${order.transactionId ?? '-'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.service.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brief: ${order.brief}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (order.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'File dari pembeli',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final attachment in order.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      attachment.isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            '${Formatters.currency(order.total)} • ${order.progress.label} '
            '(${order.progress.percentage}%)',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: order.progress.fraction,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: order.progress == OrderProgress.completed
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
          if (nextLabel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAdvance,
                child: Text(nextLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
