import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api_config.dart';
import '../../auth/services/order_service.dart';

enum WalletTransactionType { income, withdrawal }

class SellerWalletTransaction {
  const SellerWalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.fee,
    required this.createdAt,
    required this.description,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.status,
  });

  final String id;
  final WalletTransactionType type;
  final int amount;
  final int fee;
  final DateTime createdAt;
  final String description;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final String? status;

  int get netAmount =>
      type == WalletTransactionType.withdrawal ? amount - fee : amount;
}

class SellerWalletStore extends ChangeNotifier {
  SellerWalletStore._();

  static final SellerWalletStore instance = SellerWalletStore._();
  static const int initialBalance = 0;
  static const int minimumWithdrawal = 10000;

  int _balance = initialBalance;
  int _pendingBalance = 0;
  int _totalEarned = 0;
  bool _isLoading = false;
  String _bankName = 'Bank Central Asia (BCA)';
  String _rawAccountNumber = '781299019901';
  String _accountHolder = 'Mahasiswa';
  final List<SellerWalletTransaction> _transactions = [];

  int get balance => _balance;
  int get pendingBalance => _pendingBalance;
  int get totalEarned => _totalEarned;
  bool get isLoading => _isLoading;

  int get incomeLastSevenDays {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _transactions
        .where(
          (transaction) =>
              transaction.type == WalletTransactionType.income &&
              transaction.createdAt.isAfter(cutoff),
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  String get bankName => _bankName;
  String get accountNumber => _maskAccountNumber(_rawAccountNumber);
  String get accountNumberForEditing => _rawAccountNumber;
  String get accountHolder => _accountHolder;
  List<SellerWalletTransaction> get transactions =>
      List.unmodifiable(_transactions);

  Future<void> syncFromBackend() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final sellerId = await OrderService.getLoggedInUserId();
      final savedName = prefs.getString('nama');
      if (savedName != null && savedName.trim().isNotEmpty) {
        _accountHolder = savedName.trim();
      }
      final savedBank = prefs.getString('wallet_bank_name');
      final savedAccNum = prefs.getString('wallet_account_number');
      final savedAccHolder = prefs.getString('wallet_account_holder');
      if (savedBank != null && savedBank.isNotEmpty) _bankName = savedBank;
      if (savedAccNum != null && savedAccNum.isNotEmpty) {
        _rawAccountNumber = savedAccNum;
      }
      if (savedAccHolder != null && savedAccHolder.isNotEmpty) {
        _accountHolder = savedAccHolder;
      }

      final token = prefs.getString('token');
      final url = Uri.parse('${ApiConfig.baseUrl}/wallets/seller/$sellerId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? {};

        _balance = (double.tryParse(
                  data['available_balance']?.toString() ?? '0',
                ) ??
                0)
            .round();
        _pendingBalance = (double.tryParse(
                  data['pending_balance']?.toString() ?? '0',
                ) ??
                0)
            .round();
        _totalEarned = (double.tryParse(
                  data['total_earned']?.toString() ?? '0',
                ) ??
                0)
            .round();

        final List<dynamic> rawTxs = data['transactions'] ?? [];
        _transactions
          ..clear()
          ..addAll(
            rawTxs.map((raw) {
              final map = Map<String, dynamic>.from(raw);
              final isIncome = map['type']?.toString() == 'income';
              final amountInt = (double.tryParse(
                        map['amount']?.toString() ?? '0',
                      ) ??
                      0)
                  .round();
              final refCode = map['reference_code']?.toString() ??
                  'TX-${map['id'] ?? 0}';
              final title = map['title']?.toString() ??
                  (isIncome ? 'Pendapatan Jasa' : 'Penarikan Saldo');
              final counterpart = map['counterpart_name']?.toString() ?? '';

              return SellerWalletTransaction(
                id: refCode,
                type: isIncome
                    ? WalletTransactionType.income
                    : WalletTransactionType.withdrawal,
                amount: amountInt,
                fee: 0,
                createdAt:
                    DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                        DateTime.now(),
                description: counterpart.isNotEmpty
                    ? '$title ($counterpart)'
                    : title,
                bankName:
                    isIncome ? null : title.replaceFirst('Penarikan ke ', ''),
                accountNumber: isIncome ? null : counterpart,
                accountHolder: isIncome ? null : _accountHolder,
                status: map['status']?.toString() ?? 'berhasil',
              );
            }),
          );
      }
    } catch (e) {
      debugPrint('Error syncFromBackend wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SellerWalletTransaction> submitWithdrawToBackend({
    required int amount,
    required int fee,
  }) async {
    if (amount < minimumWithdrawal) {
      throw StateError(
        'Penarikan minimum adalah Rp $minimumWithdrawal.',
      );
    }
    if (amount > _balance) {
      throw StateError('Saldo tidak mencukupi untuk nominal tersebut.');
    }

    final prefs = await SharedPreferences.getInstance();
    final sellerId = await OrderService.getLoggedInUserId();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConfig.baseUrl}/wallets/withdraw');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'seller_id': sellerId,
        'amount': amount,
        'bank_or_ewallet': _bankName,
        'account_number': _rawAccountNumber,
        'account_name': _accountHolder,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw StateError(
        decoded['message']?.toString() ?? 'Gagal memproses penarikan dana.',
      );
    }

