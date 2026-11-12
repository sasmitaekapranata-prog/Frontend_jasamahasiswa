import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/beranda_screen.dart';

void main() {
  testWidgets('recommendation buttons do not open the chat page', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/beranda',
      routes: [
        GoRoute(
          path: '/beranda',
          builder: (_, __) => const BerandaScreen(),
        ),
        GoRoute(
          path: '/ai-recommendation',
          builder: (_, __) => const Scaffold(body: Text('Halaman Chat AI')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tanya Rekomendasi'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/beranda');
    expect(find.text('Halaman Chat AI'), findsNothing);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/beranda');
    expect(find.text('Halaman Chat AI'), findsNothing);
  });
}
