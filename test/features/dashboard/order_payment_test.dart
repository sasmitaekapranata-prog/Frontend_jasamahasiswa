import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/order_payment.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/service_catalog.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/seller_wallet_store.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/user_role_controller.dart';

void main() {
  setUp(SellerWalletStore.instance.reset);
  setUp(BuyerOrderStore.instance.reset);

  test('order progress is reported as a percentage', () {
    expect(OrderProgress.waitingSeller.percentage, 10);
    expect(OrderProgress.inProgress.percentage, 45);
    expect(OrderProgress.revision.percentage, 75);
    expect(OrderProgress.completed.percentage, 100);
    expect(OrderProgress.cancelled.percentage, 0);
  });

  test('order notifications appear on events and clear when read', () {
    final store = BuyerOrderStore.instance;
    final startingSellerUnread = store.sellerUnreadCount;
    final startingBuyerUnread = store.buyerUnreadCount;

    final order = store.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
      ),
    );

    expect(store.sellerUnreadCount, startingSellerUnread + 1);
    expect(order.sellerUnread, isTrue);
    expect(store.unreadNotificationCount(UserRole.penjual), 1);
    expect(
      store.notificationsFor(UserRole.penjual).first.title,
      contains('Pesanan baru'),
    );
    expect(store.unreadNotificationCount(UserRole.pembeli), 1);
    expect(
      store.notificationsFor(UserRole.pembeli).first.title,
      'Pembayaran berhasil',
    );

    store.markSellerNotificationsRead();
    expect(store.sellerUnreadCount, startingSellerUnread);
    final sellerNotification = store.notificationsFor(UserRole.penjual).single;
    store.markNotificationRead(sellerNotification.id);
    expect(store.unreadNotificationCount(UserRole.penjual), 0);

    store.updateProgress(order.transactionId, OrderProgress.inProgress);
    expect(store.buyerUnreadCount, startingBuyerUnread + 1);
    expect(store.orders.first.progress, OrderProgress.inProgress);

    store.markBuyerNotificationsRead();
    expect(store.buyerUnreadCount, startingBuyerUnread);
    store.markAllNotificationsRead(UserRole.pembeli);
    expect(store.unreadNotificationCount(UserRole.pembeli), 0);
  });

  test('seller accepts, submits results, and buyer completes the order', () {
    final store = BuyerOrderStore.instance;
    final startingBalance = SellerWalletStore.instance.balance;
    final order = store.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
      ),
    );

    store.acceptOrder(order.transactionId);
    expect(store.orders.first.progress, OrderProgress.inProgress);
    expect(store.orders.first.buyerUnread, isTrue);
    expect(
      store.notificationsFor(UserRole.pembeli).any((notification) =>
          notification.kind == OrderNotificationKind.orderAccepted),
      isTrue,
    );

    final resultFile = OrderAttachment(
      name: 'hasil.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      size: 3,
    );
    store.submitOrderResult(order.transactionId, [resultFile]);
    expect(store.orders.first.progress, OrderProgress.revision);
    expect(store.orders.first.resultFiles.single.name, 'hasil.pdf');
    expect(
      store.notificationsFor(UserRole.pembeli).any((notification) =>
          notification.kind == OrderNotificationKind.resultSubmitted),
      isTrue,
    );

    store.requestOrderRevision(order.transactionId);
    expect(store.orders.first.progress, OrderProgress.inProgress);
    expect(store.orders.first.sellerUnread, isTrue);
    expect(
      store.notificationsFor(UserRole.penjual).any((notification) =>
          notification.kind == OrderNotificationKind.revisionRequested),
      isTrue,
    );

    store.submitOrderResult(order.transactionId, [resultFile]);
    store.completeOrder(order.transactionId);
    expect(store.orders.first.progress, OrderProgress.completed);
    expect(store.orders.first.resultFiles.single.name, 'hasil.pdf');
    expect(
      SellerWalletStore.instance.balance,
      startingBalance + order.total,
    );
    expect(
      store.notificationsFor(UserRole.penjual).any((notification) =>
          notification.kind == OrderNotificationKind.orderCompleted),
      isTrue,
    );
  });

  test('seller cannot submit a result without attaching a file', () {
    final order = BuyerOrderStore.instance.confirmPayment(
      OrderPayment(
        service: ServiceCatalog.services.first,
        brief: 'Buat landing page',
        paymentMethod: 'QRIS',
        total: 55000,
      ),
    );
    final store = BuyerOrderStore.instance;
    store.acceptOrder(order.transactionId);

    expect(
      () => store.submitOrderResult(order.transactionId, const []),
      throwsArgumentError,
    );
    expect(store.orders.first.progress, OrderProgress.inProgress);
  });
}
