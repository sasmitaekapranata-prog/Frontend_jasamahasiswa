import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api_config.dart';
import 'order_service.dart';

class ChatConversationItem {
  const ChatConversationItem({
    required this.counterpartId,
    required this.counterpartName,
    required this.counterpartDepartment,
    required this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
    this.latestOrderId,
    this.latestOrderCode,
    this.latestServiceTitle,
    this.latestOrderTotal,
    this.latestOrderStatus,
  });

  final int counterpartId;
  final String counterpartName;
  final String counterpartDepartment;
  final String lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final int? latestOrderId;
  final String? latestOrderCode;
  final String? latestServiceTitle;
  final int? latestOrderTotal;
  final String? latestOrderStatus;

  factory ChatConversationItem.fromJson(Map<String, dynamic> json) {
    return ChatConversationItem(
      counterpartId: int.tryParse(json['counterpart_id']?.toString() ?? '0') ?? 0,
      counterpartName: json['counterpart_name']?.toString() ?? 'Pengguna',
      counterpartDepartment:
          json['counterpart_department']?.toString() ?? 'Mahasiswa',
      lastMessage: (json['last_message']?.toString().trim().isNotEmpty ?? false)
          ? json['last_message'].toString()
          : (json['latest_service_title'] != null
              ? 'Pesanan: ${json['latest_service_title']}'
              : 'Mulai percakapan...'),
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
      latestOrderId: int.tryParse(json['latest_order_id']?.toString() ?? ''),
      latestOrderCode: json['latest_order_code']?.toString(),
      latestServiceTitle: json['latest_service_title']?.toString(),
      latestOrderTotal:
          double.tryParse(json['latest_order_total']?.toString() ?? '')
              ?.round(),
      latestOrderStatus: json['latest_order_status']?.toString(),
    );
  }
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    this.orderId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.createdAt,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final int? orderId;
  final String message;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final bool isRead;
  final DateTime? createdAt;

  static String? _resolveUrl(dynamic rawPath) {
    final s = rawPath?.toString().trim();
    if (s == null || s.isEmpty) return null;
    if (s.startsWith('http')) return s;
    final root = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$root$s';
  }

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      receiverId: int.tryParse(json['receiver_id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? ''),
      message: json['message']?.toString() ?? '',
      fileUrl: _resolveUrl(json['file_url']),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size']?.toString(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ChatService {
  static Future<List<ChatConversationItem>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await OrderService.getLoggedInUserId();
    final token = prefs.getString('token');

    final url = Uri.parse('${ApiConfig.baseUrl}/chats/conversations/$userId');
    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded['data'] ?? [];
      return rows
          .map(
            (e) =>
                ChatConversationItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return [];
  }

  static Future<List<ChatMessageItem>> getMessages(
    int counterpartId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await OrderService.getLoggedInUserId();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/chats/messages/$userId/$counterpartId',
    );
    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded['data'] ?? [];
      return rows
          .map(
            (e) => ChatMessageItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return [];
  }

  static Future<ChatMessageItem?> sendMessage({
    required int receiverId,
    int? orderId,
    String message = '',
    Uint8List? fileBytes,
    String? fileName,
    String? fileSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = await OrderService.getLoggedInUserId();
    final token = prefs.getString('token');

    String? base64Payload;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      base64Payload =
          'data:application/octet-stream;base64,${base64Encode(fileBytes)}';
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/chats/messages');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_id': orderId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'file_base64': base64Payload,
        'file_name': fileName,
        'file_size': fileSize,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['data'] != null) {
        return ChatMessageItem.fromJson(
          Map<String, dynamic>.from(decoded['data']),
        );
      }
    }
    return null;
  }
}