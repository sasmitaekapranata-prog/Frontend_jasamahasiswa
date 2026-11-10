import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/order_payment.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/service_catalog.dart';

void main() {
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

    store.markSellerNotificationsRead();
    expect(store.sellerUnreadCount, startingSellerUnread);

    store.updateProgress(order.transactionId, OrderProgress.inProgress);
    expect(store.buyerUnreadCount, startingBuyerUnread + 1);
    expect(store.orders.first.progress, OrderProgress.inProgress);

    store.markBuyerNotificationsRead();
    expect(store.buyerUnreadCount, startingBuyerUnread);
  });
}
