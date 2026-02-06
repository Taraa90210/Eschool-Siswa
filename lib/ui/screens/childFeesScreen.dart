import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/cubits/paymentTransactionsCubit.dart';
import 'package:eschool/data/models/studyMaterial.dart';
// import 'package:eschool/data/repositories/paymentRepository.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/student.dart';
// import 'package:eschool/data/models/studyMaterial.dart';
// import 'package:eschool/ui/screens/PaymentHistoryTabScreen.dart';
import 'package:eschool/ui/screens/paymentHistoryScreen.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/screens/xenditOnlyPaymentScreen.dart';
import 'package:eschool/ui/screens/xenditInstallmentPaymentScreen.dart';
import 'package:eschool/cubits/xenditInvoiceCubit.dart';
import 'package:eschool/data/repositories/xenditRepository.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:mime/mime.dart';

class ChildFeesScreen extends StatefulWidget {
  final Student child;
  ChildFeesScreen({Key? key, required this.child}) : super(key: key);

  static Widget routeInstance() {
    return ChildFeesScreen(
      child: Get.arguments as Student,
    );
  }

  @override
  State<ChildFeesScreen> createState() => _ChildFeesScreenState();
}

class _ChildFeesScreenState extends State<ChildFeesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Selected fees untuk multi-select
  Set<int> selectedFeeIds = <int>{};
  final accentGreen = const Color(0xFF10B981);

  // Flag untuk mendeteksi apakah halaman baru saja kembali dari navigasi
  bool _isReturningFromNavigation = false;
  bool _hasInitialized = false;

  // Tab selection state - Default: Unpaid (Belum Dibayar)
  String selectedTab = 'unpaid'; // 'paid', 'pending', 'unpaid'

  // String variables for display text
  String get paidTab => 'Sudah Dibayar';
  String get pendingTab => 'Menunggu Konfirmasi';
  String get unpaidTab => 'Belum Dibayar';

  @override
  void initState() {
    super.initState();
    print("🚀 ChildFeesScreen: initState called");

    // Add observer untuk mendeteksi perubahan lifecycle app
    WidgetsBinding.instance.addObserver(this);

    _initializeAnimations();

    // Clear any previous selections when page loads
    selectedFeeIds.clear();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _performCompleteReload();
        _hasInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(ChildFeesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("🔄 ChildFeesScreen: didUpdateWidget called - triggering reload");

    // Widget updated, perform reload
    if (mounted) {
      _handleReturnFromNavigation();
    }
  }

  @override
  void dispose() {
    print("🗑️ ChildFeesScreen: dispose called");

    // Remove observer saat dispose
    WidgetsBinding.instance.removeObserver(this);

    _animationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print("🔄 ChildFeesScreen: App lifecycle changed to: $state");

    // Ketika app kembali ke foreground (user kembali dari halaman lain atau background)
    if (state == AppLifecycleState.resumed) {
      print("🔄 ChildFeesScreen: App resumed - triggering reload");
      _handleReturnFromNavigation();
    }
  }

  // GetX specific: Listen for route changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if this is a return from navigation
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && _hasInitialized) {
      print("🔄 ChildFeesScreen: Route became current - triggering reload");
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _handleReturnFromNavigation();
        }
      });
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  void _handleReturnFromNavigation() {
    // Prevent multiple rapid calls
    if (_isReturningFromNavigation) {
      print("🔄 Already processing reload, skipping...");
      return;
    }

    print("🔄 ChildFeesScreen: Handling return from navigation");

    // Delay untuk memastikan UI sudah siap dan navigasi selesai
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        print("🔄 Performing complete page reload...");
        _performCompleteReload();
      }
    });
  }

  void _performCompleteReload() {
    print("🔄 Starting complete reload process...");

    // Set flag to prevent multiple reloads
    setState(() {
      _isReturningFromNavigation = true;
      selectedFeeIds.clear();
    });

    // Reset dan restart semua animasi
    _resetAnimations();

    // Clear cubit state dan fetch ulang data
    _resetCubitAndFetchData();

    // Reset flag setelah reload selesai
    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isReturningFromNavigation = false;
        });
        print("✅ Complete reload finished");
      }
    });
  }

  void _resetAnimations() {
    print("🎬 Resetting animations...");

    try {
      // Stop semua animasi
      _animationController.stop();
      _pulseController.stop();
      _floatingController.stop();

      // Reset ke posisi awal
      _animationController.reset();
      _pulseController.reset();
      _floatingController.reset();

      // Restart animasi dengan delay untuk efek smooth
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          _animationController.forward();
          _pulseController.repeat();
          _floatingController.repeat();
          print("🎬 Animations restarted");
        }
      });
    } catch (e) {
      print("⚠️ Error resetting animations: $e");
    }
  }

  void _resetCubitAndFetchData() {
    try {
      // Get cubit instance
      final cubit = context.read<ChildFeeDetailsCubit>();

      // Reset cubit to initial state if possible
      // Note: This depends on the cubit implementation

      // Force fetch data baru dari API
      print("🌐 Fetching fresh data from API for child ID: ${widget.child.id}");
      cubit.fetchChildFeeDetails(childId: widget.child.id ?? 0);

      print("✅ API call initiated");
    } catch (e) {
      print("❌ Error resetting cubit and fetching data: $e");
    }
  }

  void fetchChildFeeDetails() {
    // Clear selections when fetching new data
    setState(() {
      selectedFeeIds.clear();
    });

    print(
        "🌐 Manual fetch - Child fee details for child ID: ${widget.child.id}");
    try {
      context
          .read<ChildFeeDetailsCubit>()
          .fetchChildFeeDetails(childId: widget.child.id ?? 0);
    } catch (e) {
      print("❌ Error in manual fetch: $e");
    }
  }

  void _toggleFeeSelection(int feeId) {
    setState(() {
      if (selectedFeeIds.contains(feeId)) {
        selectedFeeIds.remove(feeId);
      } else {
        selectedFeeIds.add(feeId);
      }
    });
  }

  double _getTotalSelectedAmount(List<ChildFeeDetails> fees) {
    double total = 0;
    for (var fee in fees) {
      if (selectedFeeIds.contains(fee.id) &&
          fee.getFeePaymentStatus() == pendingKey) {
        total += fee.remainingFeeAmountToPay();
      }
    }
    return total;
  }

  Widget _buildFeeCard(ChildFeeDetails feeDetails, int index) {
    final feePaymentStatusKey = feeDetails.getFeePaymentStatus();
    final bill =
        feeDetails.bills?.isNotEmpty == true ? feeDetails.bills!.first : null;
    final totalAmount = feeDetails.getTotalAmount();
    final paidAmount = feeDetails.getPaidAmount();
    final remainingAmount = feeDetails.remainingFeeAmountToPay();
    final isOverdue = feeDetails.isFeeOverDue();
    final isSelected = selectedFeeIds.contains(feeDetails.id);

    // Check if there are pending payments in payment history
    bool hasPendingPayment = false;
    if (bill != null && bill.paymentHistory.isNotEmpty) {
      hasPendingPayment = bill.paymentHistory
          .any((payment) => payment.status?.toLowerCase() == 'pending');
    }

    // Override status jika remaining amount = 0 atau ada pending payment
    final isPaid = feePaymentStatusKey == paidKey || remainingAmount == 0;
    final canSelect = !isPaid && remainingAmount > 0 && !hasPendingPayment;

    // Handle empty or null data with fallbacks menggunakan "~"
    final feeName = feeDetails.name?.trim().isNotEmpty == true
        ? feeDetails.name!
        : bill?.name?.trim().isNotEmpty == true
            ? bill!.name!
            : "~";

    final className = feeDetails.classDetails?.name?.trim().isNotEmpty == true
        ? feeDetails.classDetails!.name!
        : null;

    final sessionYear = feeDetails.sessionYear?.name?.trim().isNotEmpty == true
        ? feeDetails.sessionYear!.name!
        : null;

    final dueDate = feeDetails.dueDate?.trim().isNotEmpty == true
        ? feeDetails.dueDate!
        : bill?.dueDate?.trim().isNotEmpty == true
            ? bill!.dueDate!
            : null;

    // Color configuration dengan override untuk remaining = 0 dan pending payment
    Color primaryColor = Theme.of(context).colorScheme.primary;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPaid) {
      statusColor = accentGreen;
      statusIcon = Icons.verified_rounded;
      statusText =
          Utils.getTranslatedLabel(paidKey); // Override untuk remaining = 0
    } else if (hasPendingPayment) {
      statusColor = Colors.orange.shade600;
      statusIcon = Icons.hourglass_top_rounded;
      statusText = Utils.getTranslatedLabel(waitingForAdminConfirmationKey);
    } else {
      switch (feePaymentStatusKey) {
        case pendingKey:
          statusColor = isOverdue
              ? Theme.of(context).colorScheme.primary
              : primaryColor.withOpacity(0.8);
          statusIcon = isOverdue ? Icons.error_rounded : Icons.schedule_rounded;
          statusText = isOverdue
              ? Utils.getTranslatedLabel(overdueKey)
              : Utils.getTranslatedLabel(feePaymentStatusKey);
          break;
        default:
          statusColor = primaryColor.withOpacity(0.8);
          statusIcon = Icons.info_rounded;
          statusText = Utils.getTranslatedLabel(feePaymentStatusKey);
      }
    }

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
        ScaleEffect(
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
          duration: Duration(milliseconds: 500),
          delay: Duration(milliseconds: 100 * index),
          curve: Curves.easeOutBack,
        ),
      ],
      autoPlay: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : hasPendingPayment
                      ? Colors.orange.shade300
                      : isOverdue
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3)
                          : primaryColor.withOpacity(0.1),
              width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : hasPendingPayment
                      ? Colors.orange.withOpacity(0.1)
                      : primaryColor.withOpacity(0.08),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Only toggle selection when clicking on card body (not buttons)
              if (canSelect && feeDetails.id != null) {
                _toggleFeeSelection(feeDetails.id!);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan checkbox, nama dan status
                  Row(
                    children: [
                      // Checkbox untuk selection - hanya untuk unpaid fees tanpa pending payment
                      if (canSelect) ...[
                        GestureDetector(
                          onTap: () {
                            if (feeDetails.id != null) {
                              _toggleFeeSelection(feeDetails.id!);
                            }
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 12),
                      ],

                      // Icon dengan background gradient - berbeda untuk paid/unpaid/pending
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPaid
                                ? [
                                    accentGreen.withOpacity(0.9),
                                    accentGreen.withOpacity(0.8),
                                  ]
                                : hasPendingPayment
                                    ? [
                                        Colors.orange.shade600.withOpacity(0.9),
                                        Colors.orange.shade600.withOpacity(0.8),
                                      ]
                                    : [
                                        primaryColor.withOpacity(0.9),
                                        primaryColor.withOpacity(0.8),
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: isPaid
                                  ? accentGreen.withOpacity(0.3)
                                  : hasPendingPayment
                                      ? Colors.orange.withOpacity(0.3)
                                      : primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Icon(
                          isPaid
                              ? Icons.verified_rounded
                              : hasPendingPayment
                                  ? Icons.hourglass_top_rounded
                                  : Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 14),

                      // Fee name dan detail
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 6),
                            // Type dan Status badges
                            Wrap(
                              spacing: 3,
                              runSpacing: 2,
                              children: [
                                // Fee Type Badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: feeDetails
                                        .getFeeTypeColor()
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: feeDetails
                                          .getFeeTypeColor()
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        feeDetails.getFeeType() ==
                                                Utils.getTranslatedLabel(
                                                    compulsoryKey)
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 10,
                                        color: feeDetails.getFeeTypeColor(),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        feeDetails.getFeeType(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: feeDetails.getFeeTypeColor(),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6),
                                // Status Badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 10,
                                        color: statusColor,
                                      ),
                                      SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Amount information
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.06),
                          primaryColor.withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Total Amount - selalu ditampilkan
                        _buildAmountRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: Utils.getTranslatedLabel(totalAmountKey),
                          amount: totalAmount,
                          color: Theme.of(context).colorScheme.secondary,
                          isMain: true,
                          showZero: true,
                        ),

                        // Paid Amount - hanya jika > 0
                        if (paidAmount > 0) ...[
                          SizedBox(height: 10),
                          _buildAmountRow(
                            icon: Icons.paid_rounded,
                            label: Utils.getTranslatedLabel(paidAmountKey),
                            amount: paidAmount,
                            color: accentGreen,
                          ),
                        ],

                        // Remaining Amount - hanya jika > 0
                        if (remainingAmount > 0) ...[
                          SizedBox(height: 10),
                          _buildAmountRow(
                            icon: Icons.pending_actions_rounded,
                            label: Utils.getTranslatedLabel(remainingKey),
                            amount: remainingAmount,
                            color: primaryColor.withOpacity(0.8),
                          ),
                        ],

                        // Jika semua amount adalah 0, tampilkan pesan
                        if (totalAmount == 0 &&
                            paidAmount == 0 &&
                            remainingAmount == 0) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    Utils.getTranslatedLabel(
                                        amountInformationNotAvailableKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Info badges
                  if (className != null || sessionYear != null) ...[
                    Row(
                      children: [
                        if (className != null)
                          Flexible(
                            child: _buildInfoBadge(
                              icon: Icons.class_rounded,
                              label: className,
                              color: primaryColor.withOpacity(0.8),
                            ),
                          ),
                        if (className != null && sessionYear != null)
                          SizedBox(width: 10),
                        if (sessionYear != null)
                          Flexible(
                            child: _buildInfoBadge(
                              icon: Icons.calendar_today_rounded,
                              label: sessionYear,
                              color: primaryColor.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Due date section
                  if (feePaymentStatusKey == pendingKey ||
                      isOverdue ||
                      hasPendingPayment) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasPendingPayment
                            ? Colors.orange.shade50
                            : isOverdue
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08)
                                : primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasPendingPayment
                              ? Colors.orange.shade200
                              : isOverdue
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3)
                                  : primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Due date row
                          if (!hasPendingPayment) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.15)
                                        : primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    dueDate != null
                                        ? (isOverdue
                                            ? Icons.error_rounded
                                            : Icons.event_available_rounded)
                                        : Icons.schedule_rounded,
                                    size: 14,
                                    color: isOverdue
                                        ? Theme.of(context).colorScheme.primary
                                        : primaryColor.withOpacity(0.8),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dueDate != null
                                            ? (isOverdue
                                                ? Utils.getTranslatedLabel(
                                                    paymentOverdueKey)
                                                : Utils.getTranslatedLabel(
                                                    dueDateKey))
                                            : Utils.getTranslatedLabel(
                                                dueDateKey),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOverdue
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : primaryColor.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        dueDate != null
                                            ? _formatDueDate(dueDate)
                                            : "~",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: dueDate != null
                                              ? (isOverdue
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : primaryColor
                                                      .withOpacity(0.8))
                                              : Colors.grey.shade600,
                                          fontStyle: dueDate != null
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOverdue && dueDate != null)
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 1.0 +
                                            (Tween<double>(
                                              begin: 0.0,
                                              end: 0.15,
                                            )
                                                .animate(CurvedAnimation(
                                                  parent: _pulseController,
                                                  curve: Curves.easeInOut,
                                                ))
                                                .value),
                                        child: Icon(
                                          Icons.warning_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 18,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],

                          // Pending payment info
                          if (hasPendingPayment) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.pending_actions_rounded,
                                    size: 14,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Utils.getTranslatedLabel(
                                            paymentUnderReviewKey),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                      Text(
                                        Utils.getTranslatedLabel(
                                            adminIsVerifyingYourPaymentKey),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 +
                                          (Tween<double>(
                                            begin: 0.0,
                                            end: 0.1,
                                          )
                                              .animate(CurvedAnimation(
                                                parent: _pulseController,
                                                curve: Curves.easeInOut,
                                              ))
                                              .value),
                                      child: Icon(
                                        Icons.hourglass_top_rounded,
                                        color: Colors.orange.shade600,
                                        size: 18,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Action buttons row
                  Row(
                    children: [
                      // History Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _navigateToPaymentHistory(feeDetails, bill);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    Utils.getTranslatedLabel(historyKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Cicil Button
                      if (!isPaid &&
                          remainingAmount > 0 &&
                          !hasPendingPayment) ...[
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _navigateToInstallmentPayment(feeDetails);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.9),
                                      primaryColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      Utils.getTranslatedLabel(instalmentKey),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _navigateToPaymentHistory(ChildFeeDetails feeDetails, dynamic bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryScreen(
          bill: bill,
          billName: feeDetails.name ??
              bill?.name ??
              Utils.getTranslatedLabel(unknownFeeKey),
        ),
      ),
    );
  }

  void _navigateToInstallmentPayment(ChildFeeDetails feeDetails) {
    // Navigate to installment payment screen with custom amount input
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => XenditInvoiceCubit(
            XenditRepository(),
          ),
          child: XenditInstallmentPaymentScreen(
            feeDetails: feeDetails,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    bool isMain = false,
    bool showZero = false,
  }) {
    // Jika amount adalah 0 dan showZero false, jangan tampilkan
    if (amount == 0 && !showZero) {
      return SizedBox.shrink();
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 13 : 12,
              fontWeight: isMain ? FontWeight.w600 : FontWeight.w500,
              color: color.withOpacity(0.9),
            ),
          ),
        ),
        Text(
          amount > 0 ? _formatCurrency(amount) : "~",
          style: TextStyle(
            fontSize: isMain ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: amount > 0 ? color : Colors.grey.shade600,
            fontStyle: amount > 0 ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeShimmerLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 48,
                    width: 48,
                    borderRadius: 14,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoadingContainer(
                        child: CustomShimmerContainer(
                          height: 16,
                          width: MediaQuery.of(context).size.width * 0.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      ShimmerLoadingContainer(
                        child: CustomShimmerContainer(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 28,
                    width: 70,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShimmerLoadingContainer(
              child: CustomShimmerContainer(
                height: 70,
                width: double.infinity,
                borderRadius: 14,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 28,
                    width: 90,
                    borderRadius: 10,
                  ),
                ),
                SizedBox(width: 10),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 28,
                    width: 110,
                    borderRadius: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesContainer({required List<ChildFeeDetails> fees}) {
    // Filter fees sesuai tab
    List<ChildFeeDetails> filteredFees = fees.where((fee) {
      final feeStatus = fee.getFeePaymentStatus();
      final bill = fee.bills?.isNotEmpty == true ? fee.bills!.first : null;
      final hasPendingPayment = bill != null && bill.paymentHistory.isNotEmpty
          ? bill.paymentHistory
              .any((payment) => payment.status?.toLowerCase() == 'pending')
          : false;
      if (selectedTab == 'paid') {
        return feeStatus == paidKey || fee.remainingFeeAmountToPay() == 0;
      } else if (selectedTab == 'pending') {
        return hasPendingPayment;
      } else {
        // unpaid
        return (feeStatus == pendingKey || fee.remainingFeeAmountToPay() > 0) &&
            !(feeStatus == paidKey || fee.remainingFeeAmountToPay() == 0) &&
            !hasPendingPayment;
      }
    }).toList();

    if (filteredFees.isEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            // Background decoration
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
              ),
            ),
            // NoDataContainer centered completely
            Center(
              child: NoDataContainer(
                titleKey: noUnpaidBillsKey,
                animate: true,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        onRefresh: () async {
          fetchChildFeeDetails();
        },
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                      (Utils.appBarBiggerHeightPercentage * 0.1),
                ) +
                10,
            bottom: selectedFeeIds.isNotEmpty ? 100 : 30,
            left: 20,
            right: 20,
          ),
          itemCount: filteredFees.length + 1, // +1 untuk payment overview board
          itemBuilder: (context, index) {
            if (index == 0) {
              // Payment Overview Board sebagai item pertama
              return _buildPaymentOverviewBoard(filteredFees);
            }
            // Fee cards
            return _buildFeeCard(filteredFees[index - 1], index - 1);
          },
        ),
      ),
    );
  }

  Widget _buildFloatingPaymentButton(List<ChildFeeDetails> fees) {
    final totalAmount = _getTotalSelectedAmount(fees);
    final selectedCount = selectedFeeIds.length;

    return Animate(
      effects: [
        SlideEffect(
          begin: Offset(0, 1),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
        FadeEffect(duration: Duration(milliseconds: 300)),
      ],
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, 20), // Remove top margin
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false, // Prevent extra top padding
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedCount ${Utils.getTranslatedLabel(selectedCount > 1 ? itemsSelectedKey : itemSelectedKey)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatCurrency(totalAmount),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payment_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      Utils.getTranslatedLabel(payNowKey),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOverviewBoard(List<ChildFeeDetails> fees) {
    int totalFees = fees.length;
    int paidFees = 0;
    int pendingFees = 0;
    int unpaidFees = 0;
    double totalAmount = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    double unpaidAmount = 0;
    double totalOutstanding = 0; // Total remaining amount from all fees

    fees.sort((a, b) {
      final aPaid = a.getFeePaymentStatus() == paidKey ||
          a.remainingFeeAmountToPay() == 0;
      final bPaid = b.getFeePaymentStatus() == paidKey ||
          b.remainingFeeAmountToPay() == 0;

      // Kalau a sudah lunas dan b belum → a di belakang
      if (aPaid && !bPaid) return 1;
      // Kalau a belum lunas dan b sudah lunas → a di depan
      if (!aPaid && bPaid) return -1;
      // Kalau dua-duanya sama (lunas atau belum) → posisi tetap
      return 0;
    });

    for (var fee in fees) {
      final feeRemaining = fee.remainingFeeAmountToPay();
      final isPaid = fee.getFeePaymentStatus() == paidKey || feeRemaining == 0;

      // Check if there are pending payments in payment history
      bool hasPendingPayment = false;
      final bill = fee.bills?.isNotEmpty == true ? fee.bills!.first : null;
      if (bill != null && bill.paymentHistory.isNotEmpty) {
        // Check if there's a recent pending payment (not just any pending payment)
        final recentPendingPayment = bill.paymentHistory
            .where((payment) => payment.status?.toLowerCase() == 'pending')
            .isNotEmpty;

        // Also check if the fee has been partially paid but still has remaining amount
        final hasPartialPayment = fee.getPaidAmount() > 0 && feeRemaining > 0;

        hasPendingPayment = recentPendingPayment && hasPartialPayment;
      }

      // Alternative: Check if fee status indicates it's under review
      final feeStatus = fee.getFeePaymentStatus();
      final isUnderReview = feeStatus == 'menunggu konfirmasi admin' ||
          feeStatus == 'waiting for admin confirmation' ||
          feeStatus == 'payment under review';

      hasPendingPayment = hasPendingPayment || isUnderReview;

      if (isPaid) {
        paidFees++;
        paidAmount += fee.getPaidAmount();
      } else if (hasPendingPayment) {
        pendingFees++;
        // Calculate only the amount from pending payments, not the total remaining
        double pendingPaymentAmount = 0;
        if (bill != null && bill.paymentHistory.isNotEmpty) {
          pendingPaymentAmount = bill.paymentHistory
              .where((payment) => payment.status?.toLowerCase() == 'pending')
              .fold(0.0, (sum, payment) => sum + (payment.amount ?? 0));
        }
        pendingAmount += pendingPaymentAmount;
      } else {
        unpaidFees++;
        unpaidAmount += feeRemaining;
      }

      totalAmount += fee.getTotalAmount();
      totalOutstanding += feeRemaining; // Add to total outstanding for all fees
    }

    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 600)),
        SlideEffect(
          begin: Offset(0, -0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utils.getTranslatedLabel(paymentOverviewKey),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Text(
                          '$totalFees ${Utils.getTranslatedLabel(totalBillsKey)}',
                          style: TextStyle(
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

              SizedBox(height: 20),

              // Redesigned Stats Grid - Vertical Layout untuk menghindari overflow
              Column(
                children: [
                  // Status Card - Full Width
                  Builder(
                    builder: (_) {
                      if (selectedTab == 'paid') {
                        return _buildImprovedStatCard(
                          icon: Icons.check_circle_outline,
                          label: Utils.getTranslatedLabel(paidKey),
                          value: '$paidFees',
                          amount: paidAmount,
                          color: accentGreen,
                        );
                      } else if (selectedTab == 'pending') {
                        return _buildImprovedStatCard(
                          icon: Icons.hourglass_top_rounded,
                          label: Utils.getTranslatedLabel(pendingconfirmKey),
                          value: '$pendingFees',
                          amount: pendingAmount,
                          color: Colors.orange.shade600,
                        );
                      } else if (selectedTab == 'unpaid') {
                        return _buildImprovedStatCard(
                          icon: Icons.cancel_outlined,
                          label: Utils.getTranslatedLabel(unpaidKey),
                          value: '$unpaidFees',
                          amount: unpaidAmount,
                          color: primaryColor,
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),

                  SizedBox(height: 12),

                  // Total Amount Card - Full Width dengan layout yang sama
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon dengan container yang sama seperti status card
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          SizedBox(width: 12),

                          // Content dengan alignment yang tepat
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  Utils.getTranslatedLabel(totalAmountKey),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  totalAmount > 0
                                      ? _formatCurrency(totalAmount)
                                      : "No amount data",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    height: 1,
                                  ),
                                ),
                                if (totalOutstanding > 0) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      Utils.getTranslatedLabel(outstandingKey) +
                                          ': ${_formatCurrency(totalOutstanding)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovedStatCard({
    required IconData icon,
    required String label,
    required String value,
    required double amount,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),

          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                if (amount > 0) ...[
                  SizedBox(height: 2),
                  Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Background decoration dengan floating elements yang simpel
          ...List.generate(2, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = Tween<double>(
                  begin: 0.0,
                  end: 15.0,
                )
                    .animate(CurvedAnimation(
                      parent: _floatingController,
                      curve: Interval(
                        index * 0.5,
                        1.0,
                        curve: Curves.easeInOut,
                      ),
                    ))
                    .value;

                return Positioned(
                  top: 120 + (index * 300),
                  right: -40 + offset,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.04),
                    ),
                  ),
                );
              },
            );
          }),

          // Content based on selected tab
          BlocBuilder<ChildFeeDetailsCubit, ChildFeeDetailsState>(
            builder: (context, state) {
              if (state is ChildFeeDetailsFetchSuccess) {
                List<ChildFeeDetails> filteredFees;
                if (selectedTab == 'paid') {
                  filteredFees = state.fees
                      .where((fee) =>
                          fee.getFeePaymentStatus() == paidKey ||
                          fee.remainingFeeAmountToPay() == 0)
                      .toList();
                } else if (selectedTab == 'pending') {
                  filteredFees = state.fees.where((fee) {
                    final bill =
                        fee.bills?.isNotEmpty == true ? fee.bills!.first : null;
                    final hasPendingPayment =
                        bill != null && bill.paymentHistory.isNotEmpty
                            ? bill.paymentHistory.any((payment) =>
                                payment.status?.toLowerCase() == 'pending')
                            : false;
                    return hasPendingPayment;
                  }).toList();
                } else {
                  // unpaid
                  filteredFees = state.fees
                      .where((fee) =>
                          (fee.getFeePaymentStatus() == pendingKey ||
                              fee.remainingFeeAmountToPay() > 0) &&
                          !(fee.getFeePaymentStatus() == paidKey ||
                              fee.remainingFeeAmountToPay() == 0))
                      .toList();
                }
                return _buildFeesContainer(fees: filteredFees);
              }
              if (state is ChildFeeDetailsFetchFailure) {
                return Center(
                  child: Animate(
                    effects: [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                      ScaleEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        fetchChildFeeDetails();
                      },
                    ),
                  ),
                );
              }
              // Loading state
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade50,
                      Colors.white,
                    ],
                  ),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarBiggerHeightPercentage -
                                  (Utils.appBarBiggerHeightPercentage * 0.1),
                        ) +
                        10,
                    bottom: 30,
                  ),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildFeeShimmerLoading(),
                ),
              );
            },
          ),

          // Modified app bar with tab selector
          ScreenTopBackgroundContainer(
            heightPercentage: Utils.appBarBiggerHeightPercentage -
                (Utils.appBarBiggerHeightPercentage * 0.1),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Stack(
                  children: [
                    // Back button
                    const Positioned(
                      left: 10,
                      top: -2,
                      child: CustomBackButton(),
                    ),
                    Positioned(
                      right: 15,
                      top: -12,
                      child: CustomHistoryButton(child: widget.child),
                    ),

                    // Screen title
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        alignment: Alignment.topCenter,
                        width: boxConstraints.maxWidth * (0.5),
                        child: Text(
                          Utils.getTranslatedLabel(feesKey),
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: Utils.screenTitleFontSize,
                          ),
                        ),
                      ),
                    ),

                    // Tab selector container
                    Align(
                      alignment: Alignment(0.0, 0.3),
                      child: Container(
                        width: boxConstraints.maxWidth * 0.9,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.filter_list),
                          label: Text(
                            _getTabLabel(selectedTab),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => _showFilterBottomSheet(context),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Floating Payment Button - only show on unpaid tab
          if (selectedFeeIds.isNotEmpty && selectedTab == 'unpaid')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlocBuilder<ChildFeeDetailsCubit, ChildFeeDetailsState>(
                builder: (context, state) {
                  if (state is ChildFeeDetailsFetchSuccess) {
                    // Hanya fee yang terpilih dan unpaid
                    final selectedFeesData = state.fees
                        .where((fee) =>
                            selectedFeeIds.contains(fee.id) &&
                            (fee.getFeePaymentStatus() == pendingKey ||
                                fee.remainingFeeAmountToPay() > 0) &&
                            !(fee.getFeePaymentStatus() == paidKey ||
                                fee.remainingFeeAmountToPay() == 0))
                        .toList();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => XenditInvoiceCubit(
                                XenditRepository(),
                              ),
                              child: XenditOnlyPaymentScreen(
                                selectedFees: selectedFeesData,
                                totalAmount:
                                    _getTotalSelectedAmount(state.fees),
                                child: widget.child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: _buildFloatingPaymentButton(state.fees),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Filter Biaya',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih status untuk menampilkan tagihan berdasarkan status tagihan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              _buildStatusOption(context, 'paid', paidTab),
              _buildStatusOption(context, 'pending', pendingTab),
              _buildStatusOption(context, 'unpaid', unpaidTab),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext context, String value, String label) {
    final bool isSelected = selectedTab == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _getTabLabel(String tab) {
    switch (tab) {
      case 'paid':
        return 'Sudah Dibayar';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'unpaid':
        return 'Belum Dibayar';
      default:
        return 'Filter';
    }
  }

  // Payment History Tab Widget
  Widget _buildPaymentHistoryTab() {
    return BlocBuilder<PaymentTransactionsCubit, PaymentTransactionsState>(
      builder: (context, state) {
        if (state is PaymentTransactionsFetchSuccess) {
          if (state.paymentTransactions.isEmpty) {
            return Container(
              child: Center(
                child: Animate(
                  effects: [
                    FadeEffect(duration: Duration(milliseconds: 400)),
                    ScaleEffect(duration: Duration(milliseconds: 400)),
                  ],
                  autoPlay: true,
                  onComplete: (controller) => controller.stop(),
                  child: NoDataContainer(
                    titleKey: Utils.getTranslatedLabel(noTransactionsKey),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async {
              context
                  .read<PaymentTransactionsCubit>()
                  .fetchPaymentTransactions(widget.child.id ?? 0);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: ListView.builder(
                itemCount: state.paymentTransactions.length,
                padding: EdgeInsets.only(
                  bottom: 25.0,
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                        (Utils.appBarBiggerHeightPercentage * 0.1),
                  ),
                  left: 0,
                  right: 0,
                ),
                itemBuilder: (context, index) {
                  return _buildTransactionCard(
                      state.paymentTransactions[index], index);
                },
              ),
            ),
          );
        }

        if (state is PaymentTransactionsFetchFailure) {
          return Container(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                        (Utils.appBarBiggerHeightPercentage * 0.1),
                  ) +
                  20,
            ),
            child: Center(
              child: ErrorContainer(
                errorMessageCode: state.errorMessage,
                animate: true,
                onTapRetry: () {
                  context
                      .read<PaymentTransactionsCubit>()
                      .fetchPaymentTransactions(widget.child.id ?? 0);
                },
              ),
            ),
          );
        }

        // Loading state
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.white,
              ],
            ),
          ),
          child: ListView.builder(
            itemCount: 5,
            padding: EdgeInsets.only(
              bottom: 25.0,
              top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                        (Utils.appBarBiggerHeightPercentage * 0.1),
                  ) +
                  20,
              left: 0,
              right: 0,
            ),
            itemBuilder: (context, index) => _buildTransactionShimmer(),
          ),
        );
      },
    );
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
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
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
                              .withOpacity(0.1),
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
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(
                            DateTime.parse(createdAt).toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.6),
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
                                .withOpacity(0.6),
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
                                  .withOpacity(0.7),
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
                          .withOpacity(0.8),
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
                          color: statusColor.withOpacity(0.1),
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
                            .withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Metode:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.6),
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
                            color: Colors.green.withOpacity(0.1),
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

  Color _getStatusColor(String status) {
    final softRedColor = Color(0xFFE57373);
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'disetujui':
        return Colors.green;
      case 'rejected':
      case 'ditolak':
        return Colors.red;
      case 'succeed':
        return Colors.green;
      case 'failed':
        return softRedColor;
      default:
        return Theme.of(context).colorScheme.secondary.withOpacity(0.5);
    }
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
                      imageUrl: _getFullImageUrl(proofImageUrl),
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
                                color: statusColor.withOpacity(0.1),
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

// Future<void> _downloadReceipt(
//   BuildContext context,
//   List<dynamic> payments, {
//   String? bearerToken, // opsional kalau API butuh auth
// }) async {
//   try {
//     // 1) Susun URL dengan query yg rapi
//     final ids = payments.map((p) => p['id'].toString()).toList();
//     final qp = <String, String>{};
//     for (var i = 0; i < ids.length; i++) {
//       qp['payment_history_id[$i]'] = ids[i];
//       debugPrint('payment_history_id[$i]: ${ids[i]}');
//     }
//     final url = Uri.parse(Api.downloadFeeReceipt).replace(queryParameters: qp).toString();

//     // 2) Download bytes + header yang pas
//     final dio = Dio(BaseOptions(
//       headers: {
//         if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
//         'Accept': 'application/pdf',
//       },
//       responseType: ResponseType.bytes,
//       followRedirects: true,
//       // izinkan 2xx & 3xx
//       validateStatus: (s) => s != null && s >= 200 && s < 400,
//     ));

//     final resp = await dio.get<List<int>>(url);
//     final status = resp.statusCode ?? 0;
//     if (status >= 400) throw Exception('HTTP $status');

//     final bytes = resp.data ?? <int>[];
//     if (bytes.isEmpty) throw Exception('File kosong');

//     // 3) Validasi: harus PDF (magic header %PDF-)
//     final isPdf = bytes.length > 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
//     final suggestedName = 'struk_pembayaran_${ids.join('_')}.pdf';

//     if (!isPdf) {
//       // simpan debug agar tahu isi respon server
//       final appDir = await getApplicationDocumentsDirectory();
//       final debugPath = '${appDir.path}/$suggestedName.debug.txt';
//       await File(debugPath).writeAsBytes(bytes, flush: true);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server tidak mengirim PDF. Cek auth/URL. Debug: $debugPath')),
//       );
//       return;
//     }

//     // 4) Dialog "Save As" (SAF) -> user pilih /Download/ atau /Download/eSchool/
//     final savePath = await FilePicker.platform.saveFile(
//       dialogTitle: 'Simpan struk ke Download',
//       fileName: suggestedName,
//       type: FileType.custom,            // <- perbaiki ini
//       allowedExtensions: ['pdf'],
//     );
//     if (savePath == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Penyimpanan dibatalkan')),
//       );
//       return;
//     }

//     // 5) Tulis bytes ke lokasi yang dipilih user
//     await File(savePath).writeAsBytes(bytes, flush: true);

//     // 6) Buka di dalam aplikasi (pasti kebuka, tanpa viewer eksternal)
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => Scaffold(
//           appBar: AppBar(title: const Text('Struk Pembayaran')),
//           body: SfPdfViewer.memory(Uint8List.fromList(bytes)),
//         ),
//       ),
//     );

//     // 7) (Opsional) juga coba buka lewat app eksternal
//     final appDir = await getApplicationDocumentsDirectory();
//     final tempPath = '${appDir.path}/$suggestedName';
//     await File(tempPath).writeAsBytes(bytes, flush: true);
//     final openRes = await OpenFilex.open(tempPath);
//     if (openRes.type != ResultType.done) {
//       debugPrint('OpenFilex gagal: ${openRes.message} (mungkin tidak ada PDF viewer).');
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Struk tersimpan di Download.')),
//     );
//   } catch (e, s) {
//     debugPrint('ERR _downloadReceipt: $e\n$s');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Gagal menyimpan/membuka struk: $e')),
//     );
//   }
// }

//debug
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
      print('Downloading receipt from: $receiptUrl');
      print('File name: $fileName');
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
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
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
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
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
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.grey.withOpacity(0.2),
            ),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

// Helper method untuk format tanggal
String _formatDueDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '-';

  try {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMMM yyyy', "id_ID").format(date);
  } catch (e) {
    return dateString;
  }
}

class CustomHistoryButton extends StatelessWidget {
  final Student child;
  const CustomHistoryButton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/payment-history', arguments: child);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.history_rounded,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
