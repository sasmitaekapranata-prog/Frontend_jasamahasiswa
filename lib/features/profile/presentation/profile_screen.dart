import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/controllers/chat_activity_store.dart';
import '../../dashboard/presentation/order_payment.dart';
import '../controllers/seller_profile_store.dart';
import '../controllers/seller_wallet_store.dart';
import '../controllers/user_role_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _roleController = UserRoleController.instance;

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.danger,
                size: 25,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keluar dari Akun?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kamu harus masuk kembali untuk memesan jasa atau mengelola transaksi kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Ya, Keluar Akun',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldSignOut == true && mounted) {
      context.go(Routes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerProfile = SellerProfileStore.instance;
    final sellerWallet = SellerWalletStore.instance;
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _roleController,
            BuyerOrderStore.instance,
            ChatActivityStore.instance,
            sellerProfile,
            sellerWallet,
          ]),
          builder: (context, _) {
            final isSeller = _roleController.selectedRole == UserRole.penjual;
            final orderStore = BuyerOrderStore.instance;
            final notificationCount =
                orderStore.unreadNotificationCount(_roleController.selectedRole) +
                ChatActivityStore.instance
                    .unreadCount(_roleController.selectedRole);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _BrandHeader(),
                const SizedBox(height: 14),
                _ProfileCard(
                  isSeller: isSeller,
                  profile: sellerProfile,
                ),
                const SizedBox(height: 10),
                _RoleSwitcher(
                  isSeller: isSeller,
                  onRoleChanged: (role) => _roleController.setRole(role),
                ),
                const SizedBox(height: 12),
                if (isSeller) ...[
                  _BalanceCard(
                    balance: sellerWallet.balance,
                    weeklyIncome: sellerWallet.incomeLastSevenDays,
                    unreadNotifications: notificationCount,
                    onNotifications: () => context.push(Routes.notifications),
                    onWithdraw: () => context.go(Routes.withdrawSaldo),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: () => context.push(Routes.createService),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buka Penawaran Jasa Baru'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OptionsCard(
                    options: [
                      _ProfileOption(
                        title: 'Edit Profil',
                        subtitle: 'Edit Profil dan data diri kamu',
                        onTap: () =>
                            context.go(Routes.editProfile, extra: isSeller),
                      ),
                      _ProfileOption(
                        title: 'Pesanan Masuk',
                        subtitle: 'Perlu Segera kamu kerjakan',
                        badge: orderStore.sellerUnreadCount == 0
                            ? null
                            : '${orderStore.sellerUnreadCount}',
                        onTap: () => context.go(Routes.incomingOrders),
                      ),
                      _ProfileOption(
                        title: 'Kelola Jasa',
                        subtitle: 'Edit Jasa dan Hapus',
                        onTap: () => context.go(Routes.manageServices),
                      ),
                    ],
                  ),
                ] else ...[
                  _OptionsCard(
                    options: [
                      _ProfileOption(
                        title: 'Edit Profil',
                        subtitle: 'Edit Profil dan Data Diri Kamu',
                        onTap: () =>
                            context.go(Routes.editProfile, extra: isSeller),
                      ),
                      _ProfileOption(
                        title: 'Pesanan Saya',
                        badge: orderStore.buyerUnreadCount == 0
                            ? null
                            : '${orderStore.buyerUnreadCount}',
                        onTap: () => context.go(Routes.statusPesanan),
                      ),
                      _ProfileOption(
                        title: 'Pusat Bantuan',
                        onTap: () => context.push(Routes.helpCenter),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 56),
                OutlinedButton(
                  onPressed: _confirmSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFFFE5E5)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _BrandIcon(),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jasa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              'Mahasiswa',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.school_outlined, color: Colors.white, size: 26),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.isSeller,
    required this.profile,
  });

  final bool isSeller;
  final SellerProfileStore profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFFDCEAFF),
              backgroundImage: profile.photoBytes == null
                  ? null
                  : MemoryImage(profile.photoBytes!),
              child: profile.photoBytes == null
                  ? Text(
                      profile.name
                          .split(RegExp(r'\s+'))
                          .where((part) => part.isNotEmpty)
                          .take(2)
                          .map((part) => part[0].toUpperCase())
                          .join(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.program,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSeller
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFE5EEFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isSeller ? '● Lapak Siap Terima' : '✓ Mahasiswa Aktif',
                    style: TextStyle(
                      color: isSeller ? AppColors.success : AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  const _RoleSwitcher({required this.isSeller, required this.onRoleChanged});

  final bool isSeller;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _RoleButton(
            title: 'Mode Pembeli',
            selected: !isSeller,
            onTap: () => onRoleChanged(UserRole.pembeli),
          ),
          _RoleButton(
            title: 'Mode Penjual',
            selected: isSeller,
            onTap: () => onRoleChanged(UserRole.penjual),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 34,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: selected ? AppColors.primary : Colors.transparent,
            foregroundColor: selected ? Colors.white : AppColors.textSecondary,
            elevation: 0,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(title),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.weeklyIncome,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onWithdraw,
  });

  final int balance;
  final int weeklyIncome;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SALDO PENDAPATAN JASA',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  Formatters.currency(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '▲ +${Formatters.currency(weeklyIncome)} minggu ini',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 32,
                child: IconButton(
                  tooltip: 'Notifikasi',
                  onPressed: onNotifications,
                  padding: EdgeInsets.zero,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 19,
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          top: -5,
                          right: -6,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadNotifications > 9
                                  ? '9+'
                                  : '$unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FilledButton(
                onPressed: onWithdraw,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Tarik Saldo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.options});

  final List<_ProfileOption> options;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              _OptionTile(option: options[index]),
              if (index != options.length - 1)
                const Divider(height: 1, color: Color(0xFFF0F2F5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final _ProfileOption option;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.badge != null)
              Container(
                margin: const EdgeInsets.only(right: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  option.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption {
  const _ProfileOption({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;
}
