import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../features/profile/controllers/user_role_controller.dart';
import '../controllers/chat_activity_store.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _roleController = UserRoleController.instance;
  final _chatStore = ChatActivityStore.instance;
  String _query = '';

  static const _buyerChats = [
    _Chat(
      name: 'Budi Setiawan',
      initials: 'BS',
      role: 'Penjual',
      preview: 'Siap mas, source code C++ sudah selesai...',
      time: '09:48',
      color: Color(0xFFDCEAFF),
      online: true,
    ),
    _Chat(
      name: 'Annisa A. (Desain)',
      initials: 'AA',
      role: 'Penjual',
      preview: 'Baik, revisi poster 2D sudah dikirim ya.',
      time: 'Kemarin',
      color: Color(0xFFFFF2C2),
    ),
    _Chat(
      name: 'Rian D. (Tutor Web)',
      initials: 'RD',
      role: 'Penjual',
      preview: 'Jadwal konsultasi Google Meet jam 7 malam.',
      time: '25 Sep',
      color: Color(0xFFE2E7FF),
    ),
  ];

  static const _sellerChats = [
    _Chat(
      name: 'Ahmad Rizky',
      initials: 'AR',
      role: 'Pembeli',
      preview: 'Kak, apakah bisa dibantu revisi desainnya?',
      time: '10:12',
      color: Color(0xFFDCEAFF),
    ),
    _Chat(
      name: 'Siti Nabila',
      initials: 'SN',
      role: 'Pembeli',
      preview: 'Saya sudah mengirim brief dan referensi.',
      time: 'Kemarin',
      color: Color(0xFFFFF2C2),
    ),
    _Chat(
      name: 'Dimas Pratama',
      initials: 'DP',
      role: 'Pembeli',
      preview: 'Terima kasih, hasilnya sudah saya terima.',
      time: '25 Sep',
      color: Color(0xFFE2E7FF),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
          animation: Listenable.merge([_roleController, _chatStore]),
          builder: (context, _) {
            final role = _roleController.selectedRole;
            final isSeller = role == UserRole.penjual;
            final chats = isSeller ? _sellerChats : _buyerChats;
            final normalizedQuery = _query.toLowerCase();
            final visibleChats = chats
                .where(
                  (chat) =>
                      chat.name.toLowerCase().contains(normalizedQuery) ||
                      chat.preview.toLowerCase().contains(normalizedQuery),
                )
                .toList();

            return ListView(
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
                if (visibleChats.isEmpty)
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
                          'Obrolan tidak ditemukan.',
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
                          _ChatCard(
                            chat: visibleChats[index],
                            unread: _chatStore.isUnread(
                              role,
                              visibleChats[index].initials,
                            ),
                            onTap: () => context.push(
                              _openChat(role, visibleChats[index].initials),
                            ),
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
            );
          },
        ),
      ),
    );
  }

  String _openChat(UserRole role, String chatId) {
    _chatStore.markRead(role, chatId);
    return '${Routes.chatDetail}/${chatId.toLowerCase()}';
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
              '$mode • percakapan dengan $counterpart',
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

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.unread,
    required this.onTap,
  });

  final _Chat chat;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                    backgroundColor: chat.color,
                    child: Text(
                      chat.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (chat.online)
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
                      chat.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chat.role,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      chat.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.w400,
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
                    chat.time,
                    style: TextStyle(
                      color: unread
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  if (unread) ...[
                    const SizedBox(height: 7),
                    const CircleAvatar(
                      radius: 7,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 8),
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

class _Chat {
  const _Chat({
    required this.name,
    required this.initials,
    required this.role,
    required this.preview,
    required this.time,
    required this.color,
    this.online = false,
  });

  final String name;
  final String initials;
  final String role;
  final String preview;
  final String time;
  final Color color;
  final bool online;
}
