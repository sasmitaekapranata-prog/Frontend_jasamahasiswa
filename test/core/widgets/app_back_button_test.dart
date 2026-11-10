import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jasa_mahasiswa/core/widgets/app_back_button.dart';

void main() {
  testWidgets('uses fallback when the current page is the navigation root', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Halaman utama')),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackLocation: '/'),
            ),
            body: const Text('Halaman detail'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Halaman detail'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Halaman utama'), findsOneWidget);
  });

  testWidgets('pops the existing page instead of using its fallback', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/detail'),
              child: const Text('Buka detail'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackLocation: '/fallback'),
            ),
            body: const Text('Halaman detail'),
          ),
        ),
        GoRoute(
          path: '/fallback',
          builder: (context, state) => const Scaffold(body: Text('Fallback')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Buka detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Buka detail'), findsOneWidget);
    expect(find.text('Fallback'), findsNothing);
  });
}
