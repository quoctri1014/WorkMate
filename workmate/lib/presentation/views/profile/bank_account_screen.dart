import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/models/models.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  static const List<String> _allBanks = [
    'Agribank', 'Vietcombank', 'VietinBank', 'BIDV', 'GP Bank', 'CB Bank', 'Oceanbank', 'VBSP', 'VDB',
    'MBBank', 'Techcombank', 'VPBank', 'ACB', 'Sacombank', 'HDBank', 'TPBank', 'SHB', 'VIB', 'Vietbank', 
    'OCB', 'MSB', 'SeABank', 'Bac A Bank', 'Kienlongbank', 'Saigonbank', 'BVBank', 'PVcomBank', 'NCB', 
    'ABBANK', 'PGBank', 'Eximbank', 'BAOVIET Bank', 'Nam A Bank',
    'HSBC Việt Nam', 'Standard Chartered', 'Shinhan Bank', 'UOB Việt Nam', 'ANZ Việt Nam', 'Indovina Bank', 'VRB',
    'Cake by VPBank', 'Timo', 'Ubank'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final accounts = homeVm.user?.bankAccounts ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Tài khoản ngân hàng', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, fontSize: 17)),
        actions: [
          if (accounts.length < 3)
            IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28), onPressed: () => _showBankForm(context, homeVm)),
        ],
      ),
      body: accounts.isEmpty
          ? _buildEmpty(context, homeVm)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: accounts.length,
              itemBuilder: (ctx, i) => _BankCard(
                account: accounts[i],
                onEdit: () => _showBankForm(context, homeVm, accounts[i]),
                onDelete: () => _confirmDelete(context, homeVm, accounts[i].id),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, HomeViewModel vm) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.primarySurface, borderRadius: BorderRadius.circular(24)),
      child: Icon(Icons.account_balance_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary, size: 40)),
    const SizedBox(height: 20),
    Text('Chưa có tài khoản ngân hàng', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
    const SizedBox(height: 8),
    Text('Thêm tối đa 3 tài khoản để nhận lương', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height: 24),
    ElevatedButton.icon(
      onPressed: () => _showBankForm(context, vm),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Thêm tài khoản ngay'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)
      ),
    )
  ]));

  void _confirmDelete(BuildContext context, HomeViewModel vm, int bankId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text('Bạn có chắc muốn xóa tài khoản ngân hàng này?', style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          TextButton(onPressed: () { Navigator.pop(ctx); vm.deleteBank(bankId); }, child: const Text('Xóa ngay', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _showBankForm(BuildContext context, HomeViewModel vm, [BankAccount? account]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BankFormDialog(
        account: account,
        allBanks: _allBanks,
        onSave: (data) {
          if (account == null) {
            vm.addBank(data);
          } else {
            vm.updateBank(account.id, data);
          }
        },
      ),
    );
  }
}

class _BankFormDialog extends StatefulWidget {
  final BankAccount? account;
  final List<String> allBanks;
  final Function(Map<String, dynamic>) onSave;

  const _BankFormDialog({this.account, required this.allBanks, required this.onSave});

  @override
  State<_BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<_BankFormDialog> {
  final _bankCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _bankError;
  String? _numberError;
  String? _nameError;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _bankCtrl.text = widget.account!.bankName;
      _numberCtrl.text = widget.account!.accountNumber;
      _nameCtrl.text = widget.account!.accountHolder;
    }
  }

  void _validateAndSave() {
    setState(() {
      _bankError = widget.allBanks.contains(_bankCtrl.text) ? null : 'Vui lòng chọn ngân hàng từ danh sách';
      _numberError = _numberCtrl.text.length >= 6 && RegExp(r'^\d+$').hasMatch(_numberCtrl.text) ? null : 'Số tài khoản không hợp lệ (chỉ nhập số)';
      _nameError = _nameCtrl.text.length >= 3 ? null : 'Vui lòng nhập tên chủ tài khoản';
    });

    if (_bankError == null && _numberError == null && _nameError == null) {
      widget.onSave({
        'bank_name': _bankCtrl.text,
        'account_number': _numberCtrl.text,
        'account_holder': _nameCtrl.text.toUpperCase(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(28),
          border: Theme.of(context).brightness == Brightness.dark 
            ? Border.all(color: Colors.white.withOpacity(0.05)) 
            : null
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.account == null ? 'Thêm tài khoản' : 'Sửa tài khoản', 
              style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 24),
            
            // Bank Name with Search
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ngân hàng', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: _bankCtrl,
                onChanged: (val) {
                  setState(() {
                    if (val.isEmpty) {
                      _suggestions = [];
                      _showSuggestions = false;
                    } else {
                      _suggestions = widget.allBanks.where((b) => b.toLowerCase().contains(val.toLowerCase())).toList();
                      _showSuggestions = true;
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Chọn hoặc tìm ngân hàng...',
                  filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.background,
                  errorText: _bankError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              ),
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)), boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppColors.cardShadow),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (ctx, i) => ListTile(
                      dense: true,
                      title: Text(_suggestions[i], style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      onTap: () {
                        setState(() {
                          _bankCtrl.text = _suggestions[i];
                          _showSuggestions = false;
                        });
                      },
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),

            // Account Number
            _buildField('Số tài khoản', _numberCtrl, 'Nhập số tài khoản...', _numberError, TextInputType.number),
            const SizedBox(height: 16),

            // Account Holder
            _buildField('Tên chủ tài khoản', _nameCtrl, 'VD: NGUYEN VAN A', _nameError, TextInputType.text, true),
            
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Hủy', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _validateAndSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Xác nhận', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              )),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, String? error, TextInputType type, [bool allCaps = false]) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        onChanged: (val) {
          if (allCaps) {
            ctrl.value = ctrl.value.copyWith(text: val.toUpperCase(), selection: TextSelection.collapsed(offset: val.length));
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.background,
          errorText: error,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
      ),
    ]);
  }
}

class _BankCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BankCard({required this.account, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppColors.cardShadow),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.account_balance_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.bankName, style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              Text(account.accountHolder, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
            ])),
          ]),
          const SizedBox(height: 20),
          Text(account.accountNumber, style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1.5)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.02) : AppColors.background, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Sửa'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : AppColors.primary, textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13))),
          TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 16), label: const Text('Xóa'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.red[300] : AppColors.error, textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      )
    ]),
  );
}
