import 'package:eschool/cubits/xenditInvoiceCubit.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:flutter/foundation.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/models/xenditInvoice.dart';
import 'package:eschool/ui/screens/payment/xenditPaymentScreen.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class XenditOnlyPaymentScreen extends StatefulWidget {
  final List<ChildFeeDetails> selectedFees;
  final double totalAmount;
  final Student child;

  const XenditOnlyPaymentScreen({
    Key? key,
    required this.selectedFees,
    required this.totalAmount,
    required this.child,
  }) : super(key: key);

  @override
  State<XenditOnlyPaymentScreen> createState() =>
      _XenditOnlyPaymentScreenState();
}

class _XenditOnlyPaymentScreenState extends State<XenditOnlyPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController.text =
        _formatCurrency(widget.totalAmount).replaceAll('Rp ', '');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  double _parseAmount(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanValue) ?? 0;
  }

  void _validateAmount(String value) {
    setState(() {
      final amount = _parseAmount(value);
      final maxAmount = widget.totalAmount;

      if (value.isEmpty) {
        _amountError = 'Masukkan nominal pembayaran';
      } else if (amount <= 0) {
        _amountError = 'Nominal harus lebih dari 0';
      } else if (amount > maxAmount) {
        _amountError =
            'Nominal melebihi sisa tagihan (${_formatCurrency(maxAmount)})';
      } else {
        _amountError = null;
      }
    });
  }

  bool _canProceedPayment() {
    final amount = _parseAmount(_amountController.text);
    return amount > 0 &&
        amount <= widget.totalAmount &&
        _amountError == null &&
        !_isProcessing;
  }

  Future<void> _processXenditPayment() async {
    if (!_canProceedPayment()) return;

    final amount = _parseAmount(_amountController.text);

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get parent/guardian email (Student model doesn't have email)
      final email = widget.child.guardian?.email ?? 'parent@example.com';

      // Create description
      final feeNames = widget.selectedFees.map((f) => f.name).join(', ');
      final description = 'Pembayaran: $feeNames - ${_formatCurrency(amount)}';

      // Get fee IDs
      final feeIds = widget.selectedFees.map((fee) => fee.id!).toList();

      // Create Xendit invoice
      await context.read<XenditInvoiceCubit>().createInvoice(
            schoolId: 1, // TODO: Get from school data
            studentId: widget.child.id!,
            amount: amount,
            email: email,
            description: description,
            feeIds: feeIds,
          );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleXenditSuccess(XenditInvoice invoice) async {
    // Save child ID before navigation
    final childId = widget.child.id ?? 0;

    // ⭐ Use await to get payment result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<XenditInvoiceCubit>(),
          child: XenditPaymentScreen(
            invoice: invoice,
            feeIds: widget.selectedFees
                .where((fee) => fee.id != null)
                .map((fee) => fee.id!)
                .toList(),
            onPaymentSuccess: () {
              // Pop back to fee list screen
              int popCount = 0;
              Navigator.of(context).popUntil((route) {
                popCount++;
                if (popCount >= 3) return true;
                if (route.settings.name?.contains('ChildFeesScreen') == true)
                  return true;
                return route.isFirst;
              });
            },
            onPaymentFailed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pembayaran gagal. Silakan coba lagi.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ),
    );

    // ⭐ After navigation completes, check result and refresh if successful
    if (result == true && mounted) {
      if (kDebugMode) {
        print('💚 Payment completed successfully, triggering refresh...');
      }

      // Trigger refresh in valid context
      try {
        context
            .read<ChildFeeDetailsCubit>()
            .fetchChildFeeDetails(childId: childId);

        if (kDebugMode) {
          print('✅ Fee details refreshed after payment');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not refresh fee details: $e');
        }
      }

      // Show success message
      if (mounted) {
        final snackBar = SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pembayaran berhasil!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(16),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _handleXenditFailure(String errorMessage) {
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal membuat invoice: $errorMessage'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<XenditInvoiceCubit, XenditInvoiceState>(
        listener: (context, state) {
          if (state is XenditInvoiceSuccess) {
            setState(() {
              _isProcessing = false;
            });
            _handleXenditSuccess(state.invoice);
          } else if (state is XenditInvoiceFailure) {
            _handleXenditFailure(state.errorMessage);
          }
        },
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                ScreenTopBackgroundContainer(
                  heightPercentage: 0.12,
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        left: 10,
                        top: -2,
                        child: CustomBackButton(),
                      ),
                      // Screen title
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Pembayaran via Xendit',
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Summary Card
                        _buildSummaryCard(),
                        SizedBox(height: 16),

                        // Amount Input Card
                        _buildAmountInputCard(),
                        SizedBox(height: 16),

                        // Fee Details Card
                        _buildFeeDetailsCard(),
                        SizedBox(height: 16),

                        // Xendit Info Card
                        _buildXenditInfoCard(),
                        SizedBox(height: 24),

                        // Payment Button
                        _buildPaymentButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Membuat invoice...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Ringkasan Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Siswa:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${widget.child.firstName ?? ''} ${widget.child.lastName ?? ''}'
                    .trim(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah Tagihan:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${widget.selectedFees.length} item',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                _formatCurrency(widget.totalAmount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Nominal Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Text(
            'Masukkan nominal yang ingin dibayarkan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              errorText: _amountError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
              if (cleanValue.isNotEmpty) {
                final amount = double.tryParse(cleanValue) ?? 0;
                final formatted = _formatCurrency(amount).replaceAll('Rp ', '');

                if (_amountController.text != formatted) {
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection:
                        TextSelection.collapsed(offset: formatted.length),
                  );
                }
              }
              _validateAmount(_amountController.text);
            },
          ),
          if (widget.totalAmount > 0) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maksimal:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _formatCurrency(widget.totalAmount),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeDetailsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Detail Tagihan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.selectedFees.map((fee) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fee.name ?? 'Biaya tidak diketahui',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCurrency(fee.remainingFeeAmountToPay()),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildXenditInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Tentang Pembayaran Xendit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.account_balance_wallet,
            text: 'Bayar dengan Virtual Account, E-wallet, atau QRIS',
          ),
          _buildInfoItem(
            icon: Icons.security,
            text: 'Transaksi aman dan terenkripsi',
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            text: 'Konfirmasi otomatis setelah pembayaran',
          ),
          _buildInfoItem(
            icon: Icons.receipt,
            text: 'Invoice berlaku 24 jam',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (!_isProcessing && _canProceedPayment())
            ? _processXenditPayment
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 24),
            SizedBox(width: 12),
            Text(
              'Lanjutkan ke Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
