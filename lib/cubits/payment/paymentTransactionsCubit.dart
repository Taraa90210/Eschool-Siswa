import 'package:eschool/data/repositories/payment/paymentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PaymentTransactionsState {}

class PaymentTransactionsInitial extends PaymentTransactionsState {}

class PaymentTransactionsFetchInProgress extends PaymentTransactionsState {}

class PaymentTransactionsFetchSuccess extends PaymentTransactionsState {
  final List<dynamic> paymentTransactions;

  PaymentTransactionsFetchSuccess({required this.paymentTransactions});
}

class PaymentTransactionsFetchFailure extends PaymentTransactionsState {
  final String errorMessage;

  PaymentTransactionsFetchFailure(this.errorMessage);
}

class PaymentTransactionsCubit extends Cubit<PaymentTransactionsState> {
  final PaymentRepository _paymentRepository;

  PaymentTransactionsCubit(this._paymentRepository)
      : super(PaymentTransactionsInitial());

  void fetchPaymentTransactions(int? studentId) async {
    try {
      emit(PaymentTransactionsFetchInProgress());
      List<dynamic> transactions =
          await _paymentRepository.getTransactions(studentId: studentId);

      emit(PaymentTransactionsFetchSuccess(paymentTransactions: transactions));
    } catch (e) {
      emit(PaymentTransactionsFetchFailure(e.toString()));
    }
  }
}