    final createdData = decoded['data'] ?? {};
    final wdId = createdData['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final transaction = SellerWalletTransaction(
      id: 'WD-${wdId.padLeft(5, '0')}',
      type: WalletTransactionType.withdrawal,
      amount: amount,
      fee: fee,
      createdAt: DateTime.now(),
      description: 'Penarikan ke $_bankName',
      bankName: _bankName,
      accountNumber: accountNumber,
      accountHolder: _accountHolder,
      status: createdData['status']?.toString() ?? 'pending',
    );

    await syncFromBackend();
    return transaction;
  }

  SellerWalletTransaction withdraw({
    required int amount,
    required int fee,
  }) {
    if (amount < minimumWithdrawal) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Penarikan minimum adalah Rp $minimumWithdrawal.',
      );
    }
    if (fee < 0 || fee > amount) {
      throw ArgumentError.value(fee, 'fee', 'Biaya penarikan tidak valid.');
    }
    if (amount > _balance) {
      throw StateError('Saldo tidak mencukupi untuk nominal tersebut.');
    }

    final now = DateTime.now();
    final transaction = SellerWalletTransaction(
      id: 'WD-${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}-'
          '${now.microsecondsSinceEpoch}',
      type: WalletTransactionType.withdrawal,
      amount: amount,
      fee: fee,
      createdAt: now,
      description: 'Penarikan saldo',
      bankName: _bankName,
      accountNumber: accountNumber,
      accountHolder: _accountHolder,
    );
    _balance -= amount;
    _transactions.insert(0, transaction);
    notifyListeners();
    return transaction;
  }

  SellerWalletTransaction addIncome({
    required int amount,
    required String description,
    required String sourceId,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Pemasukan harus lebih dari 0.');
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'ID sumber pemasukan wajib diisi.',
      );
    }
    if (_transactions.any((transaction) => transaction.id == sourceId)) {
      return _transactions.firstWhere(
        (transaction) => transaction.id == sourceId,
      );
    }

    final transaction = SellerWalletTransaction(
      id: sourceId,
      type: WalletTransactionType.income,
      amount: amount,
      fee: 0,
      createdAt: DateTime.now(),
      description: description,
    );
    _balance += amount;
    _transactions.insert(0, transaction);
    notifyListeners();
    return transaction;
  }

  Future<void> updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    _bankName = bankName;
    _rawAccountNumber = accountNumber;
    _accountHolder = accountHolder;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_bank_name', bankName);
    await prefs.setString('wallet_account_number', accountNumber);
    await prefs.setString('wallet_account_holder', accountHolder);
  }

  void clearSession() {
    reset();
  }

  @visibleForTesting
  void reset() {
    _balance = initialBalance;
    _pendingBalance = 0;
    _totalEarned = 0;
    _bankName = 'Bank Central Asia (BCA)';
    _rawAccountNumber = '781299019901';
    _accountHolder = 'Mahasiswa';
    _transactions.clear();
    notifyListeners();
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  return '${accountNumber.substring(0, 4)} **** '
      '${accountNumber.substring(accountNumber.length - 4)}';
}