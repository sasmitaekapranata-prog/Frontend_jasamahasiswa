import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import '../controllers/chat_activity_store.dart';
import '../../profile/controllers/user_role_controller.dart';
import 'order_payment.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, this.chatId, this.order});

  final String? chatId;
  final OrderPayment? order;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final List<_ChatMessage> _messages = _initialMessages();

  bool get _isSeller =>
      UserRoleController.instance.selectedRole == UserRole.penjual;

  @override
  void initState() {
    super.initState();
    final chatId = widget.chatId;
    if (chatId != null) {
      ChatActivityStore.instance.markRead(
        UserRoleController.instance.selectedRole,
        chatId,
      );
    }
  }

  List<_ChatMessage> _initialMessages() {
    if (_isSeller) {
      return [
        const _ChatMessage(
          text: 'Halo kak, saya tertarik dengan jasa yang kamu tawarkan.',
          isMine: false,
          time: '12:08',
        ),
        const _ChatMessage(
          text: 'Halo! Tentu, boleh ceritakan kebutuhan atau brief-nya.',
          isMine: true,
          time: '12:09',
        ),
      ];
    }

    return [
      const _ChatMessage(
        text: 'Halo, saya sudah menerima brief pesanan kamu ya. 👋',
        isMine: false,
        time: '12:08',
      ),
      if (widget.order?.brief.isNotEmpty ?? false)
        _ChatMessage(
          text: 'Brief pesanan:\n${widget.order!.brief}',
          isMine: true,
          time: '12:09',
        ),
      const _ChatMessage(
        text:
            'Baik, proyeknya sedang saya kerjakan. Kalau ada yang perlu ditanyakan, kabari saya ya.',
        isMine: false,
        time: '12:10',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final counterpart = order != null && !_isSeller
        ? order.service.seller
        : _counterpartForChatId(widget.chatId, isSeller: _isSeller);
    final serviceTitle = order?.service.title ?? 'Konsultasi jasa';
    final transactionId = order?.transactionId ?? widget.chatId ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.chat),
        leadingWidth: 48,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFDCEAFF),
              child: Text(
                _initials(counterpart),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counterpart,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_isSeller ? 'Pembeli' : 'Penjual'} • Online',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Info kontak penjual belum tersedia.')),
            ),
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          if (order != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: const Color(0xFFFFF3C4),
              child: Text(
                'Pesanan Aktif: $serviceTitle • ${Formatters.currency(order.total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A5A00),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔒 Jaga keamanan transaksi. Jangan lakukan pembayaran di luar sistem. • #$transactionId',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 9,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hari ini, 12:08',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  message: message,
                  initials: _initials(counterpart),
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            onAttach: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lampiran belum tersedia.')),
            ),
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final chatId = widget.chatId;
    if (chatId != null) {
      ChatActivityStore.instance.markCounterpartUnread(
        UserRoleController.instance.selectedRole,
        chatId,
      );
    }
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isMine: true,
          time: TimeOfDay.now().format(context),
        ),
      );
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

String _counterpartForChatId(String? chatId, {required bool isSeller}) {
  if (isSeller) {
    switch (chatId?.toLowerCase()) {
      case 'sn':
        return 'Siti Nabila';
      case 'dp':
        return 'Dimas Pratama';
      default:
        return 'Ahmad Rizky';
    }
  }
  switch (chatId?.toLowerCase()) {
    case 'aa':
      return 'Annisa A.';
    case 'rd':
      return 'Rian D.';
    default:
      return 'Budi Setiawan';
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
  });

  final String text;
  final bool isMine;
  final String time;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.initials});

  final _ChatMessage message;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 6),
      decoration: BoxDecoration(
        color: message.isMine ? AppColors.primary : Colors.white,
        border: message.isMine ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(message.isMine ? 12 : 4),
          bottomRight: Radius.circular(message.isMine ? 4 : 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.time,
            style: TextStyle(
              color: message.isMine
                  ? Colors.white.withValues(alpha: 0.75)
                  : AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMine) ...[
            CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFFDCEAFF),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: onAttach,
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send, size: 17),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
