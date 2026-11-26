import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';

class AiRecommendationChatScreen extends StatefulWidget {
  const AiRecommendationChatScreen({super.key});

  @override
  State<AiRecommendationChatScreen> createState() =>
      _AiRecommendationChatScreenState();
}

class _AiRecommendationChatScreenState
    extends State<AiRecommendationChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Halo! Aku bisa bantu mencari jasa yang cocok untuk kebutuhan kuliahmu. '
          'Ceritakan tugas yang sedang kamu kerjakan dan, kalau ada, budget-mu.',
      isAssistant: true,
    ),
  ];

  static const _suggestions = [
    'Bantu cari jasa coding',
    'Aku perlu desain presentasi',
    'Butuh bantuan olah data',
  ];

  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/ai/chat';
    }
    return 'http://localhost:3000/api/ai/chat';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestion]) async {
    final text = (suggestion ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isAssistant: false));
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToLatestMessage();

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final reply = (data['reply'] ?? '').toString().trim();
        final rawServices =
            (data['recommended_services'] as List<dynamic>?) ?? [];

        final services = rawServices
            .where((item) => item is Map<String, dynamic>)
            .map((item) => _RecommendedService.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              text: reply.isNotEmpty
                  ? reply
                  : 'Berikut rekomendasi jasa yang tersedia untukmu:',
              isAssistant: true,
              services: services,
            ),
          );
        });
      } else {
        final errMsg = (body['message'] ??
                'Maaf, Asisten Jasa sedang sibuk. Coba kirim ulang pesanmu.')
            .toString();
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatMessage(text: errMsg, isAssistant: true));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: 'Gagal terhubung ke server Asisten Jasa. Pastikan backend sedang berjalan lalu coba lagi.',
            isAssistant: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToLatestMessage();
      }
    }
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _messages.length + (_isLoading ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asisten Jasa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Bantu cari jasa yang cocok',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length == 1 && !_isLoading) _buildSuggestions(),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coba tanyakan',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _sendMessage(suggestion),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ceritakan kebutuhanmu...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _sendMessage,
              tooltip: 'Kirim pesan',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.arrow_upward, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Mencari jasa yang cocok...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAssistant
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isAssistant ? AppColors.surface : AppColors.primary,
                    border: isAssistant
                        ? Border.all(color: AppColors.border)
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAssistant ? 4 : 16),
                      bottomRight: Radius.circular(isAssistant ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isAssistant ? AppColors.textPrimary : Colors.white,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
                for (final service in message.services) ...[
                  const SizedBox(height: 8),
                  _ServiceSuggestionCard(service: service),
                ],
              ],
            ),
          ),
          if (!isAssistant) const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _ServiceSuggestionCard extends StatelessWidget {
  const _ServiceSuggestionCard({required this.service});

  final _RecommendedService service;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('${Routes.serviceDetail}/${service.id}'),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: service.color,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    service.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.price,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isAssistant,
    this.services = const [],
  });

  final String text;
  final bool isAssistant;
  final List<_RecommendedService> services;
}

class _RecommendedService {
  const _RecommendedService({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String price;
  final String category;
  final IconData icon;
  final Color color;

  factory _RecommendedService.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? 'UMUM').toString();
    final rawPrice = json['price'];
    final numPrice =
        rawPrice is num ? rawPrice.toInt() : int.tryParse('$rawPrice') ?? 0;

    return _RecommendedService(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Layanan Mahasiswa').toString(),
      price: 'Mulai Rp${_formatRupiah(numPrice)}',
      category: category,
      icon: _iconForCategory(category),
      color: _colorForCategory(category),
    );
  }

  static String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  static IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('coding') || lower.contains('web') || lower.contains('it')) {
      return Icons.code;
    }
    if (lower.contains('desain') || lower.contains('ppt') || lower.contains('grafis')) {
      return Icons.palette_outlined;
    }
    if (lower.contains('data') || lower.contains('spss') || lower.contains('olah')) {
      return Icons.insert_chart_outlined;
    }
    if (lower.contains('ketik') || lower.contains('tulis') || lower.contains('dokumen')) {
      return Icons.description_outlined;
    }
    return Icons.work_outline;
  }

  static Color _colorForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('coding') || lower.contains('web') || lower.contains('it')) {
      return const Color(0xFFEEF5FF);
    }
    if (lower.contains('desain') || lower.contains('ppt') || lower.contains('grafis')) {
      return const Color(0xFFFFF3C4);
    }
    if (lower.contains('data') || lower.contains('spss') || lower.contains('olah')) {
      return const Color(0xFFDCFCE7);
    }
    return const Color(0xFFF3E8FF);
  }
}
