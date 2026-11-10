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
          final items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: _NavIconWithBadge(
                icon: Icons.chat_bubble_outline,
                count: unreadCount,
              ),
              activeIcon: _NavIconWithBadge(
                icon: Icons.chat_bubble,
                count: unreadCount,
              ),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];

          return BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: const Color(0xFF718096),
            selectedFontSize: 10,
            unselectedFontSize: 10,
            elevation: 0,
            showUnselectedLabels: true,
            onTap: (value) {
              switch (value) {
                case 0:
                  context.go('/beranda');
                  break;
                case 1:
                  context.go('/chat');
                  break;
                case 2:
                  context.go('/profil');
                  break;
              }
            },
            items: items,
          );
        },
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  const _NavIconWithBadge({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -6,
            right: -9,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
