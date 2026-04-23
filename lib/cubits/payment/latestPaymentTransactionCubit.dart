import 'package:eschool/data/repositories/payment/paymentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LatestPaymentTransactionState {}

class LatestPaymentTransactionInitial extends LatestPaymentTransactionState {}

class LatestPaymentTransactionFetchInProgress
    extends LatestPaymentTransactionState {}

class LatestPaymentTransactionFetchSuccess
    extends LatestPaymentTransactionState {
  List<dynamic> transactions;

  LatestPaymentTransactionFetchSuccess({required this.transactions});
}

class LatestPaymentTransactionFetchFailure
    extends LatestPaymentTransactionState {
  final String errorMessage;

  LatestPaymentTransactionFetchFailure(this.errorMessage);
}

class LatestPaymentTransactionCubit
    extends Cubit<LatestPaymentTransactionState> {
  final PaymentRepository _paymentRepository;

  LatestPaymentTransactionCubit(this._paymentRepository)
      : super(LatestPaymentTransactionInitial());

  void fetchLatestPaymentTransactions(int? studentId) async {
    try {
      emit(LatestPaymentTransactionFetchInProgress());

      emit(LatestPaymentTransactionFetchSuccess(
          transactions:
              await _paymentRepository.getTransactions(fetchLatest: true, studentId: studentId)));
    } catch (e) {
      emit(LatestPaymentTransactionFetchFailure(e.toString()));
    }
  }

  List<dynamic> getLatestPaymentTransactions() {
    return state is LatestPaymentTransactionFetchSuccess
        ? (state as LatestPaymentTransactionFetchSuccess).transactions
        : [];
  }

  bool doesUserHaveLatestPendingTransactions() {
    final transactions = getLatestPaymentTransactions();

    // Check if any payment group has pending payments
    for (var paymentGroup in transactions) {
      final payments = paymentGroup['payments'] as List? ?? [];
      for (var payment in payments) {
        final status = payment['status'] ?? '';
        if (status == 'pending') {
          return true;
        }
      }
    }

    return false;
  }
}
