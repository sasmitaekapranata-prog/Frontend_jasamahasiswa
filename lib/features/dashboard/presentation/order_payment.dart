import 'package:flutter/foundation.dart';

import '../../profile/controllers/seller_wallet_store.dart';
import '../../profile/controllers/user_role_controller.dart';
import 'service_catalog.dart';

class OrderAttachment {
  const OrderAttachment({
    required this.name,
    required this.bytes,
    required this.size,
  });

  final String name;
  final Uint8List bytes;
  final int size;

  bool get isImage {
    final extension = name.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }
}

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
        OrderProgress.revision => 'Menunggu konfirmasi pembeli',
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
    this.attachments = const [],
    this.resultFiles = const [],
    this.buyerName = 'Pembeli',
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
  final List<OrderAttachment> attachments;
  final List<OrderAttachment> resultFiles;
  final String buyerName;
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
    List<OrderAttachment>? resultFiles,
  }) {
    return OrderPayment(
      service: service,
      brief: brief,
      paymentMethod: paymentMethod,
      total: total,
      attachments: attachments,
      resultFiles: resultFiles ?? this.resultFiles,
      buyerName: buyerName,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
      progress: progress ?? this.progress,
      sellerUnread: sellerUnread ?? this.sellerUnread,
      buyerUnread: buyerUnread ?? this.buyerUnread,
    );
  }
}

enum OrderNotificationKind {
  paymentReceived,
  newOrder,
  orderAccepted,
  resultSubmitted,
  revisionRequested,
  orderCompleted,
}

