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
import '../../controllers/seller_service_store.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key, this.service});

  final SellerService? service;

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  static const _maxCoverBytes = 5 * 1024 * 1024;

  // Disesuaikan dengan ID pada tabel `categories` di phpMyAdmin (1 - 4)
  static const Map<String, int> _categoryMap = {
    'Coding': 1,
    'Desain': 2,
    'Tugas': 3,
    'Ketik': 4,
  };

  static List<String> get _categories => _categoryMap.keys.toList();

  final _formKey = GlobalKey<FormState>();
  final _coverFieldKey = GlobalKey<FormFieldState<Uint8List>>();
  late final TextEditingController _titleController;
  late final TextEditingController _packageController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _deliverablesController;
  late String _category;
  late int _deliveryDays;
  late int _revisions;
  Uint8List? _coverBytes;
  String? _coverName;
  bool _isPickingCover = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _titleController = TextEditingController(text: service?.title);
    _packageController = TextEditingController(
      text: service?.packageName.isNotEmpty == true ? service!.packageName : '',
    );
    _priceController = TextEditingController(
      text: service == null ? '' : service.price.toString(),
    );
    _descriptionController = TextEditingController(text: service?.description);
    _deliverablesController = TextEditingController(
      text: service?.deliverables.join('\n'),
    );
    _category = _categories.contains(service?.category)
        ? service!.category
        : _categories.first;
    _deliveryDays = service?.deliveryDays ?? 2;
    _revisions = service?.revisions ?? 2;
    _coverBytes = service?.coverBytes;
    _coverName = service?.coverName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _packageController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _deliverablesController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    if (_isPickingCover) return;
    setState(() => _isPickingCover = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        _showMessage('Format sampul harus JPG atau PNG.');
        return;
      }
      if (file.size > _maxCoverBytes) {
        _showMessage('Ukuran sampul maksimal 5 MB.');
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('File sampul tidak dapat dibaca. Silakan pilih ulang.');
        return;
      }

      setState(() {
        _coverBytes = bytes;
        _coverName = file.name;
      });
      _coverFieldKey.currentState?.didChange(bytes);
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Gagal memilih sampul: $error');
      }
    } finally {
      if (mounted) setState(() => _isPickingCover = false);
    }
  }

  // Mengambil ID user yang sedang login dari SharedPreferences
  Future<int> _getLoggedInSellerId(SharedPreferences prefs) async {
    final directIntId = prefs.getInt('user_id');
    if (directIntId != null) return directIntId;

    final directStrId = prefs.getString('user_id');
    if (directStrId != null && int.tryParse(directStrId) != null) {
      return int.parse(directStrId);
    }

    final userJsonStr = prefs.getString('user');
    if (userJsonStr != null) {
      try {
        final userMap = jsonDecode(userJsonStr);
        if (userMap is Map && userMap['id'] != null) {
          return int.tryParse(userMap['id'].toString()) ?? 1;
        }
      } catch (_) {}
    }

    return 1; // Fallback ID default jika sesi lokal belum menyimpan ID
  }

  Future<void> _save({required SellerServiceStatus status}) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final price = int.parse(
      _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final deliverables = _deliverablesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final store = SellerServiceStore.instance;

    if (_isEditing) {
      store.update(
        widget.service!.copyWith(
          title: _titleController.text.trim(),
          price: price,
          category: _category,
          description: _descriptionController.text.trim(),
          deliverables: deliverables,
          coverName: _coverName,
          coverBytes: _coverBytes,
          packageName: _packageController.text.trim(),
          deliveryDays: _deliveryDays,
          revisions: _revisions,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = await _getLoggedInSellerId(prefs);
      final token = prefs.getString('token');

      // Gabungkan deskripsi dengan keunggulan paket agar tersimpan lengkap di kolom deskripsi
      final baseDesc = _descriptionController.text.trim();
      final fullDescription = deliverables.isEmpty
          ? baseDesc
          : '$baseDesc\n\nYang termasuk dalam paket:\n${deliverables.map((e) => '• $e').join('\n')}';

      // Status 'aktif' saat Publikasikan Jasa agar langsung tampil di Beranda untuk diuji
      final dbStatus = status == SellerServiceStatus.draft ? 'draft' : 'aktif';

      // Konversi foto sampul ke format Base64 untuk dikirim ke Backend
      String? coverBase64;
      if (_coverBytes != null) {
        final ext = (_coverName ?? '').toLowerCase().endsWith('.png')
            ? 'png'
            : 'jpeg';
        coverBase64 = 'data:image/$ext;base64,${base64Encode(_coverBytes!)}';
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/services');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'seller_id': sellerId,
          'category_id': _categoryMap[_category] ?? 1,
          'judul': _titleController.text.trim(),
          'deskripsi': fullDescription,
          'harga': price,
          'nama_paket': _packageController.text.trim(),
          'waktu_pengerjaan': _deliveryDays,
          'jumlah_revisi': _revisions,
          'banner_base64': coverBase64,
          'status': dbStatus,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Tetap simpan ke local store agar state lokal tetap sinkron
        store.add(
          title: _titleController.text.trim(),
          price: price,
          category: _category,
          description: baseDesc,
          deliverables: deliverables,
          status: status,
          coverName: _coverName,
          coverBytes: _coverBytes,
          packageName: _packageController.text.trim(),
          deliveryDays: _deliveryDays,
          revisions: _revisions,
        );

        _showMessage(
          dbStatus == 'draft'
              ? 'Draft jasa berhasil disimpan ke database!'
              : 'Penawaran jasa berhasil dipublikasikan!',
        );

        // Jika dipublikasikan, langsung arahkan ke Beranda agar hasilnya langsung terlihat
        if (dbStatus == 'aktif') {
          context.go(Routes.beranda);
        } else {
          context.go(Routes.manageServices);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(errorData['message'] ?? 'Gagal menyimpan jasa ke server.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Terjadi kesalahan koneksi ke server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: Text(_isEditing ? 'Edit Jasa' : 'Buka Penawaran Jasa Baru'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _SectionTitle('1. Informasi Utama'),
                  const SizedBox(height: 10),
                  _FormLabel(
                    label: 'Judul Jasa',
                    child: TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        'Contoh: Saya akan membuat desain logo minimalis...',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Judul jasa wajib diisi'
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(
                    label: 'Kategori Jasa',
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _decoration('Pilih kategori jasa'),
                      items: [
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('2. Sampul & Media *'),
                  const SizedBox(height: 8),
                  _CoverPicker(
                    fieldKey: _coverFieldKey,
                    bytes: _coverBytes,
                    fileName: _coverName,
                    isPicking: _isPickingCover,
                    onTap: _pickCover,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('3. Detail Paket & Harga'),
                  const SizedBox(height: 8),
                  _Panel(
                    child: Column(
                      children: [
                        _FormLabel(
                          label: 'Nama Paket',
                          child: TextFormField(
                            controller: _packageController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _decoration(
                              'Contoh: Paket Logo Starter (1 Konsep Logo)',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nama paket wajib diisi'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _FormLabel(
                                label: 'Harga Jasa (Rp)',
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration('Contoh: 250000'),
                                  validator: (value) {
                                    final price = int.tryParse(
                                      (value ?? '').replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    );
                                    if (price == null || price <= 0) {
                                      return 'Harga wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FormLabel(
                                label: 'Waktu Pengerjaan',
                                child: DropdownButtonFormField<int>(
                                  initialValue: _deliveryDays,
                                  decoration: _decoration('Durasi'),
                                  items: [
                                    for (var days = 1; days <= 14; days++)
                                      DropdownMenuItem(
                                        value: days,
                                        child: Text('$days hari kerja'),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _deliveryDays = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _FormLabel(
                          label: 'Jumlah Revisi',
                          child: DropdownButtonFormField<int>(
                            initialValue: _revisions,
                            decoration: _decoration('Pilih jumlah revisi'),
                            items: [
                              for (var count = 0; count <= 10; count++)
                                DropdownMenuItem(
                                  value: count,
                                  child: Text(
                                    count == 0
                                        ? 'Tanpa revisi'
                                        : '$count kali kesempatan revisi',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _revisions = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('4. Deskripsi & Keunggulan'),
                  const SizedBox(height: 8),
                  _FormLabel(
                    label: 'Jelaskan cakupan & keunggulan layanan Anda',
                    child: TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: 7,
                      decoration: _decoration(
                        'Jelaskan layanan, keunggulan, dan hasil yang diterima pembeli.',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Deskripsi jasa wajib diisi'
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(
                    label: 'Yang termasuk dalam paket (satu item per baris)',
                    child: TextFormField(
                      controller: _deliverablesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _decoration(
                        'File resolusi tinggi\nKonsultasi konsep\nGaransi pengerjaan',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .split('\n')
                                .every((item) => item.trim().isEmpty)) {
                          return 'Isi minimal satu keunggulan layanan';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _save(status: SellerServiceStatus.draft),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Simpan Draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _save(
                                  status: SellerServiceStatus.underReview,
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Publikasikan Jasa',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.fieldKey,
    required this.bytes,
    required this.fileName,
    required this.isPicking,
    required this.onTap,
  });

  final GlobalKey<FormFieldState<Uint8List>> fieldKey;
  final Uint8List? bytes;
  final String? fileName;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FormField<Uint8List>(
      key: fieldKey,
      initialValue: bytes,
      validator: (value) =>
          value == null || value.isEmpty ? 'Sampul & Media wajib diisi' : null,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isPicking ? null : onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        hasError ? AppColors.danger : const Color(0xFF9FB4D0),
                    width: hasError ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: bytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isPicking)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            isPicking
                                ? 'Membuka file...'
                                : 'Unggah Foto Sampul Jasa',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Format JPG, PNG (Maks 5 MB)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(bytes!, fit: BoxFit.cover),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                fileName ?? 'Sampul terpilih',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(
                state.errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 10),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}