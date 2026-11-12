import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jasa_mahasiswa/app/routes/route_names.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/order_payment.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/user_role_controller.dart';
import 'package:jasa_mahasiswa/features/profile/presentation/profile_screen.dart';

void main() {
  final orderStore = BuyerOrderStore.instance;
  final roleController = UserRoleController.instance;

  setUp(() {
    orderStore.reset();
    roleController.setRole(UserRole.penjual);
  });

  tearDown(() {
    roleController.setRole(UserRole.pembeli);
  });

  testWidgets('notification bell is above withdraw button in balance card', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.profil,
      routes: [
        GoRoute(
          path: Routes.profil,
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (_, __) => const Scaffold(body: Text('Notifikasi')),
        ),
        GoRoute(
          path: Routes.withdrawSaldo,
          builder: (_, __) =>
              const Scaffold(body: Text('Riwayat & Tarik Saldo')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat & Tarik Saldo'), findsNothing);
    final notificationBell = find.byTooltip('Notifikasi');
    final withdrawButton = find.text('Tarik Saldo');
    expect(notificationBell, findsOneWidget);
    expect(
      tester.getTopLeft(notificationBell).dy,
      lessThan(tester.getTopLeft(withdrawButton).dy),
    );

    await tester.tap(notificationBell);
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path,
        Routes.notifications);
    router.go(Routes.profil);
    await tester.pumpAndSettle();
    await tester.tap(withdrawButton);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        Routes.withdrawSaldo);
    expect(find.text('Riwayat & Tarik Saldo'), findsOneWidget);
  });
}
