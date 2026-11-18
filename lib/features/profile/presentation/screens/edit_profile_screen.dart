import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/services/order_service.dart';
import '../../controllers/seller_profile_store.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.isSeller = false});

  final bool isSeller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _programController = TextEditingController();
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

  late List<String> _availableSkills;
  late List<String> _selectedSkills;
  late List<String> _customSkills;
  Uint8List? _photoBytes;
  String? _photoName;
  String _remotePhotoUrl = '';
  String _remoteKtmUrl = '';
  String _verificationStatus = 'pending';
  String _verificationNote = '';
  Uint8List? _studentCardBytes;
  String? _studentCardName;
  bool _isPickingPhoto = false;
  bool _isPickingStudentCard = false;
  bool _isLoadingProfile = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = _sellerProfile;
    _photoBytes = profile.photoBytes;
    _photoName = profile.photoName;
    _studentCardBytes = profile.studentCardBytes;
    _studentCardName = profile.studentCardName;
    _customSkills = [...profile.customSkills];
    _availableSkills = <String>{
      ..._defaultSkills,
      ..._customSkills,
      ...profile.skills,
    }.toList();
    _selectedSkills = [...profile.skills];

    _loadProfileFromBackend();
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString('user_data');
      if (rawUser != null && rawUser.isNotEmpty) {
        final localUser = jsonDecode(rawUser) as Map<String, dynamic>;
        _applyUserData(localUser);
      }

      final userId = await OrderService.getLoggedInUserId();
      if (userId > 0) {
        final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/profile');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final remoteUser = decoded['data'] as Map<String, dynamic>?;
          if (remoteUser != null && mounted) {
            _applyUserData(remoteUser);
          }
        }
      }
    } catch (e) {
      debugPrint('Error load profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  void _applyUserData(Map<String, dynamic> data) {
    final nama = (data['nama'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final noHp = (data['no_hp'] ?? '').toString().trim();
    final universitas = (data['universitas'] ?? '').toString().trim();
    final jurusan = (data['jurusan'] ?? '').toString().trim();
    final nim = (data['nim'] ?? '').toString().trim();
    final ipk = (data['ipk'] ?? '').toString().trim();
    final bio = (data['bio'] ?? '').toString().trim();
    final keahlianRaw = (data['keahlian'] ?? '').toString().trim();
    final fotoUrl = (data['foto_url'] ?? '').toString().trim();
    final hostBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    if (fotoUrl.isNotEmpty) {
      _remotePhotoUrl = fotoUrl.startsWith('http') ? fotoUrl : '$hostBase$fotoUrl';
    }
    final ktmUrl = (data['ktm_url'] ?? '').toString().trim();
    if (ktmUrl.isNotEmpty) {
      _remoteKtmUrl = ktmUrl.startsWith('http') ? ktmUrl : '$hostBase$ktmUrl';
      _studentCardName ??= ktmUrl.split('/').last;
    }
    final statusVerif = (data['status_verifikasi'] ?? '').toString().trim();
    if (statusVerif.isNotEmpty) {
      _verificationStatus = statusVerif;
    }
    _verificationNote = (data['catatan_verifikasi'] ?? '').toString().trim();

    if (nama.isNotEmpty) _nameController.text = nama;
    if (email.isNotEmpty) _emailController.text = email;
    if (noHp.isNotEmpty) _phoneController.text = noHp;
    if (universitas.isNotEmpty) _universityController.text = universitas;
    if (jurusan.isNotEmpty) _programController.text = jurusan;
    if (nim.isNotEmpty) _nimController.text = nim;
    if (ipk.isNotEmpty) _gpaController.text = ipk;
    if (bio.isNotEmpty) _bioController.text = bio;

    if (keahlianRaw.isNotEmpty) {
      final parsedSkills = keahlianRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsedSkills.isNotEmpty) {
        _selectedSkills = parsedSkills;
        for (final s in parsedSkills) {
          if (!_availableSkills.contains(s)) {
            _availableSkills.add(s);
            _customSkills.add(s);
          }
        }
      }
    }
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

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'M' : parts;
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

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final nama = _nameController.text.trim();
    if (nama.isEmpty) {
      _showMessage('Nama lengkap wajib diisi.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await OrderService.getLoggedInUserId();
      if (userId <= 0) {
        _showMessage('Sesi pengguna tidak ditemukan. Silakan login ulang.');
        return;
      }

      final payload = <String, dynamic>{
        'nama': nama,
        'no_hp': _phoneController.text.trim(),
        'universitas': _universityController.text.trim(),
        'jurusan': _programController.text.trim(),
      };

      if (_photoBytes != null && _photoBytes!.isNotEmpty) {
        final ext = (_photoName ?? 'avatar.jpg').toLowerCase().endsWith('.png')
            ? 'png'
            : 'jpeg';
        payload['foto_base64'] =
            'data:image/$ext;base64,${base64Encode(_photoBytes!)}';
      }
      if (_studentCardBytes != null && _studentCardBytes!.isNotEmpty) {
        final lowerName = (_studentCardName ?? 'ktm.jpg').toLowerCase();
        final mime = lowerName.endsWith('.pdf')
            ? 'application/pdf'
            : (lowerName.endsWith('.png') ? 'image/png' : 'image/jpeg');
        payload['ktm_base64'] =
            'data:$mime;base64,${base64Encode(_studentCardBytes!)}';
      }
      if (widget.isSeller) {
        payload['bio'] = _bioController.text.trim();
        payload['nim'] = _nimController.text.trim();
        payload['ipk'] = _gpaController.text.trim();
        payload['keahlian'] = _selectedSkills.join(', ');
      } else if (_emailController.text.trim().isNotEmpty) {
        payload['email'] = _emailController.text.trim();
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/profile');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedData =
            (decoded['data'] as Map<String, dynamic>?) ?? payload;

        final prefs = await SharedPreferences.getInstance();
        final rawExisting = prefs.getString('user_data');
        final mergedUser = rawExisting != null && rawExisting.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(rawExisting))
            : <String, dynamic>{};
        mergedUser.addAll(updatedData);
        await prefs.setString('user_data', jsonEncode(mergedUser));

        _sellerProfile.update(
          name: nama,
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

        if (mounted) {
          _showMessage('Profil berhasil disimpan ke database.');
          context.go(Routes.profil);
        }
      } else {
        final err = jsonDecode(response.body);
        _showMessage(err['message']?.toString() ?? 'Gagal menyimpan profil.');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan koneksi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                                    backgroundImage: _photoBytes != null
                                        ? MemoryImage(_photoBytes!)
                                        : (_remotePhotoUrl.isNotEmpty
                                            ? NetworkImage(_remotePhotoUrl)
                                                as ImageProvider
                                            : null),
                                    child: (_photoBytes == null &&
                                            _remotePhotoUrl.isEmpty)
                                        ? Text(
                                            _getInitials(_nameController.text),
                                            style: const TextStyle(
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
                                        onPressed: _pickSellerPhoto,
                                        icon: const Icon(Icons.add),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _pickSellerPhoto,
                                child: const Text('Ubah Foto Profil'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        onPressed: _isSaving ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
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
          hasUploadedFile:
              _studentCardBytes != null || _remoteKtmUrl.isNotEmpty,
          verificationStatus: _verificationStatus,
          verificationNote: _verificationNote,
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
    required this.hasUploadedFile,
    required this.verificationStatus,
    required this.verificationNote,
    required this.isPicking,
    required this.onTap,
  });

  final String? fileName;
  final bool hasUploadedFile;
  final String verificationStatus;
  final String verificationNote;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalized = verificationStatus.toLowerCase();
    final isVerified = normalized == 'terverifikasi' || normalized == 'aktif';
    final isRejected = normalized == 'ditolak';

    final badgeColor = isVerified
        ? const Color(0xFFDCFCE7)
        : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
    final badgeTextColor = isVerified
        ? const Color(0xFF15803D)
        : (isRejected ? const Color(0xFFB91C1C) : const Color(0xFFB45309));
    final badgeLabel = isVerified
        ? 'Terverifikasi'
        : (isRejected
            ? 'Ditolak Admin'
            : (hasUploadedFile
                ? 'Menunggu Verifikasi Admin'
                : 'Belum Unggah KTM'));

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: AppColors.textSecondary,
                  ),
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
                              : fileName ??
                                  'Pilih foto atau PDF, maksimal 10 MB',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isRejected && verificationNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Catatan Admin: $verificationNote',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 10,
                  ),
                ),
              ],
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