import 'package:eschool/cubits/xenditInvoiceCubit.dart';
import 'package:eschool/data/models/xenditInvoice.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class XenditPaymentScreen extends StatefulWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final List<int>? feeIds; // IDs of fees being paid

  const XenditPaymentScreen({
    Key? key,
    required this.invoice,
    required this.onPaymentSuccess,
    this.onPaymentFailed,
    this.feeIds,
  }) : super(key: key);

  @override
  State<XenditPaymentScreen> createState() => _XenditPaymentScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => XenditPaymentScreen(
        invoice: arguments['invoice'] as XenditInvoice,
        onPaymentSuccess: arguments['onPaymentSuccess'] as VoidCallback,
        onPaymentFailed: arguments['onPaymentFailed'] as VoidCallback?,
        feeIds: arguments['feeIds'] as List<int>?,
      ),
    );
  }
}

class _XenditPaymentScreenState extends State<XenditPaymentScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          // Intercept navigation to success/failed URLs
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            // Check if navigating to success URL
            if (url.contains('success') ||
                url.contains('completed') ||
                url.contains('paid')) {
              // Prevent navigation and handle success
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }

            // Check if navigating to failure URL
            if (url.contains('failed') ||
                url.contains('error') ||
                url.contains('cancel')) {
              // Prevent navigation and handle failure
              _handlePaymentFailed();
              return NavigationDecision.prevent;
            }

            // Allow navigation to Xendit checkout pages
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoice.invoiceUrl));
  }

  void _checkPaymentStatus() async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      await context
          .read<XenditInvoiceCubit>()
          .checkInvoiceStatus(widget.invoice.id);

      final state = context.read<XenditInvoiceCubit>().state;

      if (state is XenditInvoiceStatusUpdated) {
        if (state.invoice.isPaid) {
          _handlePaymentSuccess();
        } else if (state.invoice.isFailed) {
          _handlePaymentFailed();
        } else if (state.invoice.isExpired) {
          _showExpiredDialog();
        } else {
          _showPendingDialog();
        }
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _handlePaymentSuccess() async {
    // Call backend to confirm payment and update fee status
    await _confirmPaymentToBackend();

    Navigator.of(context).pop();
    widget.onPaymentSuccess();
  }

  /// Confirm payment to backend to update fee status
  Future<void> _confirmPaymentToBackend() async {
    if (widget.feeIds == null || widget.feeIds!.isEmpty) {
      print('No fee IDs provided, skipping backend confirmation');
      return;
    }

    try {
      final result = await Api.post(
        url: Api.confirmPayment,
        body: {
          'invoice_id': widget.invoice.id,
          'fee_ids': widget.feeIds,
          'payment_method': 'xendit',
          'status': 'paid',
          'amount': widget.invoice.amount,
          'transaction_id': widget.invoice.id,
        },
        useAuthToken: true,
      );

      if (kDebugMode) {
        print('Payment confirmation response: $result');
      }
    } catch (e) {
      // Log error but don't block success flow
      if (kDebugMode) {
        print('Error confirming payment to backend: $e');
      }
    }
  }

  void _handlePaymentFailed() {
    Navigator.of(context).pop();
    if (widget.onPaymentFailed != null) {
      widget.onPaymentFailed!();
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Utils.getTranslatedLabel('paymentPending')),
        content: Text(
          'Pembayaran Anda masih dalam proses. Silakan selesaikan pembayaran atau cek status nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Utils.getTranslatedLabel('okayKey')),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Invoice Kadaluarsa'),
        content: Text(
          'Invoice pembayaran telah kadaluarsa. Silakan buat invoice baru.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close payment screen
            },
            child: Text(Utils.getTranslatedLabel('okayKey')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Utils.getTranslatedLabel('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Utils.getTranslatedLabel('okayKey')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                // Refresh button
                Positioned(
                  right: 10,
                  top: -2,
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    onPressed: _isCheckingStatus ? null : _checkPaymentStatus,
                  ),
                ),
                // Screen title
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pembayaran via Xendit',
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Total: ${_formatCurrency(widget.invoice.amount)}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.12 + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (_isLoading || _isCheckingStatus)
                    Container(
                      color: Colors.white.withOpacity(0.8),
                      child: Center(
                        child: CustomCircularProgressIndicator(
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
