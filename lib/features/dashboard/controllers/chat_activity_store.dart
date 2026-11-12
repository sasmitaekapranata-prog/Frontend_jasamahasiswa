import 'package:flutter/foundation.dart';

import '../../profile/controllers/user_role_controller.dart';

class ChatActivityStore extends ChangeNotifier {
  ChatActivityStore._();

  static final ChatActivityStore instance = ChatActivityStore._();

  final Map<UserRole, Set<String>> _unreadChats = {
    UserRole.pembeli: <String>{},
    UserRole.penjual: <String>{},
  };

  int unreadCount(UserRole role) => _unreadChats[role]?.length ?? 0;
  List<String> unreadChatIds(UserRole role) =>
      List.unmodifiable(_unreadChats[role] ?? const <String>{});

  bool isUnread(UserRole role, String chatId) =>
      _unreadChats[role]?.contains(chatId.toLowerCase()) ?? false;

  void markRead(UserRole role, String chatId) {
    if (_unreadChats[role]?.remove(chatId.toLowerCase()) ?? false) {
      notifyListeners();
    }
  }

  void markUnread(UserRole role, String chatId) {
    final chats = _unreadChats.putIfAbsent(role, () => <String>{});
    if (chats.add(chatId.toLowerCase())) {
      notifyListeners();
    }
  }

  void markAllRead(UserRole role) {
    final chats = _unreadChats[role];
    if (chats == null || chats.isEmpty) return;
    chats.clear();
    notifyListeners();
  }

  void markCounterpartUnread(UserRole senderRole, String chatId) {
    final receiverRole = senderRole == UserRole.penjual
        ? UserRole.pembeli
        : UserRole.penjual;
    final normalizedId = chatId.toLowerCase();
    final counterpartId = switch (normalizedId) {
      'ar' => 'bs',
      'bs' => 'ar',
      'sn' => 'aa',
      'aa' => 'sn',
      'dp' => 'rd',
      'rd' => 'dp',
      _ => normalizedId,
    };
    markUnread(receiverRole, counterpartId);
  }
}
