import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/services/chat_service.dart';
import '../../../features/profile/controllers/user_role_controller.dart';
import 'order_payment.dart';
import 'service_catalog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _roleController = UserRoleController.instance;

  List<ChatConversationItem> _conversations = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final items = await ChatService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Baru';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return Formatters.shortDate(local);
  }

  OrderPayment _toOrderContext(
    ChatConversationItem item, {
    required bool isSeller,
  }) {
    return OrderPayment(
      dbId: item.latestOrderId,
      buyerId: isSeller ? item.counterpartId : null,
      sellerId: isSeller ? null : item.counterpartId,
      rawStatus: item.latestOrderStatus ?? 'diproses',
      service: ServiceInfo(
        id: '0',
        title: item.latestServiceTitle ?? 'Konsultasi Jasa',
        seller: isSeller ? 'Saya' : item.counterpartName,
        department: item.counterpartDepartment,
        rating: '5.0',
        reviews: 0,
        salesCount: 0,
        price: item.latestOrderTotal ?? 0,
        category: 'Jasa',
        color: const Color(0xFFDCEAFF),
        iconColor: AppColors.primary,
        icon: Icons.work_outline,
        description: '',
        includes: const [],
      ),
      brief: '',
      paymentMethod: 'QRIS',
      total: item.latestOrderTotal ?? 0,
      buyerName: isSeller ? item.counterpartName : 'Saya',
      transactionId: item.latestOrderCode ?? 'CHAT-${item.counterpartId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh, size: 20),
          ),
          IconButton(
            tooltip: 'Cari obrolan',
            onPressed: _searchFocusNode.requestFocus,
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _roleController,
          builder: (context, _) {
            final isSeller = _roleController.selectedRole == UserRole.penjual;
            final normalizedQuery = _query.toLowerCase();
            final visibleChats = _conversations
                .where(
                  (c) =>
                      c.counterpartName
                          .toLowerCase()
                          .contains(normalizedQuery) ||
                      c.lastMessage.toLowerCase().contains(normalizedQuery) ||
                      (c.latestServiceTitle ?? '')
                          .toLowerCase()
                          .contains(normalizedQuery),
                )
                .toList();

            return RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _ChatModeBanner(
                    mode: isSeller ? 'Mode Penjual' : 'Mode Pembeli',
                    counterpart: isSeller ? 'Pembeli' : 'Penjual',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau pesan...',
                      prefixIcon: const Icon(Icons.search, size: 19),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _query.isEmpty ? 'Obrolan Terbaru' : 'Hasil Pencarian',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (visibleChats.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada obrolan. Pesan akan muncul setelah ada pesanan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < visibleChats.length;
                              index++) ...[
                            _ConversationTile(
                              item: visibleChats[index],
                              initials: _initials(
                                visibleChats[index].counterpartName,
                              ),
                              roleLabel: isSeller ? 'Pembeli' : 'Penjual',
                              timeLabel: _formatTime(
                                visibleChats[index].lastMessageAt,
                              ),
                              onTap: () async {
                                final item = visibleChats[index];
                                await context.push(
                                  '${Routes.chatDetail}/${item.counterpartId}',
                                  extra: _toOrderContext(
                                    item,
                                    isSeller: isSeller,
                                  ),
                                );
                                _loadConversations();
                              },
                            ),
                            if (index != visibleChats.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(left: 68),
                                child: Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatModeBanner extends StatelessWidget {
  const _ChatModeBanner({required this.mode, required this.counterpart});

  final String mode;
  final String counterpart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_horiz,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$mode - percakapan dengan $counterpart',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.item,
    required this.initials,
    required this.roleLabel,
    required this.timeLabel,
    required this.onTap,
  });

  final ChatConversationItem item;
  final String initials;
  final String roleLabel;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item.unreadCount > 0;
    return Material(
      color: unread ? const Color(0xFFF5F9FF) : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFDCEAFF),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.counterpartName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.latestServiceTitle != null
                          ? '$roleLabel - ${item.latestServiceTitle}'
                          : roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: unread
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  if (unread) ...[
                    const SizedBox(height: 7),
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${item.unreadCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}