import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../controllers/seller_profile_store.dart';

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
  final _sellerProfile = SellerProfileStore.instance;
  static const _defaultSkills = [
    'Coding',
    'Desain',
    'Penulisan',
    'Olah Data',
    'Tutor',
    'SPSS & R',
    'Web Dev',
    'Python',
    'Skripsi',
  ];
  late final List<String> _availableSkills;
  late final List<String> _selectedSkills;
  late final List<String> _customSkills;
  Uint8List? _photoBytes;
  String? _photoName;
  Uint8List? _studentCardBytes;
  String? _studentCardName;
  bool _isPickingPhoto = false;
  bool _isPickingStudentCard = false;

  @override
  void initState() {
    super.initState();
    final profile = _sellerProfile;
    if (widget.isSeller) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _universityController.text = profile.university;
      _programController.text = profile.program;
      _bioController.text = profile.bio;
      _nimController.text = profile.nim;
      _gpaController.text = profile.gpa;
      _photoBytes = profile.photoBytes;
      _photoName = profile.photoName;
      _studentCardBytes = profile.studentCardBytes;
      _studentCardName = profile.studentCardName;
    }
    _customSkills = [...profile.customSkills];
    _availableSkills = [..._defaultSkills, ..._customSkills, ...profile.skills]
        .toSet()
        .toList();
    _selectedSkills = [...profile.skills];
  }

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

  Future<void> _pickSellerPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        _showMessage('Ukuran foto profil maksimal 5 MB.');
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Foto tidak dapat dibaca. Silakan pilih ulang.');
        return;
      }
      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
      });
    } on Exception catch (error) {
      if (mounted) _showMessage('Gagal memilih foto profil: $error');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _pickStudentCard() async {
    if (_isPickingStudentCard) return;
    setState(() => _isPickingStudentCard = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        _showMessage('Ukuran file KTM maksimal 10 MB.');
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('File KTM tidak dapat dibaca. Silakan pilih ulang.');
        return;
      }
      setState(() {
        _studentCardBytes = bytes;
        _studentCardName = file.name;
      });
    } on Exception catch (error) {
      if (mounted) _showMessage('Gagal memilih file KTM: $error');
    } finally {
      if (mounted) setState(() => _isPickingStudentCard = false);
    }
  }

  Future<void> _addCustomSkill() async {
    final controller = TextEditingController();
    final skill = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah kategori / skill'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Contoh: Ilustrasi Digital',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    controller.dispose();

    final value = skill?.trim();
    if (value == null || value.isEmpty || !mounted) return;
    final existing = _availableSkills.firstWhere(
      (item) => item.toLowerCase() == value.toLowerCase(),
      orElse: () => '',
    );
    setState(() {
      final selected = existing.isEmpty ? value : existing;
      if (existing.isEmpty) {
        _availableSkills.add(value);
        _customSkills.add(value);
      }
      if (!_selectedSkills.contains(selected)) _selectedSkills.add(selected);
    });
  }

  void _saveSellerProfile() {
    _sellerProfile.update(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      university: _universityController.text.trim(),
      program: _programController.text.trim(),
      bio: _bioController.text.trim(),
      nim: _nimController.text.trim(),
      gpa: _gpaController.text.trim(),
      photoBytes: _photoBytes,
      photoName: _photoName,
      studentCardBytes: _studentCardBytes,
      studentCardName: _studentCardName,
      skills: _selectedSkills,
      customSkills: _customSkills,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil penjual berhasil diperbarui.')),
    );
    context.go(Routes.profil);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: const Color(0xFFDCEAFF),
                              backgroundImage: _photoBytes == null
                                  ? null
                                  : MemoryImage(_photoBytes!),
                              child: _photoBytes == null
                                  ? const Text(
                                      'AS',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
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
                                  onPressed: widget.isSeller
                                      ? _pickSellerPhoto
                                      : _showBackendNotice,
                                  icon: const Icon(Icons.add),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: widget.isSeller
                              ? _pickSellerPhoto
                              : _showBackendNotice,
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
                  onPressed: widget.isSeller
                      ? _saveSellerProfile
                      : _showBackendNotice,
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
        _VerificationCard(
          fileName: _studentCardName,
          isPicking: _isPickingStudentCard,
          onTap: _pickStudentCard,
        ),
        const SizedBox(height: 18),
        const _SectionHeading('Kategori / Skill Utama'),
        _SkillList(
          availableSkills: _availableSkills,
          selectedSkills: _selectedSkills,
          onSkillToggled: (skill) {
            setState(() {
              if (_selectedSkills.contains(skill)) {
                _selectedSkills.remove(skill);
              } else {
                _selectedSkills.add(skill);
              }
            });
          },
          onAddSkill: _addCustomSkill,
        ),
      ],
    );
  }
}

class _BackendNotice extends StatelessWidget {
  const _BackendNotice({required this.isSeller});

  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    if (isSeller) return const SizedBox.shrink();
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
  const _VerificationCard({
    required this.fileName,
    required this.isPicking,
    required this.onTap,
  });

  final String? fileName;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kartu Tanda Mahasiswa (KTM)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPicking
                          ? 'Membuka file...'
                          : fileName ?? 'Pilih foto atau PDF, maksimal 10 MB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isPicking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.upload_file_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillList extends StatelessWidget {
  const _SkillList({
    required this.availableSkills,
    required this.selectedSkills,
    required this.onSkillToggled,
    required this.onAddSkill,
  });

  final List<String> availableSkills;
  final List<String> selectedSkills;
  final ValueChanged<String> onSkillToggled;
  final VoidCallback onAddSkill;

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
          for (final skill in availableSkills)
            FilterChip(
              label: Text(skill),
              selected: selectedSkills.contains(skill),
              onSelected: (_) => onSkillToggled(skill),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.surface,
              selectedColor: const Color(0xFFEFF6FF),
              side: BorderSide(
                color: selectedSkills.contains(skill)
                    ? const Color(0xFFBFDBFE)
                    : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: selectedSkills.contains(skill)
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 15),
            label: const Text('Tambah sendiri'),
            onPressed: onAddSkill,
            visualDensity: VisualDensity.compact,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
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