class OrderNotification {
  const OrderNotification({
    required this.id,
    required this.orderId,
    required this.audience,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String orderId;
  final UserRole audience;
  final OrderNotificationKind kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  OrderNotification copyWith({bool? isRead}) => OrderNotification(
        id: id,
        orderId: orderId,
        audience: audience,
        kind: kind,
        title: title,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

class BuyerOrderStore extends ChangeNotifier {
  BuyerOrderStore._();

  static final BuyerOrderStore instance = BuyerOrderStore._();

  final List<OrderPayment> _orders = [];
  final List<OrderNotification> _notifications = [];

  List<OrderPayment> get orders => List.unmodifiable(_orders);
  OrderPayment? orderForTransaction(String transactionId) {
    for (final order in _orders) {
      if (order.transactionId == transactionId) return order;
    }
    return null;
  }

  List<OrderNotification> notificationsFor(UserRole role) => List.unmodifiable(
        _notifications.where((notification) => notification.audience == role),
      );

  int unreadNotificationCount(UserRole role) => _notifications
      .where(
        (notification) => notification.audience == role && !notification.isRead,
      )
      .length;

  int get sellerUnreadCount =>
      _orders.where((order) => order.sellerUnread).length;

  int get buyerUnreadCount =>
      _orders.where((order) => order.buyerUnread).length;

  OrderPayment confirmPayment(OrderPayment order) {
    final now = DateTime.now();
    final confirmedOrder = order.copyWith(
      transactionId: 'TRX-${now.microsecondsSinceEpoch}',
      paidAt: now,
      sellerUnread: true,
    );
    _orders.insert(0, confirmedOrder);
    final orderId = confirmedOrder.transactionId!;
    _addNotification(
      orderId: orderId,
      audience: UserRole.penjual,
      kind: OrderNotificationKind.newOrder,
      title: 'Pesanan baru dari ${confirmedOrder.buyerName}',
      message: '${confirmedOrder.service.title} perlu segera dikonfirmasi.',
    );
    _addNotification(
      orderId: orderId,
      audience: UserRole.pembeli,
      kind: OrderNotificationKind.paymentReceived,
      title: 'Pembayaran berhasil',
      message: 'Pesanan ${confirmedOrder.service.title} menunggu penjual.',
    );
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

  void acceptOrder(String? transactionId) {
    final order = _findOrder(transactionId);
    _updateOrder(
      transactionId,
      expectedProgress: OrderProgress.waitingSeller,
      progress: OrderProgress.inProgress,
      sellerUnread: false,
      buyerUnread: true,
    );
    _addNotification(
      orderId: order.transactionId!,
      audience: UserRole.pembeli,
      kind: OrderNotificationKind.orderAccepted,
      title: 'Pesanan mulai dikerjakan',
      message: 'Penjual mulai mengerjakan ${order.service.title}.',
    );
    notifyListeners();
  }

  void submitOrderResult(
    String? transactionId,
    List<OrderAttachment> resultFiles,
  ) {
    if (resultFiles.isEmpty) {
      throw ArgumentError.value(
        resultFiles,
        'resultFiles',
        'Minimal satu file hasil harus dilampirkan.',
      );
    }
    final order = _findOrder(transactionId);
    _updateOrder(
      transactionId,
      expectedProgress: OrderProgress.inProgress,
      progress: OrderProgress.revision,
      resultFiles: List.unmodifiable(resultFiles),
      sellerUnread: false,
      buyerUnread: true,
    );
    _addNotification(
      orderId: order.transactionId!,
      audience: UserRole.pembeli,
      kind: OrderNotificationKind.resultSubmitted,
      title: 'Hasil pesanan siap diperiksa',
      message: 'Penjual mengirim hasil untuk ${order.service.title}.',
    );
    notifyListeners();
  }

  void requestOrderRevision(String? transactionId) {
    final order = _findOrder(transactionId);
    _updateOrder(
      transactionId,
      expectedProgress: OrderProgress.revision,
      progress: OrderProgress.inProgress,
      sellerUnread: true,
      buyerUnread: false,
    );
    _addNotification(
      orderId: order.transactionId!,
      audience: UserRole.penjual,
      kind: OrderNotificationKind.revisionRequested,
      title: 'Pembeli meminta revisi',
      message: 'Ada revisi untuk ${order.service.title}.',
    );
    notifyListeners();
  }

  void completeOrder(String? transactionId) {
    final order = _findOrder(transactionId);
    if (order.total <= 0) {
      throw StateError('Total pesanan harus lebih dari nol untuk pencairan.');
    }
    _updateOrder(
      transactionId,
      expectedProgress: OrderProgress.revision,
      progress: OrderProgress.completed,
      sellerUnread: true,
      buyerUnread: false,
    );
    _addNotification(
      orderId: order.transactionId!,
      audience: UserRole.penjual,
      kind: OrderNotificationKind.orderCompleted,
      title: 'Pesanan dikonfirmasi selesai',
      message: 'Pesanan ${order.service.title} telah diselesaikan.',
    );
    SellerWalletStore.instance.addIncome(
      amount: order.total,
      description: 'Pesanan ${order.service.title}',
      sourceId: 'ORDER-${order.transactionId}',
    );
    notifyListeners();
  }

  OrderPayment _findOrder(String? transactionId) {
    final index = _orders.indexWhere(
      (order) => order.transactionId == transactionId,
    );
    if (index == -1) {
      throw StateError('Pesanan yang akan diperbarui tidak ditemukan.');
    }
    return _orders[index];
  }

  void _updateOrder(
    String? transactionId, {
    required OrderProgress expectedProgress,
    required OrderProgress progress,
    required bool sellerUnread,
    required bool buyerUnread,
    List<OrderAttachment>? resultFiles,
  }) {
    final index = _orders.indexWhere(
      (order) => order.transactionId == transactionId,
    );
    if (index == -1) {
      throw StateError('Pesanan yang akan diperbarui tidak ditemukan.');
    }
    if (_orders[index].progress != expectedProgress) {
      throw StateError(
        'Status pesanan tidak sesuai untuk melakukan perubahan ini.',
      );
    }

    _orders[index] = _orders[index].copyWith(
      progress: progress,
      resultFiles: resultFiles,
      sellerUnread: sellerUnread,
      buyerUnread: buyerUnread,
    );
  }

  void markSellerNotificationsRead() {
    _markNotificationsRead(UserRole.penjual);
  }

  void markBuyerNotificationsRead() {
    _markNotificationsRead(UserRole.pembeli);
  }

  void markNotificationRead(String notificationId) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1 || _notifications[index].isRead) return;
    final notification = _notifications[index];
    _notifications[index] = notification.copyWith(isRead: true);
    final orderIndex = _orders.indexWhere(
      (order) => order.transactionId == notification.orderId,
    );
    if (orderIndex != -1) {
      final order = _orders[orderIndex];
      _orders[orderIndex] = notification.audience == UserRole.penjual
          ? order.copyWith(sellerUnread: false)
          : order.copyWith(buyerUnread: false);
    }
    notifyListeners();
  }

  void markAllNotificationsRead(UserRole role) {
    var changed = false;
    for (var index = 0; index < _notifications.length; index++) {
      final notification = _notifications[index];
      if (notification.audience == role && !notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
        changed = true;
      }
    }
    for (var index = 0; index < _orders.length; index++) {
      final order = _orders[index];
      if (role == UserRole.penjual && order.sellerUnread) {
        _orders[index] = order.copyWith(sellerUnread: false);
        changed = true;
      } else if (role == UserRole.pembeli && order.buyerUnread) {
        _orders[index] = order.copyWith(buyerUnread: false);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _orders.clear();
    _notifications.clear();
    notifyListeners();
  }

  void _addNotification({
    required String orderId,
    required UserRole audience,
    required OrderNotificationKind kind,
    required String title,
    required String message,
  }) {
    final notification = OrderNotification(
      id: '$orderId-${kind.name}-${DateTime.now().microsecondsSinceEpoch}',
      orderId: orderId,
      audience: audience,
      kind: kind,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notification);
  }

  void _markNotificationsRead(UserRole role) {
    var changed = false;
    for (var index = 0; index < _orders.length; index++) {
      final order = _orders[index];
      if (role == UserRole.penjual && order.sellerUnread) {
        _orders[index] = order.copyWith(sellerUnread: false);
        changed = true;
      } else if (role == UserRole.pembeli && order.buyerUnread) {
        _orders[index] = order.copyWith(buyerUnread: false);
        changed = true;
      }
    }
    for (var index = 0; index < _notifications.length; index++) {
      final notification = _notifications[index];
      if (notification.audience == role && !notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}
