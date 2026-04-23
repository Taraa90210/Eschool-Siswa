import 'package:eschool/utils/system/apiJson.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:flutter/foundation.dart';

/// Custom exception for payment confirmation errors
class PaymentConfirmationException implements Exception {
  final String message;
  PaymentConfirmationException(this.message);

  @override
  String toString() => message;
}

/// Payment Service V2 - Uses ApiJson for proper JSON handling
/// This is a new service that doesn't modify existing payment code
class PaymentConfirmationService {
  /// Confirm payment after gateway success (Xendit, Stripe, Razorpay)
  ///
  /// This method calls POST /api/parent/payment-confirmation with proper headers:
  /// - Authorization: Bearer {token}
  /// - school_code: {school_code}
  /// - Content-Type: application/json
  ///
  /// **Input Validation:**
  /// - Invoice ID must be at least 10 characters
  /// - Fee IDs list must not be empty
  /// - Amount must be greater than 0
  /// - Payment method must be valid (xendit, stripe, razorpay)
  ///
  /// Returns PaymentResponse on success (200)
  /// Throws PaymentConfirmationException on validation errors
  /// Throws ApiException on error (400, 401, 404, 422, 500)
  Future<PaymentResponse> confirmPayment({
    required String invoiceId,
    required String paymentMethod,
    required List<int> feeIds,
    required String status,
    required double amount,
  }) async {
    try {
      // Input Validation
      if (invoiceId.isEmpty || invoiceId.length < 10) {
        throw PaymentConfirmationException(
          'Invoice ID tidak valid. Minimal 10 karakter.',
        );
      }

      if (feeIds.isEmpty) {
        throw PaymentConfirmationException(
          'Tidak ada biaya yang dipilih untuk pembayaran.',
        );
      }

      if (amount <= 0) {
        throw PaymentConfirmationException(
          'Nominal pembayaran tidak valid. Harus lebih dari Rp 0.',
        );
      }

      final validMethods = ['xendit', 'stripe', 'razorpay'];
      if (!validMethods.contains(paymentMethod.toLowerCase())) {
        throw PaymentConfirmationException(
          'Metode pembayaran "$paymentMethod" tidak didukung.',
        );
      }

      if (kDebugMode) {
        print('🔵 PaymentConfirmationService: Confirm Payment Request');
        print('Invoice ID: $invoiceId');
        print('Payment Method: $paymentMethod');
        print('Fee IDs: $feeIds');
        print('Status: $status');
        print('Amount: $amount');
      }

      final result = await ApiJson.post(
        url: Api.confirmPayment,
        body: {
          'invoice_id': invoiceId,
          'payment_method': paymentMethod,
          'fee_ids': feeIds,
          'status': status,
          'amount': amount.toInt(),
        },
      );

      if (kDebugMode) {
        print('🟢 PaymentConfirmationService: Confirmation Success');
        print('Response: $result');
      }

      return PaymentResponse.fromJson(result);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 PaymentConfirmationService: Confirmation Error: $e');
      }
      rethrow;
    }
  }

  /// Get payment transaction details by invoice ID
  ///
  /// This method calls GET /api/payment-confirmation/{invoice_id}
  ///
  /// Returns PaymentDetailsResponse on success (200)
  /// Throws ApiException on error (401, 404, 500)
  Future<PaymentDetailsResponse> getPaymentDetails(String invoiceId) async {
    try {
      if (kDebugMode) {
        print('🔵 PaymentConfirmationService: Get Payment Details');
        print('Invoice ID: $invoiceId');
      }

      final result = await ApiJson.get(
        url: '${Api.confirmPayment}/$invoiceId',
      );

      if (kDebugMode) {
        print('🟢 PaymentConfirmationService: Details Retrieved');
        print('Response: $result');
      }

      return PaymentDetailsResponse.fromJson(result);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 PaymentConfirmationService: Get Details Error: $e');
      }
      rethrow;
    }
  }
}

/// Response model for payment confirmation
class PaymentResponse {
  final bool error;
  final String message;
  final PaymentData? data;

  PaymentResponse({
    required this.error,
    required this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

/// Payment data from confirmation response
class PaymentData {
  final int feesUpdated;
  final String transactionId;
  final String updatedAt;

  PaymentData({
    required this.feesUpdated,
    required this.transactionId,
    required this.updatedAt,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      feesUpdated: json['fees_updated'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fees_updated': feesUpdated,
      'transaction_id': transactionId,
      'updated_at': updatedAt,
    };
  }
}

/// Response model for payment details
class PaymentDetailsResponse {
  final bool error;
  final PaymentDetails? data;

  PaymentDetailsResponse({
    required this.error,
    this.data,
  });

  factory PaymentDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsResponse(
      error: json['error'] ?? false,
      data: json['data'] != null ? PaymentDetails.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'data': data?.toJson(),
    };
  }
}

/// Payment details model
class PaymentDetails {
  final String invoiceId;
  final String transactionId;
  final String paymentMethod;
  final double amount;
  final String status;
  final List<int> feeIds;
  final String confirmedAt;
  final int confirmedBy;

  PaymentDetails({
    required this.invoiceId,
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.feeIds,
    required this.confirmedAt,
    required this.confirmedBy,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      invoiceId: json['invoice_id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      feeIds: List<int>.from(json['fee_ids'] ?? []),
      confirmedAt: json['confirmed_at'] ?? '',
      confirmedBy: json['confirmed_by'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'amount': amount,
      'status': status,
      'fee_ids': feeIds,
      'confirmed_at': confirmedAt,
      'confirmed_by': confirmedBy,
    };
  }
}
