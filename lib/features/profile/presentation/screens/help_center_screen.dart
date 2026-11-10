import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _faqs = [
    _HelpQuestion(
      question: 'Bagaimana jika hasil pekerjaan tidak sesuai?',
      answer:
          'Kamu dapat mengajukan revisi gratis sesuai kuota pada paket jasa. '
          'Jika terjadi kendala, simpan bukti percakapan dan hubungi tim bantuan '
          'agar kami dapat membantu meninjau masalahnya.',
    ),
    _HelpQuestion(
      question: 'Berapa lama proses verifikasi pembayaran?',
      answer:
          'Pembayaran biasanya diverifikasi setelah bukti pembayaran diterima. '
          'Periksa status pesanan secara berkala dan pastikan nominal serta '
          'informasi transaksi sudah sesuai.',
    ),
    _HelpQuestion(
      question: 'Bagaimana cara menjadi Penjual Jasa?',
      answer: 'Buka menu Profil, pilih Mode Penjual, lalu lengkapi profil dan '
          'informasi jasa. Publikasikan jasa agar dapat ditinjau sebelum '
          'ditampilkan kepada pembeli.',
    ),
    _HelpQuestion(
      question: 'Apakah identitas mahasiswa saya aman?',
      answer: 'Informasi identitas hanya digunakan untuk kebutuhan verifikasi '
          'mahasiswa dan tidak ditampilkan sebagai informasi publik.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.toLowerCase();
    final questions = _faqs
        .where(
          (item) =>
              item.question.toLowerCase().contains(normalizedQuery) ||
              item.answer.toLowerCase().contains(normalizedQuery),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Pusat Bantuan & FAQ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ada yang bisa dibantu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cari jawaban cepat atau hubungi tim kami',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText:
                        'Ketik masalah kamu (misal: Pembayaran, Garansi)...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 16),
                          ),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ContactSupportCard(onTap: _showContactNotice),
          const SizedBox(height: 18),
          const Text(
            'PERTANYAAN POPULER (FAQ)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Belum ada jawaban yang cocok. Coba kata kunci lain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            )
          else
            for (var index = 0; index < questions.length; index++)
              _FaqTile(
                question: questions[index],
                initiallyExpanded: _query.isEmpty && index == 0,
              ),
        ],
      ),
    );
  }

  void _showContactNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const CircleAvatar(
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.chat_bubble, color: Color(0xFF16A34A)),
        ),
        title: const Text('Hubungi Customer Service'),
        content: const Text(
          'Kontak WhatsApp Customer Service belum dikonfigurasi. '
          'Silakan gunakan FAQ untuk mencari jawaban sementara.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFECFDF3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF86EFAC)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF16A34A),
                child: Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hubungi CS via WhatsApp',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Respon cepat (08:00 - 21:00 WIB)',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(62, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Chat CS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.initiallyExpanded,
  });

  final _HelpQuestion question;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>(question.question),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          question.question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              question.answer,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpQuestion {
  const _HelpQuestion({required this.question, required this.answer});

  final String question;
  final String answer;
}
