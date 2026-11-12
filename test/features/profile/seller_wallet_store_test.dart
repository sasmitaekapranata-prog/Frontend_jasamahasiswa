import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/seller_wallet_store.dart';

void main() {
  final wallet = SellerWalletStore.instance;

  setUp(wallet.reset);

  test('withdrawal deducts balance and records the transaction', () {
    final transaction = wallet.withdraw(amount: 500000, fee: 2500);

    expect(wallet.balance, 950000);
    expect(transaction.type, WalletTransactionType.withdrawal);
    expect(transaction.netAmount, 497500);
    expect(wallet.transactions, [transaction]);
  });

  test('withdrawal above available balance is rejected atomically', () {
    expect(
      () => wallet.withdraw(amount: 1450001, fee: 2500),
      throwsStateError,
    );

    expect(wallet.balance, SellerWalletStore.initialBalance);
    expect(wallet.transactions, isEmpty);
  });

  test('completed-order income is recorded once', () {
    final first = wallet.addIncome(
      amount: 75000,
      description: 'Pesanan desain',
      sourceId: 'ORDER-1',
    );
    final duplicate = wallet.addIncome(
      amount: 75000,
      description: 'Pesanan desain',
      sourceId: 'ORDER-1',
    );

    expect(duplicate, same(first));
    expect(wallet.balance, SellerWalletStore.initialBalance + 75000);
    expect(wallet.incomeLastSevenDays, 75000);
    expect(wallet.transactions, hasLength(1));
  });

  test('bank account changes remain masked in the wallet', () {
    wallet.updateBankAccount(
      bankName: 'Bank Mandiri',
      accountNumber: '1234567890',
      accountHolder: 'Dina',
    );

    expect(wallet.bankName, 'Bank Mandiri');
    expect(wallet.accountNumber, '1234 **** 7890');
    expect(wallet.accountNumberForEditing, '1234567890');
  });
}
