import 'package:eschool/data/repositories/payment/paymentConfirmationRepository.dart';
import 'package:eschool/data/services/paymentConfirmationService.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart'; // For ErrorMessageMapper
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class PaymentConfirmationState {}

class PaymentConfirmationInitial extends PaymentConfirmationState {}

class PaymentConfirmationInProgress extends PaymentConfirmationState {}

class PaymentConfirmationSuccess extends PaymentConfirmationState {
  final PaymentResponse paymentResponse;

  PaymentConfirmationSuccess({required this.paymentResponse});
}

class PaymentConfirmationFailure extends PaymentConfirmationState {
  final String errorMessage;

  PaymentConfirmationFailure(this.errorMessage);
}

/// New cubit for payment confirmation using PaymentConfirmationService
/// This properly sends Authorization, school_code, and Content-Type headers
class PaymentConfirmationCubit extends Cubit<PaymentConfirmationState> {
  final PaymentConfirmationRepository _paymentRepository;

  PaymentConfirmationCubit(this._paymentRepository)
      : super(PaymentConfirmationInitial());

  /// Confirm payment after gateway success
  ///
  /// Parameters:
  /// - invoiceId: Invoice ID from payment gateway
  /// - paymentMethod: 'xendit', 'stripe', or 'razorpay'
  /// - feeIds: List of fee IDs to mark as paid
  /// - status: Payment status ('paid' or 'pending')
  /// - amount: Payment amount
  ///
  /// Returns user-friendly error messages via ErrorMessageMapper
  void confirmPayment({
    required String invoiceId,
    required String paymentMethod,
    required List<int> feeIds,
    required String status,
    required double amount,
  }) async {
    try {
      // Guard: Check if cubit is already closed
      if (isClosed) {
        if (kDebugMode) {
          debugPrint('âš ï¸ PaymentConfirmationCubit is closed, skipping emit');
        }
        return;
      }

      emit(PaymentConfirmationInProgress());

      final response = await _paymentRepository.confirmPayment(
        invoiceId: invoiceId,
        paymentMethod: paymentMethod,
        feeIds: feeIds,
        status: status,
        amount: amount,
      );

      // Guard: Check again before emitting success
      if (!isClosed) {
        emit(PaymentConfirmationSuccess(paymentResponse: response));
      }
    } catch (e) {
      // Guard: Check before emitting failure
      if (!isClosed) {
        // Enhancement: Convert technical errors to user-friendly messages
        final friendlyMessage = ErrorMessageMapper.getUserFriendlyMessage(e);
        emit(PaymentConfirmationFailure(friendlyMessage));
      }
    }
  }

  /// Reset state to initial
  void reset() {
    emit(PaymentConfirmationInitial());
  }
}

