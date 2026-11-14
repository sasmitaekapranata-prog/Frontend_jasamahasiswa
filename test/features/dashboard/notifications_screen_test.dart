import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jasa_mahasiswa/app/routes/route_names.dart';
import 'package:jasa_mahasiswa/features/dashboard/controllers/chat_activity_store.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/beranda_screen.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/notifications_screen.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/order_payment.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/service_catalog.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/user_role_controller.dart';

void main() {
  final orderStore = BuyerOrderStore.instance;
  final chatStore = ChatActivityStore.instance;
  final roleController = UserRoleController.instance;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    orderStore.reset();
    chatStore
      ..markAllRead(UserRole.pembeli)
      ..markAllRead(UserRole.penjual);
    roleController.setRole(UserRole.penjual);
  });

  tearDown(() {
    roleController.setRole(UserRole.pembeli);
  });

  testWidgets('notification opens its order and marks it as read', (
    tester,
  ) async {
    final order = orderStore.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
        buyerName: 'Dina',
      ),
    );
    final router = GoRouter(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '${Routes.chatDetail}/:id',
          builder: (_, state) => Scaffold(
            body: Text(
              'Chat untuk ${(state.extra as OrderPayment).service.title}',
            ),
          ),
        ),
        GoRoute(
          path: Routes.beranda,
          builder: (_, __) => const Scaffold(body: Text('Beranda')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Pesanan baru dari Dina'), findsOneWidget);
    expect(orderStore.unreadNotificationCount(UserRole.penjual), 1);
    await tester.tap(find.text('Pesanan baru dari Dina'));
    await tester.pumpAndSettle();

    expect(find.text('Chat untuk ${order.service.title}'), findsOneWidget);
    expect(orderStore.unreadNotificationCount(UserRole.penjual), 0);
  });

  testWidgets('mark all read clears only current-role notification badge', (
    tester,
  ) async {
    orderStore.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
      ),
    );
    final router = GoRouter(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: Routes.beranda,
          builder: (_, __) => const Scaffold(body: Text('Beranda')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();

    expect(orderStore.unreadNotificationCount(UserRole.penjual), 0);
    expect(orderStore.unreadNotificationCount(UserRole.pembeli), 1);
  });

  testWidgets('unread chat notification opens the matching conversation', (
    tester,
  ) async {
    chatStore.markUnread(UserRole.penjual, 'ar');
    final router = GoRouter(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '${Routes.chatDetail}/:id',
          builder: (_, state) => Scaffold(
            body: Text('Percakapan ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: Routes.beranda,
          builder: (_, __) => const Scaffold(body: Text('Beranda')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Pesan baru dari Ahmad Rizky'), findsOneWidget);
    await tester.tap(find.text('Pesan baru dari Ahmad Rizky'));
    await tester.pumpAndSettle();

    expect(find.text('Percakapan ar'), findsOneWidget);
    expect(chatStore.unreadCount(UserRole.penjual), 0);
  });

  testWidgets('dashboard bell opens the notification inbox', (tester) async {
    roleController.setRole(UserRole.pembeli);
    orderStore.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
      ),
    );
    final router = GoRouter(
      initialLocation: Routes.beranda,
      routes: [
        GoRoute(
          path: Routes.beranda,
          builder: (_, __) => const BerandaScreen(),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.notifications);
    expect(find.text('Pembayaran berhasil'), findsOneWidget);
  });
}
