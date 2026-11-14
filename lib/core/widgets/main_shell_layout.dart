import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../features/dashboard/controllers/chat_activity_store.dart';
import '../../features/profile/controllers/user_role_controller.dart';

class MainShellLayout extends StatelessWidget {
  const MainShellLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = switch (location) {
      '/beranda' => 0,
      '/chat' => 1,
      '/profil' => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([
          UserRoleController.instance,
          ChatActivityStore.instance,
        ]),
        builder: (context, _) {
          final unreadCount = ChatActivityStore.instance.unreadCount(
            UserRoleController.instance.selectedRole,
          );
          return SafeArea(
            top: false,
            child: Container(
              key: const ValueKey('main-navigation-bar'),
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _NavigationItem(
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      selected: currentIndex == 0,
                      onTap: () => context.go('/beranda'),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      selected: currentIndex == 1,
                      unreadCount: unreadCount,
                      onTap: () => context.go('/chat'),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      label: 'Akun',
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      selected: currentIndex == 2,
                      onTap: () => context.go('/profil'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
    this.unreadCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          unreadCount > 0 ? '$label, $unreadCount pesan belum dibaca' : label,
      child: Center(
        child: Material(
          color: selected ? const Color(0xFFEEF5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 74,
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selected ? activeIcon : icon,
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFF718096),
                        size: 24,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -3,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFEEF5FF)
                                    : AppColors.surface,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF718096),
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
