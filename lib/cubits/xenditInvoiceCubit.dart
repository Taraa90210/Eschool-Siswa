import 'package:eschool/data/models/xenditInvoice.dart';
import 'package:eschool/data/repositories/xenditRepository.dart';
import 'package:eschool/data/models/paymentMethod.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// States
abstract class XenditInvoiceState {}

class XenditInvoiceInitial extends XenditInvoiceState {}

class XenditInvoiceLoading extends XenditInvoiceState {}

class XenditInvoiceSuccess extends XenditInvoiceState {
  final XenditInvoice invoice;
  final double baseAmount; // Amount before fee
  final double feeAmount; // Xendit fee
  final double totalAmount; // Amount + fee

  XenditInvoiceSuccess(
    this.invoice, {
    required this.baseAmount,
    required this.feeAmount,
    required this.totalAmount,
  });
}

class XenditInvoiceFailure extends XenditInvoiceState {
  final String errorMessage;

  XenditInvoiceFailure(this.errorMessage);
}

class XenditInvoiceStatusChecking extends XenditInvoiceState {
  final XenditInvoice currentInvoice;

  XenditInvoiceStatusChecking(this.currentInvoice);
}

class XenditInvoiceStatusUpdated extends XenditInvoiceState {
  final XenditInvoice invoice;

  XenditInvoiceStatusUpdated(this.invoice);
}

// Cubit
class XenditInvoiceCubit extends Cubit<XenditInvoiceState> {
  final XenditRepository _repository;

  XenditInvoiceCubit(this._repository) : super(XenditInvoiceInitial());

  /// Create new Xendit invoice
  ///
  /// Customer Absorb Fee Model: User pays base amount + Xendit fee
  /// Fee is calculated based on selected payment method for accuracy
  Future<void> createInvoice({
    required int schoolId,
    required int studentId,
    required double amount,
    required String email,
    required String description,
    required List<int> feeIds,
    XenditPaymentMethod?
        paymentMethod, // Accept full object to utilize dynamic API fees
  }) async {
    emit(XenditInvoiceLoading());

    try {
      // Calculate fee based on payment method (if provided)
      final baseAmount = amount;
      double feeAmount;

      if (paymentMethod != null) {
        // Use accurate fee from the dynamically parsed object
        feeAmount = paymentMethod.calculateFee(baseAmount);
      } else {
        // Fallback: 3% flat fee jika metode pembayaran tidak dipilih
        feeAmount = baseAmount * 0.03;
      }

      final totalAmount = baseAmount + feeAmount;

      // Create invoice with total amount (base + fee)
      final invoice = await _repository.createInvoice(
        schoolId: schoolId,
        studentId: studentId,
        amount: totalAmount, // User pays this (base + fee)
        baseAmount: baseAmount,
        feeAmount: feeAmount,
        email: email,
        description: description,
        feeIds: feeIds,
        paymentMethods: paymentMethod?.xenditCode != null
            ? [paymentMethod!.xenditCode!]
            : null,
        paymentMethodId: paymentMethod?.id,
      );

      emit(XenditInvoiceSuccess(
        invoice,
        baseAmount: baseAmount,
        feeAmount: feeAmount,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      emit(XenditInvoiceFailure(ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }

  /// Check invoice payment status
  Future<void> checkInvoiceStatus(String invoiceId) async {
    // Keep current invoice while checking
    if (state is XenditInvoiceSuccess) {
      emit(
          XenditInvoiceStatusChecking((state as XenditInvoiceSuccess).invoice));
    }

    try {
      final invoice = await _repository.getInvoiceStatus(invoiceId);

      emit(XenditInvoiceStatusUpdated(invoice));
    } catch (e) {
      emit(XenditInvoiceFailure(ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(XenditInvoiceInitial());
  }
}
