import 'package:flutter/foundation.dart';

import 'service_catalog.dart';

enum OrderProgress {
  waitingSeller,
  inProgress,
  revision,
  completed,
  cancelled,
}

extension OrderProgressDetails on OrderProgress {
  double get fraction => switch (this) {
        OrderProgress.waitingSeller => 0.1,
        OrderProgress.inProgress => 0.45,
        OrderProgress.revision => 0.75,
        OrderProgress.completed => 1,
        OrderProgress.cancelled => 0,
      };

  int get percentage => (fraction * 100).round();

  String get label => switch (this) {
        OrderProgress.waitingSeller => 'Menunggu konfirmasi penjual',
        OrderProgress.inProgress => 'Sedang dikerjakan',
        OrderProgress.revision => 'Menunggu revisi',
        OrderProgress.completed => 'Selesai',
        OrderProgress.cancelled => 'Dibatalkan',
      };
}

class OrderPayment {
  const OrderPayment({
    required this.service,
    required this.brief,
    required this.paymentMethod,
    required this.total,
    this.transactionId,
    this.paidAt,
    this.progress = OrderProgress.waitingSeller,
    this.sellerUnread = false,
    this.buyerUnread = false,
  });

  final ServiceInfo service;
  final String brief;
  final String paymentMethod;
  final int total;
  final String? transactionId;
  final DateTime? paidAt;
  final OrderProgress progress;
  final bool sellerUnread;
  final bool buyerUnread;

  OrderPayment copyWith({
    String? transactionId,
    DateTime? paidAt,
    OrderProgress? progress,
    bool? sellerUnread,
    bool? buyerUnread,
  }) {
    return OrderPayment(
      service: service,
      brief: brief,
      paymentMethod: paymentMethod,
      total: total,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
      progress: progress ?? this.progress,
      sellerUnread: sellerUnread ?? this.sellerUnread,
      buyerUnread: buyerUnread ?? this.buyerUnread,
    );
  }
}

class BuyerOrderStore extends ChangeNotifier {
  BuyerOrderStore._();

  static final BuyerOrderStore instance = BuyerOrderStore._();

  final List<OrderPayment> _orders = [];

  List<OrderPayment> get orders => List.unmodifiable(_orders);

  int get sellerUnreadCount =>
      _orders.where((order) => order.sellerUnread).length;

  int get buyerUnreadCount =>
      _orders.where((order) => order.buyerUnread).length;

  OrderPayment confirmPayment(OrderPayment order) {
    final now = DateTime.now();
    final confirmedOrder = order.copyWith(
      transactionId: 'TRX-${now.millisecondsSinceEpoch.toString().substring(5)}',
      paidAt: now,
      sellerUnread: true,
    );
    _orders.insert(0, confirmedOrder);
    notifyListeners();
    return confirmedOrder;
  }

  void updateProgress(String? transactionId, OrderProgress progress) {
    final index = _orders.indexWhere(
      (order) => order.transactionId == transactionId,
    );
    if (index == -1 || _orders[index].progress == progress) {
      return;
    }

    _orders[index] = _orders[index].copyWith(
      progress: progress,
      buyerUnread: true,
    );
    notifyListeners();
  }

  void markSellerNotificationsRead() {
    _markNotificationsRead((order) => order.sellerUnread, (order) {
      return order.copyWith(sellerUnread: false);
    });
  }

  void markBuyerNotificationsRead() {
    _markNotificationsRead((order) => order.buyerUnread, (order) {
      return order.copyWith(buyerUnread: false);
    });
  }

  void _markNotificationsRead(
    bool Function(OrderPayment) isUnread,
    OrderPayment Function(OrderPayment) markRead,
  ) {
    var changed = false;
    for (var index = 0; index < _orders.length; index++) {
      if (isUnread(_orders[index])) {
        _orders[index] = markRead(_orders[index]);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}
