import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_back_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.isSeller = false});

  final bool isSeller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Arif Setiawan');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _programController = TextEditingController(
    text: 'S1 Teknik Informatika',
  );
  final _bioController = TextEditingController();
  final _nimController = TextEditingController();
  final _gpaController = TextEditingController();
  final _skills = <String>['SPSS & R', 'Web Dev', 'Python', 'Skripsi'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _programController.dispose();
    _bioController.dispose();
    _nimController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  void _showBackendNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Perubahan belum tersimpan. Sinkronisasi menunggu backend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isSeller ? 'Edit Profil Penjual' : 'Edit Profil Pembeli';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: Text(title),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CircleAvatar(
                              radius: 34,
                              backgroundColor: Color(0xFFDCEAFF),
                              child: Text(
                                'AS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  color: Colors.white,
                                  onPressed: _showBackendNotice,
                                  icon: const Icon(Icons.add),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showBackendNotice,
                          child: const Text('Ubah Foto Profil'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BackendNotice(isSeller: widget.isSeller),
                  const SizedBox(height: 20),
                  if (widget.isSeller)
                    _buildSellerFields()
                  else
                    _buildBuyerFields(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppColors.surface,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _showBackendNotice,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileField(label: 'Nama Lengkap', controller: _nameController),
        const SizedBox(height: 14),
        _ProfileField(
          label: 'Email Mahasiswa',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          hintText: 'Email yang digunakan saat daftar',
        ),
        const SizedBox(height: 14),
        _ProfileField(
          label: 'Nomor WhatsApp',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hintText: 'Masukkan nomor WhatsApp',
        ),
        const SizedBox(height: 14),
        _ProfileField(
          label: 'Universitas / Institusi',
          controller: _universityController,
          hintText: 'Masukkan nama universitas',
        ),
        const SizedBox(height: 14),
        _ProfileField(
          label: 'Program Studi',
          controller: _programController,
          hintText: 'Masukkan program studi',
        ),
      ],
    );
  }

  Widget _buildSellerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Data Pribadi'),
        _ProfileField(label: 'Nama Lengkap', controller: _nameController),
        const SizedBox(height: 12),
        _ProfileField(
          label: 'Nomor WhatsApp / HP',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hintText: 'Masukkan nomor WhatsApp',
        ),
        const SizedBox(height: 12),
        _ProfileField(
          label: 'Bio / Deskripsi Singkat Jasa',
          controller: _bioController,
          hintText: 'Ceritakan jasa yang kamu tawarkan',
          maxLines: 3,
        ),
        const SizedBox(height: 18),
        const _SectionHeading('Data Akademik Kampus'),
        _ProfileField(
          label: 'Nama Universitas',
          controller: _universityController,
          hintText: 'Masukkan nama universitas',
        ),
        const SizedBox(height: 12),
        _ProfileField(
          label: 'Fakultas / Program Studi',
          controller: _programController,
          hintText: 'Masukkan fakultas atau program studi',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProfileField(
                label: 'NIM / Angkatan',
                controller: _nimController,
                hintText: 'Masukkan NIM',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'IPK Terakhir',
                controller: _gpaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                hintText: 'Contoh: 3.80',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionHeading('Verifikasi Identitas Mahasiswa'),
        const _VerificationCard(),
        const SizedBox(height: 18),
        const _SectionHeading('Kategori / Skill Utama'),
        _SkillList(skills: _skills),
      ],
    );
  }
}

class _BackendNotice extends StatelessWidget {
  const _BackendNotice({required this.isSeller});

  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        isSeller
            ? 'Form penjual sudah disiapkan. Data pendaftaran, verifikasi, dan penyimpanan akan tersambung setelah backend tersedia.'
            : 'Form pembeli sudah disiapkan. Data pendaftaran dan penyimpanan akan tersambung setelah backend tersedia.',
        style: const TextStyle(
          color: Color(0xFF1E40AF),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hintText,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.badge_outlined, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kartu Tanda Mahasiswa (KTM)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Unggah dan verifikasi menunggu backend',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.upload_file_outlined, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _SkillList extends StatelessWidget {
  const _SkillList({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final skill in skills)
            Chip(
              label: Text(skill),
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFFEFF6FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              labelStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
