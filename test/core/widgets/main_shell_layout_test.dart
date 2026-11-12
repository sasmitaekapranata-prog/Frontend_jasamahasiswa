import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jasa_mahasiswa/core/widgets/main_shell_layout.dart';

void main() {
  testWidgets('dashboard navigation matches the compact three-item layout', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/beranda',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShellLayout(child: child),
          routes: [
            GoRoute(
              path: '/beranda',
              builder: (_, __) => const Scaffold(body: Text('Halaman Beranda')),
            ),
            GoRoute(
              path: '/chat',
              builder: (_, __) => const Scaffold(body: Text('Halaman Chat')),
            ),
            GoRoute(
              path: '/profil',
              builder: (_, __) => const Scaffold(body: Text('Halaman Akun')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Beranda'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('main-navigation-bar'))).height,
      72,
    );

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Halaman Chat'), findsOneWidget);

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Halaman Akun'), findsOneWidget);
  });
}
