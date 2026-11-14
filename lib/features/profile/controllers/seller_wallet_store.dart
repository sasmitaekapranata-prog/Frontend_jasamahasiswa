import 'package:flutter/foundation.dart';

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

  int get netAmount =>
      type == WalletTransactionType.withdrawal ? amount - fee : amount;
}

class SellerWalletStore extends ChangeNotifier {
  SellerWalletStore._();

  static final SellerWalletStore instance = SellerWalletStore._();
  static const int initialBalance = 1450000;
  static const int minimumWithdrawal = 50000;

  int _balance = initialBalance;
  String _bankName = 'Bank Central Asia (BCA)';
  String _rawAccountNumber = '781299019901';
  String _accountHolder = 'Alex Wijaya';
  final List<SellerWalletTransaction> _transactions = [];

  int get balance => _balance;
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

  void updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) {
    _bankName = bankName;
    _rawAccountNumber = accountNumber;
    _accountHolder = accountHolder;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _balance = initialBalance;
    _bankName = 'Bank Central Asia (BCA)';
    _rawAccountNumber = '781299019901';
    _accountHolder = 'Alex Wijaya';
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
