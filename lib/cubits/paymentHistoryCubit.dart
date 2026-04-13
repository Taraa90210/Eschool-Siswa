import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/paymentHistory.dart';
import 'dart:convert';

abstract class PaymentHistoryState {}

class PaymentHistoryInitial extends PaymentHistoryState {}

class PaymentHistoryLoading extends PaymentHistoryState {}

class PaymentHistoryLoaded extends PaymentHistoryState {
  final List<PaymentHistory> paymentHistoryList;
  final int billId;

  PaymentHistoryLoaded({
    required this.paymentHistoryList,
    required this.billId,
  });
}

class PaymentHistoryLoadFailure extends PaymentHistoryState {
  final String errorMessage;

  PaymentHistoryLoadFailure({required this.errorMessage});
}

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  PaymentHistoryCubit() : super(PaymentHistoryInitial());

  void loadPaymentHistory({
    required int billId,
    required List<dynamic> rawPaymentHistory,
  }) {
    try {
      emit(PaymentHistoryLoading());

      List<PaymentHistory> parsedHistory = [];

      for (var payment in rawPaymentHistory) {
        try {
          PaymentHistory parsedPayment;

          final String jsonString =
              const JsonEncoder.withIndent('  ').convert(payment);

          // Split by lines and print each line
          final List<String> lines = jsonString.split('\n');
          for (String line in lines) {
            debugPrint(line);
          }

          debugPrint("***");

          // Handle JSON Map data from API
          if (payment is Map<String, dynamic>) {
            // Parse each key from payment_history object
            final String? date = payment['date'] as String?;
            final String? amountStr = payment['amount'] as String?;
            final double? amount = double.tryParse(amountStr ?? '0');
            final String? paymentMethod = payment['payment_method'] as String?;
            final String? status = payment['status'] as String?;
            final String? proofImage = payment['proof_image'] as String?;
            final int? id = payment['id'] as int?;
            final String? transactionId = payment['transaction_id'] as String?;
            final String? notes = payment['notes'] as String?;
            final String? rejectedReason =
                payment['rejected_reason'] as String?;
            final String? approvedBy = payment['approved_by'] as String?;
            final String? approvedAt = payment['approved_at'] as String?;
            final int? billIdFromPayment = payment['bill_id'] as int?;

            // Create PaymentHistory object with parsed variables
            parsedPayment = PaymentHistory(
              id: id,
              status: status,
              amount: amount,
              date: date,
              paymentMethod: paymentMethod,
              proofImage: proofImage,
              transactionId: transactionId,
              notes: notes,
              rejectedReason: rejectedReason,
              approvedBy: approvedBy,
              approvedAt: approvedAt,
              billId: billIdFromPayment ?? billId,
            );
          }
          // Handle generic Map
          else if (payment is Map) {
            Map<String, dynamic> paymentMap =
                Map<String, dynamic>.from(payment);

            // Parse each key from converted map
            final String? date = paymentMap['date'] as String?;
            final String? amountStr = paymentMap['amount'] as String?;
            final double? amount = double.tryParse(amountStr ?? '0');
            final String? paymentMethod =
                paymentMap['payment_method'] as String?;
            final String? status = paymentMap['status'] as String?;
            final String? proofImage = paymentMap['proof_image'] as String?;
            final int? id = paymentMap['id'] as int?;
            final String? transactionId =
                paymentMap['transaction_id'] as String?;
            final String? notes = paymentMap['notes'] as String?;
            final String? rejectedReason =
                paymentMap['rejected_reason'] as String?;
            final String? approvedBy = paymentMap['approved_by'] as String?;
            final String? approvedAt = paymentMap['approved_at'] as String?;
            final int? billIdFromPayment = paymentMap['bill_id'] as int?;

            // Create PaymentHistory object with parsed variables
            parsedPayment = PaymentHistory(
              id: id,
              status: status,
              amount: amount,
              date: date,
              paymentMethod: paymentMethod,
              proofImage: proofImage,
              transactionId: transactionId,
              notes: notes,
              rejectedReason: rejectedReason,
              approvedBy: approvedBy,
              approvedAt: approvedAt,
              billId: billIdFromPayment ?? billId,
            );
          }
          // Handle PaymentHistory objects or other dynamic objects
          else {
            parsedPayment = PaymentHistory.fromDynamic(payment);
          }

          // Add payment if it has valid data
          if (parsedPayment.status != null &&
              parsedPayment.amount != null &&
              parsedPayment.date != null) {
            parsedHistory.add(parsedPayment);
          }
        } catch (e) {
          // Skip invalid payments
          continue;
        }
      }

      // Sort by date (newest first)
      parsedHistory.sort((a, b) {
        final dateA = DateTime.tryParse(a.date ?? '');
        final dateB = DateTime.tryParse(b.date ?? '');

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      emit(PaymentHistoryLoaded(
        paymentHistoryList: parsedHistory,
        billId: billId,
      ));
    } catch (e) {
      emit(PaymentHistoryLoadFailure(errorMessage: e.toString()));
    }
  }

  void addPaymentHistory(PaymentHistory newPayment) {
    final currentState = state;
    if (currentState is PaymentHistoryLoaded) {
      final updatedList =
          List<PaymentHistory>.from(currentState.paymentHistoryList)
            ..add(newPayment);

      // Sort by date (newest first)
      updatedList.sort((a, b) {
        final dateA = DateTime.tryParse(a.date ?? '');
        final dateB = DateTime.tryParse(b.date ?? '');

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      emit(PaymentHistoryLoaded(
        paymentHistoryList: updatedList,
        billId: currentState.billId,
      ));
    }
  }

  void updatePaymentStatus({
    required int paymentId,
    required String newStatus,
    String? rejectedReason,
    String? approvedBy,
  }) {
    final currentState = state;
    if (currentState is PaymentHistoryLoaded) {
      final updatedList = currentState.paymentHistoryList.map((payment) {
        if (payment.id == paymentId) {
          return payment.copyWith(
            status: newStatus,
            rejectedReason: rejectedReason,
            approvedBy: approvedBy,
            approvedAt: newStatus == 'approved'
                ? DateTime.now().toIso8601String()
                : null,
          );
        }
        return payment;
      }).toList();

      emit(PaymentHistoryLoaded(
        paymentHistoryList: updatedList,
        billId: currentState.billId,
      ));
    }
  }

  void clearHistory() {
    emit(PaymentHistoryInitial());
  }
}


