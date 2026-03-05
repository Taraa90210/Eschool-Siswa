import 'package:eschool/data/services/paymentConfirmationService.dart';
import 'package:eschool/utils/api.dart';

/// Payment Repository V2 - Uses PaymentConfirmationService
/// This is a new repository that doesn't modify existing payment repository
class PaymentConfirmationRepository {
  final PaymentConfirmationService _paymentService =
      PaymentConfirmationService();

  /// Confirm payment after gateway success
  ///
  /// Use this method for payment confirmation after gateway success
  /// (Xendit, Stripe, Razorpay)
  Future<PaymentResponse> confirmPayment({
    required String invoiceId,
    required String paymentMethod,
    required List<int> feeIds,
    required String status,
    required double amount,
  }) async {
    try {
      return await _paymentService.confirmPayment(
        invoiceId: invoiceId,
        paymentMethod: paymentMethod,
        feeIds: feeIds,
        status: status,
        amount: amount,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Get payment details by invoice ID
  Future<PaymentDetailsResponse> getPaymentDetails(String invoiceId) async {
    try {
      return await _paymentService.getPaymentDetails(invoiceId);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
