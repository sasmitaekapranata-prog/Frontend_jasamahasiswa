import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../controllers/seller_wallet_store.dart';

enum _TransactionFilter { all, income, withdrawal }

class WithdrawSaldoScreen extends StatefulWidget {
  const WithdrawSaldoScreen({super.key});

  @override
  State<WithdrawSaldoScreen> createState() => _WithdrawSaldoScreenState();
}

class _WithdrawSaldoScreenState extends State<WithdrawSaldoScreen> {
  static const _transferFee = 2500;

  final _amountController = TextEditingController(text: '1000000');
  final _wallet = SellerWalletStore.instance;
  _TransactionFilter _filter = _TransactionFilter.withdrawal;
  SellerWalletTransaction? _latestWithdrawal;
  bool _showSuccess = false;

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  int get _fee => _amount > 0 && _amount < 1500000 ? _transferFee : 0;

  int get _netAmount => (_amount - _fee).clamp(0, _amount).toInt();
  int get _balance => _wallet.balance;
  String get _bankName => _wallet.bankName;
  String get _accountNumber => _wallet.accountNumber;
  String get _editableAccountNumber => _wallet.accountNumberForEditing;
  String get _accountHolder => _wallet.accountHolder;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  void _setAmount(int amount) {
    _amountController.text = amount.toString();
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  String? _validateAmount() {
    if (_amount < SellerWalletStore.minimumWithdrawal) {
      return 'Minimal penarikan '
          '${Formatters.currency(SellerWalletStore.minimumWithdrawal)}.';
    }
    if (_amount > _balance) {
      return 'Saldo tidak mencukupi untuk nominal tersebut.';
    }
    return null;
  }

  Future<void> _confirmWithdrawal() async {
    final validationError = _validateAmount();
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final amount = _amount;
    final fee = _fee;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmWithdrawalSheet(
        amount: amount,
        fee: fee,
        netAmount: amount - fee,
        bankName: _bankName,
        accountNumber: _accountNumber,
        accountHolder: _accountHolder,
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final withdrawal = _wallet.withdraw(amount: amount, fee: fee);
      setState(() {
        _latestWithdrawal = withdrawal;
        _showSuccess = true;
      });
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    }
  }

  Future<void> _editBankAccount() async {
    final accountNameController = TextEditingController(text: _accountHolder);
    final accountNumberController = TextEditingController(
      text: _editableAccountNumber,
    );
    final formKey = GlobalKey<FormState>();
    var selectedBank = _bankName;

    final account = await showDialog<(String, String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rekening Tujuan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedBank,
                decoration: const InputDecoration(labelText: 'Bank'),
                items: const [
                  DropdownMenuItem(
                    value: 'Bank Central Asia (BCA)',
                    child: Text('Bank Central Asia (BCA)'),
                  ),
                  DropdownMenuItem(
                    value: 'Bank Mandiri',
                    child: Text('Bank Mandiri'),
                  ),
                  DropdownMenuItem(
                    value: 'Bank Negara Indonesia (BNI)',
                    child: Text('Bank Negara Indonesia (BNI)'),
                  ),
                  DropdownMenuItem(
                    value: 'Bank Rakyat Indonesia (BRI)',
                    child: Text('Bank Rakyat Indonesia (BRI)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) selectedBank = value;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 8
                    ? 'Masukkan nomor rekening yang valid'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accountNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama pemilik rekening wajib diisi'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                (
                  selectedBank,
                  accountNumberController.text.trim(),
                  accountNameController.text.trim(),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    accountNameController.dispose();
    accountNumberController.dispose();

    if (account == null || !mounted) return;
    setState(() {
      _wallet.updateBankAccount(
        bankName: account.$1,
        accountNumber: account.$2,
        accountHolder: account.$3,
      );
    });
  }

  void _showReceipt(SellerWalletTransaction withdrawal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReceiptSheet(
        withdrawal: withdrawal,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: withdrawal.id));
          Navigator.pop(sheetContext);
          _showMessage('ID transaksi berhasil disalin.');
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess && _latestWithdrawal != null) {
      return _WithdrawalSuccessScreen(
        withdrawal: _latestWithdrawal!,
        onShowReceipt: () => _showReceipt(_latestWithdrawal!),
        onBackToProfile: () {
          setState(() => _showSuccess = false);
          context.go(Routes.profil);
        },
      );
    }

    return AnimatedBuilder(
      animation: _wallet,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: Routes.profil),
          title: const Text(
            'Riwayat & Tarik Saldo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    _BalanceCard(
                      balance: _balance,
                      minimum: SellerWalletStore.minimumWithdrawal,
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Catatan Transaksi'),
                    const SizedBox(height: 8),
                    _TransactionFilters(
                      selected: _filter,
                      onChanged: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Rekening Tujuan'),
                    const SizedBox(height: 8),
                    _BankAccountCard(
                      bankName: _bankName,
                      accountNumber: _accountNumber,
                      accountHolder: _accountHolder,
                      onEdit: _editBankAccount,
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Nominal Penarikan'),
                    const SizedBox(height: 8),
                    _AmountInput(
                      controller: _amountController,
                      onClear: () => _setAmount(0),
                    ),
                    const SizedBox(height: 10),
                    _AmountPresets(
                      balance: _balance,
                      onSelected: _setAmount,
                    ),
                    if (_amount > _balance) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nominal melebihi saldo tersedia '
                        '(${Formatters.currency(_balance)}).',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionLabel('Rincian Transaksi'),
                    const SizedBox(height: 8),
                    _WithdrawalBreakdown(
                      amount: _amount,
                      fee: _fee,
                      netAmount: _netAmount,
                      remainingBalance:
                          (_balance - _amount).clamp(0, _balance).toInt(),
                    ),
                    const SizedBox(height: 12),
                    const _ProcessingNotice(),
                    const SizedBox(height: 18),
                    _TransactionHistory(
                      filter: _filter,
                      transactions: _wallet.transactions,
                      onWithdrawalTap: _showReceipt,
                    ),
                  ],
                ),
              ),
              _BottomAction(
                label: 'Konfirmasi & Tarik Saldo',
                onPressed: _confirmWithdrawal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.minimum});

  final int balance;
  final int minimum;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Siap Ditarik',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  Formatters.currency(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'Min. ${Formatters.currency(minimum)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF8493A8),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      ),
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.selected,
    required this.onChanged,
  });

