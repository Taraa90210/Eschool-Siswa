import 'package:eschool/data/models/xenditInvoice.dart';
import 'package:eschool/data/repositories/xenditRepository.dart';
import 'package:eschool/data/models/paymentMethod.dart';
import 'package:eschool/utils/xenditFeeCalculator.dart';
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
    String? paymentMethodId, // Optional: for accurate fee calculation
  }) async {
    emit(XenditInvoiceLoading());

    try {
      // Calculate fee based on payment method (if provided)
      final baseAmount = amount;
      double feeAmount;

      if (paymentMethodId != null) {
        // Use accurate fee for selected payment method
        final method = PaymentMethod.getById(paymentMethodId);
        feeAmount = method?.calculateFee(baseAmount) ??
            XenditFeeCalculator.calculateFee(baseAmount);
      } else {
        // Use default fee if no method selected
        feeAmount = XenditFeeCalculator.calculateFee(baseAmount);
      }

      final totalAmount = baseAmount + feeAmount;

      // Create invoice with total amount (base + fee)
      final invoice = await _repository.createInvoice(
        schoolId: schoolId,
        studentId: studentId,
        amount: totalAmount, // User pays this (base + fee)
        email: email,
        description: description,
        feeIds: feeIds,
      );

      emit(XenditInvoiceSuccess(
        invoice,
        baseAmount: baseAmount,
        feeAmount: feeAmount,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      emit(XenditInvoiceFailure(e.toString()));
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
      emit(XenditInvoiceFailure(e.toString()));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(XenditInvoiceInitial());
  }
}
