import 'dart:io';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:eschool/cubits/paymentSubmissionCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Payment type enum
enum PaymentType { manual, xendit }

class PaymentScreen extends StatefulWidget {
  final List<ChildFeeDetails> selectedFees;
  final double totalAmount;
  final Student child;

  const PaymentScreen({
    Key? key,
    required this.selectedFees,
    required this.totalAmount,
    required this.child,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _uploadController;

  // Payment type selection
  PaymentType selectedPaymentType = PaymentType.manual;

  PaymentMethod? selectedPaymentMethod;
  File? selectedProofFile;
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  String? uploadError;

  // String variables for display text
  String get screenTitle => 'Pembayaran';
  String get paymentSummaryTitle => 'Ringkasan Pembayaran';
  String get studentLabel => 'Siswa: ';
  String get unknownFee => 'Biaya tidak diketahui';
  String get feeIdLabel => 'ID Pembayaran : ';
  String get uploadPaymentProofTitle => 'Unggah Bukti Pembayaran';
  String get uploadPaymentProofSubtitle => 'Wajib • JPG, PNG, PDF • Maks 2MB';
  String get paymentMethodsTitle => 'Metode Pembayaran';
  String get paymentMethodsSubtitle =>
      'Pilih metode pembayaran yang diinginkan';
  String get selectPaymentProofTitle => 'Pilih Bukti Pembayaran';
  String get selectPaymentProofSubtitle =>
      'Pilih cara untuk menambahkan bukti pembayaran';
  String get galleryOption => 'Galeri';
  String get gallerySubtitle => 'JPG, PNG, PDF';
  String get cameraOption => 'Kamera';
  String get cameraSubtitle => 'Ambil Foto';
  String get fileSizeExceeded =>
      'Ukuran file melebihi batas 2MB. Pilih file yang lebih kecil.';
  String get invalidFileFormat =>
      'Format file tidak valid. Pilih file JPG, JPEG, PNG, atau PDF.';
  String get failedToPickFile => 'Gagal memilih file: ';
  String get photoSizeExceeded =>
      'Ukuran foto melebihi batas 2MB. Coba ambil foto dengan kualitas lebih rendah.';
  String get failedToTakePhoto => 'Gagal mengambil foto: ';
  String get processing => 'Memproses...';
  String get tapToUploadPaymentProof => 'Ketuk untuk unggah bukti pembayaran';
  String get jpgPngPdfMax2mb => 'JPG, PNG, PDF (Maks 2MB)';
  String get changeFile => 'Ganti File';
  String get removeFile => 'Hapus';
  String get failedToLoadImage => 'Gagal memuat gambar';
  String get noPaymentMethodsAvailable =>
      'Tidak ada metode pembayaran tersedia';
  String get unknownMethod => 'Metode Tidak Dikenal';
  String get accountHolder => 'a.n. ';
  String get submittingPayment => 'Mengirim Pembayaran...';
  String get submitBulkPayment => 'Kirim Pembayaran Massal';
  String get submitPayment => 'Kirim Pembayaran';
  String get paymentSubmittedSuccessfully => 'Pembayaran Berhasil Dikirim';
  String get bulkPaymentSubmittedSuccessfully =>
      'Pembayaran Massal Berhasil Dikirim';
  String get paymentIdLabel => 'ID Pembayaran';
  String get feeLabel => 'Biaya';
  String get amountLabel => 'Jumlah';
  String get paymentMethodLabel => 'Metode Pembayaran';
  String get statusLabel => 'Status';
  String get pendingStatus => 'MENUNGGU';
  String get totalFeesLabel => 'Total Biaya';
  String get totalAmountLabel => 'Total Jumlah';
  String get unknownPaymentMethod => 'Tidak Dikenal';
  String get notificationMessage =>
      'Anda akan diberitahu setelah pembayaran diverifikasi oleh admin.';
  String get okButton => 'OK';
  String get hintUploadProof => 'Upload bukti pembayaran terlebih dahulu';
  String get hintSelectMethod => 'Pilih metode pembayaran';
  String get hintCompleteAll => 'Lengkapi semua data untuk melanjutkan';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _uploadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _uploadController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      setState(() {
        uploadError = null;
        isUploading = true;
      });

      _uploadController.forward();

      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (file != null) {
        final fileSize = await File(file.path).length();
        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            uploadError = fileSizeExceeded;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        final extension = file.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
          setState(() {
            uploadError = invalidFileFormat;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        setState(() {
          selectedProofFile = File(file.path);
          isUploading = false;
        });
      } else {
        setState(() {
          isUploading = false;
        });
      }

      _uploadController.reset();
    } catch (e) {
      setState(() {
        uploadError = failedToPickFile + e.toString();
        isUploading = false;
      });
      _uploadController.reset();
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        uploadError = null;
        isUploading = true;
      });

      _uploadController.forward();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (photo != null) {
        final fileSize = await File(photo.path).length();
        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            uploadError = photoSizeExceeded;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        setState(() {
          selectedProofFile = File(photo.path);
          isUploading = false;
        });
      } else {
        setState(() {
          isUploading = false;
        });
      }

      _uploadController.reset();
    } catch (e) {
      setState(() {
        uploadError = failedToTakePhoto + e.toString();
        isUploading = false;
      });
      _uploadController.reset();
    }
  }

