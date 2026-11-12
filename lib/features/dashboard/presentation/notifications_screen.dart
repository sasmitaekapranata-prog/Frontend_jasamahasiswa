import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import '../controllers/chat_activity_store.dart';
import '../../profile/controllers/user_role_controller.dart';
import 'order_payment.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderStore = BuyerOrderStore.instance;
    final chatStore = ChatActivityStore.instance;
    final roleController = UserRoleController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([orderStore, chatStore, roleController]),
      builder: (context, _) {
        final role = roleController.selectedRole;
        final notifications = orderStore.notificationsFor(role);
        final unreadChatIds = chatStore.unreadChatIds(role);
        final unreadCount =
            orderStore.unreadNotificationCount(role) + unreadChatIds.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(fallbackLocation: Routes.beranda),
            title: const Text(
              'Notifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                onPressed: unreadCount == 0
                    ? null
                    : () {
                        orderStore.markAllNotificationsRead(role);
                        chatStore.markAllRead(role);
                      },
                child: const Text(
                  'Tandai semua dibaca',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
          ),
          body: notifications.isEmpty && unreadChatIds.isEmpty
              ? const _EmptyNotifications()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    if (unreadChatIds.isNotEmpty) ...[
                      const _NotificationSectionTitle('Pesan belum dibaca'),
                      for (final chatId in unreadChatIds) ...[
                        _ChatNotificationCard(
                          role: role,
                          chatId: chatId,
                          onTap: () {
                            chatStore.markRead(role, chatId);
                            context.push(
                              '${Routes.chatDetail}/${Uri.encodeComponent(chatId)}',
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    if (notifications.isNotEmpty) ...[
                      _NotificationSectionTitle(
                        unreadChatIds.isEmpty
                            ? 'Pembaruan pesanan'
                            : 'Riwayat pesanan',
                      ),
                      for (final notification in notifications) ...[
                        _NotificationCard(
                          notification: notification,
                          onTap: () {
                            orderStore.markNotificationRead(notification.id);
                            final order = orderStore.orderForTransaction(
                              notification.orderId,
                            );
                            if (order == null) {
                              context.push(
                                role == UserRole.penjual
                                    ? Routes.incomingOrders
                                    : Routes.statusPesanan,
                              );
                              return;
                            }
                            context.push(
                              '${Routes.chatDetail}/${Uri.encodeComponent(notification.orderId)}',
                              extra: order,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _NotificationSectionTitle extends StatelessWidget {
  const _NotificationSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ChatNotificationCard extends StatelessWidget {
  const _ChatNotificationCard({
    required this.role,
    required this.chatId,
    required this.onTap,
  });

  final UserRole role;
  final String chatId;
  final VoidCallback onTap;

  String get _senderName {
    final names = role == UserRole.penjual
        ? const {
            'ar': 'Ahmad Rizky',
            'sn': 'Siti Nabila',
            'dp': 'Dimas Pratama',
          }
        : const {
            'bs': 'Budi Setiawan',
            'aa': 'Annisa A. (Desain)',
            'rd': 'Rian D. (Tutor Web)',
          };
    return names[chatId.toLowerCase()] ?? 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFEAF2FF),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan baru dari $_senderName',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buka percakapan untuk melihat dan membalas pesan.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Belum dibaca',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada notifikasi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pembaruan pembayaran dan pesanan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final OrderNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (notification.kind) {
      OrderNotificationKind.paymentReceived => (
          Icons.check_circle_outline,
          AppColors.success,
          const Color(0xFFDCFCE7),
        ),
      OrderNotificationKind.newOrder => (
          Icons.shopping_bag_outlined,
          AppColors.primary,
          const Color(0xFFEAF2FF),
        ),
      OrderNotificationKind.orderAccepted => (
          Icons.handyman_outlined,
          AppColors.primary,
          const Color(0xFFEAF2FF),
        ),
      OrderNotificationKind.resultSubmitted => (
          Icons.assignment_turned_in_outlined,
          const Color(0xFFD97706),
          const Color(0xFFFFF3C4),
        ),
      OrderNotificationKind.revisionRequested => (
          Icons.replay_outlined,
          const Color(0xFFD97706),
          const Color(0xFFFFF3C4),
        ),
      OrderNotificationKind.orderCompleted => (
          Icons.task_alt,
          AppColors.success,
          const Color(0xFFDCFCE7),
        ),
    };

    return Material(
      color: notification.isRead ? AppColors.surface : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: background,
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${Formatters.shortDate(notification.createdAt)} • '
                      '${TimeOfDay.fromDateTime(notification.createdAt).format(context)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
