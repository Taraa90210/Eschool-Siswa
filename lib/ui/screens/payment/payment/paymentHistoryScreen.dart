import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/imageUtils.dart';
import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:eschool/data/models/payment/paymentMethod.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Bill bill;
  final String billName;

  const PaymentHistoryScreen({
    Key? key,
    required this.bill,
    required this.billName,
  }) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> paymentHistory = [];

  // String variables with Key suffix

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _animationController.forward();

    // Extract payment history from bill data
    // Convert PaymentHistory objects to Maps
    paymentHistory = widget.bill.paymentHistory.map((payment) {
      String finalMethodName = payment.paymentMethod ?? payment.method ?? '';

      // Fallback mapping if string is empty but ID exists
      if (finalMethodName.isEmpty && payment.paymentMethodId != null) {
        final matchedMethod =
            XenditPaymentMethod.getById(payment.paymentMethodId!);
        if (matchedMethod != null) {
          finalMethodName = matchedMethod.name;
        }
      }

      return <String, dynamic>{
        'status': payment.status ?? 'unknown',
        'amount': payment.amount?.toString() ?? '0',
        'date': payment.date ?? '',
        'payment_method': finalMethodName,
        'proof_image': payment.proofImage ?? '',
      };
    }).toList();

    // Sort by date (newest first)
    paymentHistory.sort((a, b) {
      final dateA = a['date'] != null && a['date'].isNotEmpty
          ? Utils.parseUtcDate(a['date'])
          : null;
      final dateB = b['date'] != null && b['date'].isNotEmpty
          ? Utils.parseUtcDate(b['date'])
          : null;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCurrency(String amountStr) {
    try {
      final amount = double.parse(amountStr);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (e) {
      return 'Rp $amountStr';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = Utils.parseUtcDate(dateString);
      if (date != null) {
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'rejected':
      case 'failed':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'rejected':
      case 'failed':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment, int index) {
    final String status =
        payment['status'] ?? Utils.getTranslatedLabel(unknownKey);
    final String amount = payment['amount'] ?? '0';
    final String date = payment['date'] ?? '';
    final String paymentMethod = payment['payment_method'] ?? '';
    final String proofImage = payment['proof_image'] ?? '';

    // Parse double values for admin fee check
    final double? parsedAdminFee =
        double.tryParse(payment['admin_fee_amount'] ?? '0');
    final bool hasAdminFee = parsedAdminFee != null && parsedAdminFee > 0;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Animate(
        effects: [
          FadeEffect(
            duration: Duration(milliseconds: 600),
            delay: Duration(milliseconds: 100 * index),
          ),
          SlideEffect(
            begin: Offset(0.3, 0),
            end: Offset.zero,
            duration: Duration(milliseconds: 700),
            delay: Duration(milliseconds: 100 * index),
            curve: Curves.easeOutCubic,
          ),
        ],
        child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status and date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.toLowerCase() == "pending"
                                    ? Utils.getTranslatedLabel(pendingKey)
                                    : status.toLowerCase() == "approved"
                                        ? Utils.getTranslatedLabel(approvedKey)
                                        : status.toLowerCase() == "rejected"
                                            ? Utils.getTranslatedLabel(
                                                rejectedKey)
                                            : Utils.getTranslatedLabel(
                                                unknownKey),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              Text(
                                date.isNotEmpty
                                    ? _formatDate(date)
                                    : Utils.getTranslatedLabel(noDateKey),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Payment details
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Amount
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: primaryColor.withValues(alpha: 0.8),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Utils.getTranslatedLabel(amountKey),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Spacer(),
                              Text(
                                _formatCurrency(amount),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),

                          // Admin Fee (if any)
                          if (hasAdminFee) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(width: 24), // Align with text
                                Text(
                                  "Biaya Admin",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatCurrency(
                                      payment['admin_fee_amount'] ?? '0'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Divider(color: primaryColor.withValues(alpha: 0.1)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(width: 24),
                                Text(
                                  "Total Pembayaran",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatCurrency(
                                      payment['total_amount'] ?? '0'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Payment Method
                          SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KIRI: ikon + label (label boleh wrap)
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment_rounded,
                                      size: 16,
                                      color:
                                          primaryColor.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        Utils.getTranslatedLabel(
                                            paymentMethodKey), // "Metode Pembayaran"
                                        softWrap: true,
                                        maxLines:
                                            null, // biar bisa lebih dari 1 baris
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // KANAN: chip nama bank (wrap & rata kanan)
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: constraints.maxWidth),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            paymentMethod.isNotEmpty
                                                ? paymentMethod // contoh: "Bank Syariah Indonesia"
                                                : Utils.getTranslatedLabel(
                                                    notSpecifiedKey),
                                            softWrap: true,
                                            maxLines:
                                                null, // boleh lebih dari 1 baris
                                            textAlign: TextAlign
                                                .right, // tetap “menempel” ke kanan
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: paymentMethod.isNotEmpty
                                                  ? primaryColor.withValues(
                                                      alpha: 0.9)
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Payment Proof Section with Image Display
                    SizedBox(height: 20),

                    if (proofImage.isNotEmpty) ...[
                      // Enhanced Image Preview Container
                      GestureDetector(
                        onTap: () => _showImageDialog(proofImage),
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CachedNetworkImage(
                                  imageUrl: proofImage,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 240,
                                  placeholder: (context, url) => Container(
                                    height: 240,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryColor.withValues(alpha: 0.1),
                                          primaryColor.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 240,
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          size: 64,
                                          color: primaryColor.withValues(
                                              alpha: 0.3),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          Utils.getTranslatedLabel(
                                              failedToLoadImageKey),
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Overlay gradient for better text visibility
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                              duration: 3000.ms,
                              color: primaryColor.withValues(alpha: 0.1)),
                    ],
                  ],
                ))));
  }

  void _showImageDialog(String imageUrl) {
    // Use the new ImageUtils for a better full-screen experience
    ImageUtils.showSingleImage(
      context: context,
      imageUrl: imageUrl,
      // imageName: "Payment Proof",
      showDownload: true,
      heroTag: "payment_proof",
    );
  }

  Widget _buildEmptyState() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Animate(
        effects: [
          FadeEffect(duration: Duration(milliseconds: 600)),
          ScaleEffect(duration: Duration(milliseconds: 600)),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 24),
            Text(
              Utils.getTranslatedLabel(noPaymentHistoryKey),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: 8),
            Text(
              Utils.getTranslatedLabel(noPaymentsMadeKey),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Content
          paymentHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarSmallerHeightPercentage,
                        ) +
                        20,
                    bottom: 30,
                    left: 20,
                    right: 20,
                  ),
                  itemCount: paymentHistory.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentHistoryItem(
                        paymentHistory[index], index);
                  },
                ),

          // App bar
          ScreenTopBackgroundContainer(
            heightPercentage: Utils.appBarSmallerHeightPercentage,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    left: 10,
                    top: -2,
                    child: const CustomBackButton(),
                  ),
                  Text(
                    Utils.getTranslatedLabel(paymentHistoryTitleKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        widget.billName,
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontSize: Utils.screenSubTitleFontSize,
                        ),
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
}
