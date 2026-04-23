import 'package:eschool/cubits/payment/paymentTransactionsCubit.dart';
import 'package:eschool/data/repositories/payment/paymentRepository.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/utils/system/api.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentTransactionsCubit>(
          create: (_) => PaymentTransactionsCubit(PaymentRepository()),
        ),
      ],
      child: const TransactionsScreen(),
    );
  }

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final softRedColor = Color(0xFFE57373);

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    super.initState();
    Future.delayed(Duration.zero, () {
      // context.read<PaymentTransactionsCubit>().fetchPaymentTransactions();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange; // Orange untuk pending
      case 'approved':
      case 'disetujui':
        return Colors.green; // Hijau untuk disetujui
      case 'rejected':
      case 'ditolak':
        return Colors.red; // Merah untuk ditolak
      case 'succeed':
        return Colors.green;
      case 'failed':
        return softRedColor;
      default:
        return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5);
    }
  }

  Widget _buildTransactionCard(dynamic paymentGroup, int index) {
    final payments = paymentGroup['payments'] as List;
    final totalAmount = paymentGroup['total_amount'] ?? 0;
    final proofImageUrl = paymentGroup['proof_image_url'] ?? '';

    // Get the first payment for common data like date, status
    final firstPayment = payments.isNotEmpty ? payments[0] : {};
    final status = firstPayment['status'] ?? '';
    final statusColor = _getStatusColor(status);
    final createdAt = firstPayment['created_at'] ?? '';

    return Animate(
      effects: [
        FadeEffect(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ),
        SlideEffect(
          begin: Offset(0.2, 0),
          end: Offset.zero,
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuint,
        ),
      ],
      autoPlay: true,
      onComplete: (controller) => controller.stop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _showPaymentDetails(paymentGroup);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Payment count badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${payments.length} Pembayaran",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Date and time
                      if (createdAt.isNotEmpty) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Utils.formatDate(DateTime.parse(createdAt).toLocal()),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          DateFormat('HH:mm', 'id_ID').format(
                            DateTime.parse(createdAt).toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fee names (show up to 2, then "and X more")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0;
                          i < (payments.length > 2 ? 2 : payments.length);
                          i++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: i < payments.length - 1 ? 4 : 0),
                          child: Text(
                            "${payments[i]['fee_name'] ?? 'Unknown Fee'}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      if (payments.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "dan ${payments.length - 2} tagihan lainnya",
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Student name
                  Text(
                    "${firstPayment['student_name'] ?? '-'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Amount and status
                  Row(
                    children: [
                      Text(
                        "Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.0,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Payment method info from first payment
                  Row(
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Metode:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${firstPayment['payment_method_name'] ?? 'Unknown'}",
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Proof image indicator
                      if (proofImageUrl.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.image,
                            size: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Tertunda';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  void _showPaymentDetails(dynamic paymentGroup) {
    final payments = paymentGroup['payments'] as List;
    final totalAmount = paymentGroup['total_amount'] ?? 0;
    final proofImageUrl = paymentGroup['proof_image_url'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    Utils.getTranslatedLabel(paymentDetailsKey),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Total: Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Proof image
            if (proofImageUrl.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _getFullImageUrl(
                          proofImageUrl), // Menggunakan helper function
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Memuat gambar...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gambar tidak dapat dimuat',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Periksa koneksi internet',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final status = payment['status'] ?? '';
                  final statusColor = _getStatusColor(status);

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${payment['fee_name'] ?? 'Unknown Fee'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Rp ${NumberFormat("#,##0", 'id_ID').format(payment['amount'] ?? 0)}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "ID: ${payment['id']}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Download Receipt and Close buttons
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Download Receipt button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReceipt(payments),
                      icon: Icon(Icons.download, size: 18),
                      label: Text(
                        'Unduh Struk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReceipt(List<dynamic> payments) {
    try {
      // Generate payment IDs list
      final paymentIds =
          payments.map((payment) => payment['id'].toString()).toList();

      // Create URL with payment_history_id parameters
      String receiptUrl = Api.downloadFeeReceipt;
      for (int i = 0; i < paymentIds.length; i++) {
        if (i == 0) {
          receiptUrl += '?payment_history_id[${i}]=${paymentIds[i]}';
        } else {
          receiptUrl += '&payment_history_id[${i}]=${paymentIds[i]}';
        }
      }

      // Generate filename based on payment IDs
      final fileName = 'struk_pembayaran_${paymentIds.join('_')}';

      // Create StudyMaterial object for download
      final studyMaterial = StudyMaterial(
        id: 0,
        fileName: fileName,
        fileUrl: receiptUrl,
        fileExtension: 'pdf',
        fileThumbnail: '',
        studyMaterialType: StudyMaterialType.file,
      );

      Utils.openDownloadBottomsheet(
        context: context,
        storeInExternalStorage: true,
        studyMaterial: studyMaterial,
      );
    } catch (e) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Terjadi kesalahan saat mengunduh struk',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Widget _buildTransactionShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
      effects: [
        ShimmerEffect(
          duration: Duration(seconds: 1),
          color: Colors.white54,
        ),
      ],
    );
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If the path already contains the base URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash if present and add base URL
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<PaymentTransactionsCubit, PaymentTransactionsState>(
            builder: (context, state) {
              if (state is PaymentTransactionsFetchSuccess) {
                if (state.paymentTransactions.isEmpty) {
                  return Center(
                    child: Animate(
                      effects: [
                        FadeEffect(duration: Duration(milliseconds: 400)),
                        ScaleEffect(duration: Duration(milliseconds: 400)),
                      ],
                      autoPlay: true,
                      onComplete: (controller) => controller.stop(),
                      child: NoDataContainer(
                        titleKey:
                            "noTransactionsKey", // Use appropriate key here
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    // context
                    //     .read<PaymentTransactionsCubit>()
                    //     .fetchPaymentTransactions();
                  },
                  child: ListView.builder(
                      itemCount: state.paymentTransactions.length,
                      padding: EdgeInsets.only(
                        bottom: 25.0,
                        top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarSmallerHeightPercentage,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                            state.paymentTransactions[index], index);
                      }),
                );
              }

              if (state is PaymentTransactionsFetchFailure) {
                return Center(
                  child: ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    animate: true,
                    onTapRetry: () {
                      // context
                      //     .read<PaymentTransactionsCubit>()
                      //     .fetchPaymentTransactions();
                    },
                  ),
                );
              }

              // Loading state
              return ListView.builder(
                itemCount: 5,
                padding: EdgeInsets.only(
                  bottom: 25.0,
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                  ),
                ),
                itemBuilder: (context, index) => _buildTransactionShimmer(),
              );
            },
          ),
        ],
      ),
    );
  }
}
