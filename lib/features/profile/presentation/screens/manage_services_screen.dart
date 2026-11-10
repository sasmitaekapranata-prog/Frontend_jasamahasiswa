import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../controllers/seller_service_store.dart';
import 'create_service_screen.dart';

enum _ServiceFilter { all, active, inactive, draft, underReview }

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _store = SellerServiceStore.instance;
  _ServiceFilter _filter = _ServiceFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Kelola Jasa Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final services = _store.services;
          final filteredServices =
              services.where((service) => _matchesFilter(service)).toList();

          return Column(
            children: [
              _FilterBar(
                selected: _filter,
                counts: {
                  _ServiceFilter.all: services.length,
                  _ServiceFilter.active:
                      _count(services, SellerServiceStatus.active),
                  _ServiceFilter.inactive:
                      _count(services, SellerServiceStatus.inactive),
                  _ServiceFilter.draft:
                      _count(services, SellerServiceStatus.draft),
                  _ServiceFilter.underReview:
                      _count(services, SellerServiceStatus.underReview),
                },
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              Expanded(
                child: filteredServices.isEmpty
                    ? const _EmptyServices()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: filteredServices.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ServiceCard(
                          service: filteredServices[index],
                          onToggle: () => _toggle(filteredServices[index]),
                          onEdit: () => _edit(filteredServices[index]),
                          onDelete: () => _delete(filteredServices[index]),
                          onDetails: () =>
                              _showDetails(filteredServices[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _matchesFilter(SellerService service) {
    return switch (_filter) {
      _ServiceFilter.all => true,
      _ServiceFilter.active => service.status == SellerServiceStatus.active,
      _ServiceFilter.inactive => service.status == SellerServiceStatus.inactive,
      _ServiceFilter.draft => service.status == SellerServiceStatus.draft,
      _ServiceFilter.underReview =>
        service.status == SellerServiceStatus.underReview,
    };
  }

  int _count(List<SellerService> services, SellerServiceStatus status) {
    return services.where((service) => service.status == status).length;
  }

  void _toggle(SellerService service) {
    final nextStatus = service.status == SellerServiceStatus.active
        ? SellerServiceStatus.inactive
        : SellerServiceStatus.active;
    _store.setStatus(service.id, nextStatus);
  }

  Future<void> _edit(SellerService service) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreateServiceScreen(service: service),
      ),
    );
  }

  Future<void> _delete(SellerService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jasa?'),
        content: Text('Jasa "${service.title}" akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _store.delete(service.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jasa berhasil dihapus.')),
      );
    }
  }

  void _showDetails(SellerService service) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori: ${service.category}'),
            const SizedBox(height: 8),
            Text('Harga: ${Formatters.currency(service.price)}'),
            const SizedBox(height: 8),
            if (service.packageName.isNotEmpty) ...[
              Text('Paket: ${service.packageName}'),
              const SizedBox(height: 8),
            ],
            Text('Waktu pengerjaan: ${service.deliveryDays} hari kerja'),
            Text('Revisi: ${service.revisions}x'),
            const SizedBox(height: 8),
            Text('Status: ${_statusLabel(service.status)}'),
            const SizedBox(height: 12),
            Text(service.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _edit(service);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final _ServiceFilter selected;
  final Map<_ServiceFilter, int> counts;
  final ValueChanged<_ServiceFilter> onSelected;

  static const _filters = [
    _ServiceFilter.all,
    _ServiceFilter.active,
    _ServiceFilter.inactive,
    _ServiceFilter.draft,
    _ServiceFilter.underReview,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _filters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text('${_filterLabel(filter)} (${counts[filter]})'),
                  selected: selected == filter,
                  onSelected: (_) => onSelected(filter),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected == filter
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  selectedColor: AppColors.primary,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
  });

  final SellerService service;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final isActive = service.status == SellerServiceStatus.active;
    final canToggle =
        isActive || service.status == SellerServiceStatus.inactive;
    final color = _categoryColor(service.category);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: service.coverBytes == null
                    ? Icon(_categoryIcon(service.category), color: color)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          service.coverBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.currency(service.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Terjual: ${service.salesCount}x  •  Rating: ⭐ ${service.rating}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _StatusBadge(status: service.status),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          if (canToggle)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tampilkan Layanan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                _ActionButton(label: 'Edit', onPressed: onEdit),
                const SizedBox(width: 6),
                _ActionButton(
                  label: 'Hapus',
                  onPressed: onDelete,
                  isDestructive: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.status == SellerServiceStatus.underReview
                        ? 'Sedang diverifikasi tim moderasi'
                        : 'Jasa tersimpan sebagai draft',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ),
                _ActionButton(
                  label: service.status == SellerServiceStatus.draft
                      ? 'Edit'
                      : 'Detail',
                  onPressed: service.status == SellerServiceStatus.draft
                      ? onEdit
                      : onDetails,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: 'Hapus',
                  onPressed: onDelete,
                  isDestructive: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SellerServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      SellerServiceStatus.active => (
          '● Aktif',
          const Color(0xFF15803D),
          const Color(0xFFDCFCE7),
        ),
      SellerServiceStatus.inactive => (
          '● Nonaktif',
          AppColors.danger,
          const Color(0xFFFFF1F2),
        ),
      SellerServiceStatus.draft => (
          'Draft',
          AppColors.textSecondary,
          const Color(0xFFF1F5F9),
        ),
      SellerServiceStatus.underReview => (
          '● Ditinjau Admin',
          const Color(0xFFB45309),
          const Color(0xFFFFF3C4),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
            isDestructive ? AppColors.danger : AppColors.textPrimary,
        backgroundColor:
            isDestructive ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  const _EmptyServices();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.border),
            SizedBox(height: 10),
            Text(
              'Belum ada jasa pada status ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(_ServiceFilter filter) {
  return switch (filter) {
    _ServiceFilter.all => 'Semua',
    _ServiceFilter.active => 'Aktif',
    _ServiceFilter.inactive => 'Nonaktif',
    _ServiceFilter.draft => 'Draft',
    _ServiceFilter.underReview => 'Ditinjau',
  };
}

String _statusLabel(SellerServiceStatus status) {
  return switch (status) {
    SellerServiceStatus.active => 'Aktif',
    SellerServiceStatus.inactive => 'Nonaktif',
    SellerServiceStatus.draft => 'Draft',
    SellerServiceStatus.underReview => 'Ditinjau Admin',
  };
}

Color _categoryColor(String category) {
  return switch (category) {
    'Desain' => const Color(0xFF9333EA),
    'Akademik' => const Color(0xFF16A34A),
    'Penulisan' => const Color(0xFFF59E0B),
    _ => AppColors.primary,
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Desain' => Icons.palette_outlined,
    'Akademik' => Icons.school_outlined,
    'Penulisan' => Icons.edit_note_outlined,
    _ => Icons.code,
  };
}