  void _showFileSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    selectPaymentProofTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectPaymentProofSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFileSourceOption(
                          icon: Icons.photo_library_outlined,
                          label: galleryOption,
                          subtitle: gallerySubtitle,
                          onTap: () {
                            Navigator.pop(context);
                            _pickDocument();
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildFileSourceOption(
                          icon: Icons.camera_alt_outlined,
                          label: cameraOption,
                          subtitle: cameraSubtitle,
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PaymentMethod> _getAvailablePaymentMethods() {
    for (var fee in widget.selectedFees) {
      if (fee.paymentMethods?.isNotEmpty == true) {
        return fee.paymentMethods!;
      }
    }
    return [];
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    if (method.id == 16) return SizedBox.shrink();
    final isSelected = selectedPaymentMethod?.id == method.id;

    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 400)),
        SlideEffect(
          begin: Offset(0.3, 0),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        ),
      ],
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method;
            // Clear error when changing method
          });
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 8 : 4,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Payment method image or icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: method.hasImage
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  border: method.hasImage
                      ? Border.all(color: Colors.grey.shade200, width: 1)
                      : null,
                ),
                child: method.hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: method.fullImageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.9),
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.payment_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name ?? unknownMethod,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    if (method.description != null &&
                        method.name != method.description) ...[
                      SizedBox(height: 4),
                      Text(
                        method.description ?? unknownMethod,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                    if (method.accountNumber?.isNotEmpty == true) ...[
                      Text(
                        method.accountNumber!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (method.accountHolder?.isNotEmpty == true) ...[
                      SizedBox(height: 2),
                      Text(
                        accountHolder + method.accountHolder!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Checklist indicator
              AnimatedContainer(
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
                        : Colors.grey.shade400,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFeesInfo() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                Icons.receipt_long_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                paymentSummaryTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Student info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    studentLabel + widget.child.getFullName(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ...widget.selectedFees
              .map((fee) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fee.name ?? unknownFee,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                feeIdLabel + fee.id!.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(fee.remainingFeeAmountToPay()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.selectedFees.length > 1
                      ? Utils.getTranslatedLabel(totalAmountKey) +
                          ' (${widget.selectedFees.length})'
                      : Utils.getTranslatedLabel(totalAmountKey),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              Text(
                _formatCurrency(widget.totalAmount),
                style: TextStyle(
                  fontSize: 18,
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

  Widget _buildPaymentTypeSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                Icons.payment,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentTypeOption(
                  type: PaymentType.xendit,
                  icon: Icons.account_balance_wallet,
                  title: 'Bayar Otomatis',
                  subtitle: 'Via Xendit (VA, E-wallet, QRIS)',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPaymentTypeOption(
                  type: PaymentType.manual,
                  icon: Icons.upload_file,
                  title: 'Upload Bukti',
                  subtitle: 'Transfer manual + upload',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required PaymentType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedPaymentType == type;
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentType = type;
          // Reset selections when changing payment type
          if (type == PaymentType.xendit) {
            selectedProofFile = null;
            uploadError = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                Icons.cloud_upload_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploadPaymentProofTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      uploadPaymentProofSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (selectedProofFile != null) ...[
            // Show selected file with image preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  // Image preview or file icon
                  if (_isImageFile()) ...[
                    // Preview gambar
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedProofFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                    failedToLoadImage,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ] else ...[
                    // File icon untuk PDF
                    Icon(
                      _getFileIcon(),
                      size: 48,
                      color: Colors.green.shade600,
                    ),
                    SizedBox(height: 12),
                  ],
                  Text(
                    _getFileName(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getFileSize(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFileSourceDialog,
                    icon: Icon(Icons.edit_outlined, size: 16),
                    label: Text(changeFile),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedProofFile = null;
                        uploadError = null;
                      });
                    },
                    icon: Icon(Icons.delete_outline, size: 16),
                    label: Text(removeFile),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.shade400),
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Upload button
            GestureDetector(
              onTap: isUploading ? null : _showFileSourceDialog,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _uploadController,
                  builder: (context, child) {
                    if (isUploading) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            processing,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          tapToUploadPaymentProof,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          jpgPngPdfMax2mb,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
          if (uploadError != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uploadError!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isImageFile() {
    if (selectedProofFile == null) return false;
    final extension = selectedProofFile!.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  IconData _getFileIcon() {
    if (selectedProofFile == null) return Icons.description;

    final extension = selectedProofFile!.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _getFileName() {
    if (selectedProofFile == null) return '';
    return selectedProofFile!.path.split('/').last;
  }

  String _getFileSize() {
    if (selectedProofFile == null) return '';
    final bytes = selectedProofFile!.lengthSync();
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool _canProceedPayment() {
    return selectedPaymentMethod != null && selectedProofFile != null;
  }

  String _getButtonHintMessage() {
    // Check conditions in priority order
    if (selectedProofFile == null) {
      return hintUploadProof;
    } else if (selectedPaymentMethod == null) {
      return hintSelectMethod;
    } else {
      return hintCompleteAll;
    }
  }

  Future<void> _processPayment() async {
    if (!_canProceedPayment()) return;

    // Always use unified payment method with array format
    final feesIds = widget.selectedFees.map((fee) => fee.id!).toList();

    await context.read<PaymentSubmissionCubit>().submitPayment(
          childId: widget.child.id!,
          feesIds: feesIds, // Always send as array, even for single payment
          paymentMethodId: selectedPaymentMethod!.id!,
          proofFile: selectedProofFile!,
        );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required Map<String, String> paymentDetails,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie Animation
            Lottie.asset(
              "assets/animations/payment_success.json",
              width: 140,
              height: 140,
              repeat: true,
            ),
            SizedBox(height: 20),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Payment Details Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paymentDetails.entries
                    .map((entry) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 16),

            // Info Box
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Utils.getTranslatedLabel(paymentPendingMsgKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Back to fees screen
                },
                child: Text(
                  okButton,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethods = _getAvailablePaymentMethods();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<PaymentSubmissionCubit, PaymentSubmissionState>(
        listener: (context, state) {
          if (state is PaymentSubmissionSuccess) {
            // Handle successful payment submission
            // Always use translation key for consistent language
            final message = Utils.getTranslatedLabel(paymentSuccessMsgKey);

            Map<String, String> paymentDetails = {};

            if (state.paymentMethod == 'single') {
              final fee = widget.selectedFees.first;

              // Build payment details - exclude transaction ID completely
              paymentDetails = {};

              paymentDetails[Utils.getTranslatedLabel(feesKey)] =
                  fee.name ?? unknownFee;
              paymentDetails[Utils.getTranslatedLabel(amountKey)] =
                  _formatCurrency(fee.remainingFeeAmountToPay());
              paymentDetails[Utils.getTranslatedLabel(paymentMethodKey)] =
                  selectedPaymentMethod!.name ?? unknownPaymentMethod;
              paymentDetails[Utils.getTranslatedLabel(statusKey)] =
                  Utils.getTranslatedLabel(pendingKey).toUpperCase();

              _showSuccessDialog(
                title: Utils.getTranslatedLabel(paymentSuccessTitleKey),
                message: message,
                paymentDetails: paymentDetails,
              );
            } else {
              // Build bulk payment details - exclude transaction ID completely
              paymentDetails = {};

              paymentDetails[totalFeesLabel] = '${widget.selectedFees.length}';
              paymentDetails[Utils.getTranslatedLabel(amountKey)] =
                  _formatCurrency(widget.totalAmount);
              paymentDetails[Utils.getTranslatedLabel(paymentMethodKey)] =
                  selectedPaymentMethod!.name ?? unknownPaymentMethod;
              paymentDetails[Utils.getTranslatedLabel(statusKey)] =
                  Utils.getTranslatedLabel(pendingKey).toUpperCase();

              _showSuccessDialog(
                title: bulkPaymentSubmittedSuccessfully,
                message: message,
                paymentDetails: paymentDetails,
              );
            }
          } else if (state is PaymentSubmissionFailure) {
            // Handle payment submission failure
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background decoration
            ...List.generate(2, (index) {
              return Positioned(
                top: 150 + (index * 300),
                right: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  ),
                ),
              );
            }),

            // Main content
            Column(
              children: [
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
                          screenTitle,
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: Utils.screenTitleFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 30,
                      left: 20,
                      right: 20,
                      bottom: 30, // Normal padding
                    ),
                    children: [
                      // Payment summary
                      _buildSelectedFeesInfo(),

                      // Upload section
                      _buildUploadSection(),

                      // Payment methods section
                      _buildPaymentMethodsSection(paymentMethods),

                      SizedBox(height: 24),

                      // Button as part of content (not floating)
                      SafeArea(
                        child: BlocBuilder<PaymentSubmissionCubit,
                            PaymentSubmissionState>(
                          builder: (context, state) {
                            final isSubmitting =
                                state is PaymentSubmissionInProgress;
                            final canProceed = _canProceedPayment();
                            final isEnabled = canProceed && !isSubmitting;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Hint message when disabled
                                if (!isEnabled && !isSubmitting)
                                  Animate(
                                    effects: [
                                      FadeEffect(
                                          duration:
                                              Duration(milliseconds: 300)),
                                      SlideEffect(
                                        begin: Offset(0, -0.2),
                                        duration: Duration(milliseconds: 300),
                                      ),
                                    ],
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      margin: EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _getButtonHintMessage(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Main button
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: ElevatedButton(
                                    onPressed:
                                        isEnabled ? _processPayment : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.grey.shade400,
                                      disabledForegroundColor: Colors.white70,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: isEnabled ? 8 : 2,
                                      shadowColor: isEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isSubmitting) ...[
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            submittingPayment,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ] else ...[
                                          Icon(
                                            isEnabled
                                                ? Icons.payment_rounded
                                                : Icons.lock_outline,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            widget.selectedFees.length > 1
                                                ? submitBulkPayment
                                                : submitPayment,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(List<PaymentMethod> paymentMethods) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethodsTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      paymentMethodsSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (paymentMethods.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      noPaymentMethodsAvailable,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),
          ],
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
