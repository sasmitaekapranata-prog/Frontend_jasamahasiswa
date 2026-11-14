import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static const _services = [
    _RecommendedService(
      id: 'web-react',
      title: 'Jasa Web React & UI Tailwind',
      price: 'Mulai Rp50.000',
      category: 'Coding',
      icon: Icons.code,
      color: Color(0xFFEEF5FF),
    ),
    _RecommendedService(
      id: 'desain-ppt',
      title: 'Desain PPT & Poster Aesthetic',
      price: 'Mulai Rp25.000',
      category: 'Desain',
      icon: Icons.palette_outlined,
      color: Color(0xFFFFF3C4),
    ),
    _RecommendedService(
      id: 'olah-data',
      title: 'Olah Data SPSS & Skripsi',
      price: 'Mulai Rp75.000',
      category: 'Olah Data',
      icon: Icons.insert_chart_outlined,
      color: Color(0xFFDCFCE7),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? suggestion]) {
    final text = (suggestion ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final service = _matchService(text);
    setState(() {
      _messages.add(_ChatMessage(text: text, isAssistant: false));
      _messages.add(
        _ChatMessage(
          text: _buildReply(text, service),
          isAssistant: true,
          service: service,
        ),
      );
      _messageController.clear();
    });
    _scrollToLatestMessage();
  }

  _RecommendedService? _matchService(String text) {
    final normalized = text.toLowerCase();
    if (RegExp(r'\b(coding|kode|program|website|web|aplikasi|codingan)\b')
        .hasMatch(normalized)) {
      return _services[0];
    }
    if (RegExp(r'\b(desain|design|ppt|presentasi|poster|canva)\b')
        .hasMatch(normalized)) {
      return _services[1];
    }
    if (RegExp(r'\b(data|spss|skripsi|statistik|penelitian|olah)\b')
        .hasMatch(normalized)) {
      return _services[2];
    }
    return null;
  }

  String _buildReply(String text, _RecommendedService? service) {
    if (service != null) {
      return 'Dari ceritamu, jasa ${service.category.toLowerCase()} sepertinya '
          'paling sesuai. Ini salah satu pilihan yang bisa kamu lihat. '
          'Kamu juga bisa ceritakan deadline atau detail tugas agar pencarian '
          'lebih pas.';
    }

    if (RegExp(r'\b(tutor|belajar|mengajar|materi|paham)\b')
        .hasMatch(text.toLowerCase())) {
      return 'Kalau yang kamu butuhkan adalah belajar atau konsultasi, coba '
          'cari jasa tutor sesuai mata kuliahmu. Mata kuliah dan topik apa '
          'yang ingin kamu pelajari?';
    }

    return 'Boleh ceritakan lebih spesifik jasa yang kamu butuhkan? Misalnya '
        'coding website, desain presentasi, atau bantuan olah data. Kamu juga '
        'bisa menyebutkan kisaran budget agar aku bisa mengarahkan pilihan.';
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (_messages.length == 1) _buildSuggestions(),
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
              onPressed: _sendMessage,
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
                if (message.service case final service?) ...[
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
    this.service,
  });

  final String text;
  final bool isAssistant;
  final _RecommendedService? service;
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
}
