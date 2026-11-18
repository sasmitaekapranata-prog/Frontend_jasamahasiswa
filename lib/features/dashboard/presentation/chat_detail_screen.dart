import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/services/chat_service.dart';
import '../../auth/services/order_service.dart';
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

  List<ChatMessageItem> _messages = [];
  int _myUserId = 1;
  int? _counterpartId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;

  bool get _isSeller =>
      UserRoleController.instance.selectedRole == UserRole.penjual;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final myId = await OrderService.getLoggedInUserId();
    int? targetId;
    final order = widget.order;
    if (order != null) {
      if (order.buyerId != null && order.buyerId != myId) {
        targetId = order.buyerId;
      } else if (order.sellerId != null && order.sellerId != myId) {
        targetId = order.sellerId;
      }
    }
    targetId ??= int.tryParse(widget.chatId ?? '');

    if (targetId == null || targetId == 0) {
      final fetchedOrders = _isSeller
          ? await OrderService.getSellerOrders()
          : await OrderService.getBuyerOrders();
      for (final item in fetchedOrders) {
        if (order?.dbId != null && item.dbId == order!.dbId) {
          targetId = _isSeller ? item.buyerId : item.sellerId;
          break;
        }
        if (order?.transactionId != null &&
            item.transactionId == order!.transactionId) {
          targetId = _isSeller ? item.buyerId : item.sellerId;
          break;
        }
      }
      if ((targetId == null || targetId == 0) && fetchedOrders.isNotEmpty) {
        targetId = _isSeller
            ? fetchedOrders.first.buyerId
            : fetchedOrders.first.sellerId;
      }
    }

    if (!mounted) return;
    setState(() {
      _myUserId = myId;
      _counterpartId = (targetId != null && targetId > 0) ? targetId : null;
    });

    await _fetchMessages(scrollToBottom: true);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchMessages(scrollToBottom: false),
    );
  }

  Future<void> _fetchMessages({required bool scrollToBottom}) async {
    if (_counterpartId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final fetched = await ChatService.getMessages(_counterpartId!);
      if (!mounted) return;
      final hasNew = fetched.length != _messages.length;
      setState(() {
        _messages = fetched;
        _isLoading = false;
      });
      if (scrollToBottom || hasNew) {
        _scrollToEnd();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatClock(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _counterpartId == null || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final sent = await ChatService.sendMessage(
      receiverId: _counterpartId!,
      orderId: widget.order?.dbId,
      message: text,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    if (sent != null) {
      await _fetchMessages(scrollToBottom: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim pesan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickAndSendAttachment() async {
    if (_counterpartId == null || _isSending) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'zip',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isSending = true);
    final sent = await ChatService.sendMessage(
      receiverId: _counterpartId!,
      orderId: widget.order?.dbId,
      message: _messageController.text.trim(),
      fileBytes: file.bytes,
      fileName: file.name,
      fileSize: _formatBytes(file.size),
    );
    if (!mounted) return;
    _messageController.clear();
    setState(() => _isSending = false);

    if (sent != null) {
      await _fetchMessages(scrollToBottom: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunggah lampiran.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final counterpart = order != null
        ? (_isSeller ? order.buyerName : order.service.seller)
        : 'Pengguna';
    final serviceTitle = order?.service.title ?? 'Konsultasi jasa';
    final transactionId = order?.transactionId ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.chat),
        leadingWidth: 48,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDCEAFF),
                  child: Text(
                    _initials(counterpart),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_isSeller ? 'Pembeli' : 'Penjual'} - Online',
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          if (order != null && order.total > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              color: const Color(0xFFFEF3C7),
              child: Text(
                'Pesanan Aktif: $serviceTitle (${Formatters.currency(order.total)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Jaga keamanan transaksi! Jangan lakukan pembayaran di luar sistem.${transactionId != '-' ? ' - #$transactionId' : ''}',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Belum ada pesan dengan $counterpart.\nKirim pesan pertama atau lampirkan file brief/hasil di bawah.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg.senderId == _myUserId;
                          return _RealMessageBubble(
                            message: msg,
                            isMine: isMine,
                            initials: _initials(counterpart),
                            timeText: _formatClock(msg.createdAt),
                          );
                        },
                      ),
          ),
          _Composer(
            controller: _messageController,
            isSending: _isSending,
            onAttach: _pickAndSendAttachment,
            onSend: _sendTextMessage,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _RealMessageBubble extends StatelessWidget {
  const _RealMessageBubble({
    required this.message,
    required this.isMine,
    required this.initials,
    required this.timeText,
  });

  final ChatMessageItem message;
  final bool isMine;
  final String initials;
  final String timeText;

  bool _isImage(String? name) {
    if (name == null) return false;
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = message.fileUrl != null && message.fileUrl!.isNotEmpty;
    final extLabel = (message.fileName ?? 'FILE')
        .split('.')
        .last
        .toUpperCase();

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 275),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : Colors.white,
        border: isMine ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFile) ...[
            if (_isImage(message.fileName))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.fileUrl!,
                    height: 140,
                    width: 230,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.fileUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Link lampiran disalin! Tempel di browser untuk membuka/unduh.',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        extLabel.length > 4 ? 'FILE' : extLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.fileName ?? 'Lampiran',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isMine
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${message.fileSize ?? 'File'} - Ketuk untuk salin link',
                            style: TextStyle(
                              color: isMine
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.message.isNotEmpty) const SizedBox(height: 6),
          ],
          if (message.message.isNotEmpty)
            Text(
              message.message,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isMine ? '$timeText ' : timeText,
              style: TextStyle(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFDCEAFF),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 7),
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
    required this.isSending,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
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
              onPressed: isSending ? null : onAttach,
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(38, 38),
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
                    horizontal: 14,
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
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 17),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(38, 38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}