  final _TransactionFilter selected;
  final ValueChanged<_TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_TransactionFilter.all, 'Semua'),
      (_TransactionFilter.income, 'Pemasukan'),
      (_TransactionFilter.withdrawal, 'Pencairan'),
    ];
    return Row(
      children: [
        for (final (filter, label) in filters) ...[
          Expanded(
            child: _FilterChip(
              label: label,
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
          ),
          if (filter != _TransactionFilter.withdrawal) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: selected ? Colors.white : AppColors.textSecondary,
          side: BorderSide(
            color: selected ? const Color(0xFF1E293B) : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.onEdit,
  });

  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _bankInitials(bankName),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accountNumber • a.n. $accountHolder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Status: Terverifikasi ✓',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit case final onEdit?)
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Ubah'),
            ),
        ],
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        prefixText: 'Rp  ',
        prefixStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          tooltip: 'Hapus nominal',
          onPressed: onClear,
          icon: const Icon(Icons.close, size: 18),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AmountPresets extends StatelessWidget {
  const _AmountPresets({
    required this.balance,
    required this.onSelected,
  });

  final int balance;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final presets = [
      (100000, 'Rp 100rb'),
      (500000, 'Rp 500rb'),
      (1000000, 'Rp 1jt'),
      (balance, 'Tarik Semua'),
    ];
    return Row(
      children: [
        for (var index = 0; index < presets.length; index++) ...[
          Expanded(
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: () => onSelected(presets[index].$1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(presets[index].$2),
                ),
              ),
            ),
          ),
          if (index != presets.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _WithdrawalBreakdown extends StatelessWidget {
  const _WithdrawalBreakdown({
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.remainingBalance,
  });

  final int amount;
  final int fee;
  final int netAmount;
  final int remainingBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Jumlah Penarikan',
            value: Formatters.currency(amount),
            emphasized: true,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Biaya Admin Transfer',
            value: fee == 0 ? 'Gratis (Rp 0)' : Formatters.currency(fee),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _DetailRow(
            label: 'Total Diterima di Rekening',
            value: Formatters.currency(netAmount),
            emphasized: true,
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sisa saldo setelah penarikan: ${Formatters.currency(remainingBalance)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  emphasized ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 10,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingNotice extends StatelessWidget {
  const _ProcessingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Color(0xFFD97706), size: 15),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Proses pencairan membutuhkan 1–2 hari kerja (Senin–Jumat).',
              style: TextStyle(
                color: Color(0xFF9A5A00),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionHistory extends StatelessWidget {
  const _TransactionHistory({
    required this.filter,
    required this.transactions,
    required this.onWithdrawalTap,
  });

  final _TransactionFilter filter;
  final List<SellerWalletTransaction> transactions;
  final ValueChanged<SellerWalletTransaction> onWithdrawalTap;

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = transactions.where((transaction) {
      return switch (filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.income =>
          transaction.type == WalletTransactionType.income,
        _TransactionFilter.withdrawal =>
          transaction.type == WalletTransactionType.withdrawal,
      };
    }).toList();
    if (visibleTransactions.isEmpty) {
      final message = switch (filter) {
        _TransactionFilter.all => 'Belum ada transaksi.',
        _TransactionFilter.income => 'Belum ada catatan pemasukan.',
        _TransactionFilter.withdrawal => 'Belum ada catatan penarikan.',
      };
      return _HistoryEmpty(
        message: message,
        icon: filter == _TransactionFilter.income
            ? Icons.south_west
            : Icons.receipt_long_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Riwayat Transaksi'),
        const SizedBox(height: 8),
        for (final transaction in visibleTransactions) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: transaction.type == WalletTransactionType.withdrawal
                  ? () => onWithdrawalTap(transaction)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor:
                          transaction.type == WalletTransactionType.income
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFFF1F2),
                      child: Icon(
                        transaction.type == WalletTransactionType.income
                            ? Icons.south_west
                            : Icons.north_east,
                        color: transaction.type == WalletTransactionType.income
                            ? AppColors.success
                            : AppColors.danger,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${Formatters.shortDate(transaction.createdAt)} • '
                            '${transaction.type == WalletTransactionType.income ? 'Berhasil' : 'Menunggu proses'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${transaction.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${transaction.type == WalletTransactionType.income ? '+' : '-'}'
                      '${Formatters.currency(transaction.amount)}',
                      style: TextStyle(
                        color: transaction.type == WalletTransactionType.income
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ConfirmWithdrawalSheet extends StatelessWidget {
  const _ConfirmWithdrawalSheet({
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  final int amount;
  final int fee;
  final int netAmount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Konfirmasi Penarikan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Nominal penarikan',
                value: Formatters.currency(amount),
                emphasized: true,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'Biaya admin',
                value: Formatters.currency(fee),
              ),
              const Divider(height: 22),
              _DetailRow(
                label: 'Diterima di rekening',
                value: Formatters.currency(netAmount),
                emphasized: true,
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Bank', value: bankName),
              const SizedBox(height: 7),
              _DetailRow(label: 'Nomor rekening', value: accountNumber),
              const SizedBox(height: 7),
              _DetailRow(label: 'Nama penerima', value: accountHolder),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Konfirmasi Penarikan'),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Periksa kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawalSuccessScreen extends StatelessWidget {
  const _WithdrawalSuccessScreen({
    required this.withdrawal,
    required this.onShowReceipt,
    required this.onBackToProfile,
  });

  final SellerWalletTransaction withdrawal;
  final VoidCallback onShowReceipt;
  final VoidCallback onBackToProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: Routes.profil),
        title: const Text(
          'Detail Penarikan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                children: [
                  const _SuccessHeader(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const _SectionLabel('Total Penarikan'),
                        const SizedBox(height: 7),
                        Text(
                          Formatters.currency(withdrawal.amount),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Rincian Rekening Tujuan'),
                        const SizedBox(height: 10),
                        _BankAccountCard(
                          bankName: withdrawal.bankName ?? '',
                          accountNumber: withdrawal.accountNumber ?? '',
                          accountHolder: withdrawal.accountHolder ?? '',
                        ),
                        const SizedBox(height: 16),
                        const _SectionLabel('Rincian Transaksi'),
                        const SizedBox(height: 10),
                        _DetailRow(
                          label: 'ID Transaksi',
                          value: withdrawal.id,
                        ),
                        const SizedBox(height: 9),
                        _DetailRow(
                          label: 'Waktu transaksi',
                          value:
                              '${Formatters.shortDate(withdrawal.createdAt)}, '
                              '${TimeOfDay.fromDateTime(withdrawal.createdAt).format(context)}',
                        ),
                        const SizedBox(height: 9),
                        _DetailRow(
                          label: 'Nominal penarikan',
                          value: Formatters.currency(withdrawal.amount),
                        ),
                        const SizedBox(height: 9),
                        _DetailRow(
                          label: 'Biaya admin',
                          value: withdrawal.fee == 0
                              ? 'Gratis (Rp 0)'
                              : Formatters.currency(withdrawal.fee),
                          valueColor: AppColors.success,
                        ),
                        const Divider(height: 22),
                        _DetailRow(
                          label: 'Status',
                          value: 'Menunggu proses',
                          emphasized: true,
                          valueColor: const Color(0xFFB45309),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Permintaan tercatat di perangkat ini. Proses transfer '
                          'bank memerlukan integrasi backend.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Jaga kerahasiaan informasi rekening Anda.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onShowReceipt,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Lihat Resi / Bukti Transfer'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: onBackToProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Kembali ke Profil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.check, color: AppColors.success, size: 29),
        ),
        SizedBox(height: 11),
        Text(
          'Permintaan Penarikan Dicatat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Permintaan Anda menunggu pemrosesan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({
    required this.withdrawal,
    required this.onCopy,
  });

  final SellerWalletTransaction withdrawal;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rincian Resi Penarikan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'PENARIKAN SALDO',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.currency(withdrawal.amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Bank tujuan',
                    value: withdrawal.bankName ?? '-',
                  ),
                  const SizedBox(height: 9),
                  _DetailRow(
                    label: 'Nomor rekening',
                    value: withdrawal.accountNumber ?? '-',
                  ),
                  const SizedBox(height: 9),
                  _DetailRow(
                    label: 'Nama penerima',
                    value: withdrawal.accountHolder ?? '-',
                  ),
                  const SizedBox(height: 9),
                  _DetailRow(label: 'ID transaksi', value: withdrawal.id),
                  const SizedBox(height: 9),
                  _DetailRow(
                    label: 'Status',
                    value: 'Menunggu proses',
                    valueColor: const Color(0xFFB45309),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin ID Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _bankInitials(String bankName) {
  final name = bankName
      .replaceAll(RegExp(r'\([^)]*\)'), '')
      .trim()
      .split(RegExp(r'\s+'));
  if (name.length == 1) {
    return name.first
        .substring(0, name.first.length.clamp(1, 3).toInt())
        .toUpperCase();
  }
  return '${name[0][0]}${name[1][0]}'.toUpperCase();
}
