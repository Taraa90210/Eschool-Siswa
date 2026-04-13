import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/childFeeDetails.dart';

abstract class StudentFeesState {}

class StudentFeesInitial extends StudentFeesState {}

class StudentFeesLoading extends StudentFeesState {}

class StudentFeesLoaded extends StudentFeesState {
  final List<Bill> bills;
  final List<PaymentMethod> paymentMethods;

  StudentFeesLoaded({
    required this.bills,
    required this.paymentMethods,
  });
}

class StudentFeesLoadFailure extends StudentFeesState {
  final String errorMessage;

  StudentFeesLoadFailure({required this.errorMessage});
}

class PaymentMethod {
  final int id;
  final String name;
  final String accountNumber;
  final String accountHolder;
  final String? image;
  final String? imageUrl;
  final String createdAt;
  final String updatedAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.accountHolder,
    this.image,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolder: json['account_holder'] as String,
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class StudentFeesCubit extends Cubit<StudentFeesState> {
  StudentFeesCubit() : super(StudentFeesInitial());

  void loadStudentFees(Map<String, dynamic> responseData) {
    try {
      emit(StudentFeesLoading());

      // Parse bills
      List<Bill> bills = [];
      if (responseData['data'] != null &&
          responseData['data']['bills'] != null) {
        final billsList = responseData['data']['bills'] as List;
        for (var billData in billsList) {
          try {
            // Parse each bill key
            final int id = billData['id'] as int;
            final String name = billData['name'] as String? ?? '';
            final String? dueDate = billData['due_date'] as String?;
            final String originalAmountStr =
                billData['original_amount'] as String? ?? '0';
            final double originalAmount =
                double.tryParse(originalAmountStr) ?? 0.0;
            final String type = billData['type'] as String? ?? '';
            final int totalAmount = billData['total_amount'] as int? ?? 0;
            final int paidAmount = billData['paid_amount'] as int? ?? 0;
            final int remainingAmount =
                billData['remaining_amount'] as int? ?? 0;
            final String status = billData['status'] as String? ?? 'unpaid';

            // Note: discount and penalty are passed as raw Map to Bill constructor
            // (same format used by Bill.fromJson for consistency)

            // Parse payment history
            // Parse payment history
            List<PaymentHistory> paymentHistory = [];
            if (billData['payment_history'] != null) {
              final paymentHistoryList = billData['payment_history'] as List;
              for (var paymentData in paymentHistoryList) {
                try {
                  final String? date = paymentData['date'] as String?;
                  final String? amountStr = paymentData['amount'] as String?;
                  final double? amount = double.tryParse(amountStr ?? '0');
                  final String? paymentMethod =
                      paymentData['payment_method'] as String?;
                  final String? status = paymentData['status'] as String?;
                  final String? proofImage =
                      paymentData['proof_image'] as String?;

                  paymentHistory.add(PaymentHistory(
                    date: date,
                    amount: amount,
                    paymentMethod: paymentMethod,
                    status: status,
                    proofImage: proofImage,
                    id: id,
                  ));
                } catch (e) {
                  continue; // Skip invalid payment history
                }
              }
            }
            bills.add(Bill(
              id: id,
              name: name,
              dueDate: dueDate,
              originalAmount: originalAmount,
              type: type,
              discount: billData['discount'] as Map<String, dynamic>?,
              penalty: billData['penalty'] as Map<String, dynamic>?,
              totalAmount: totalAmount.toDouble(),
              paidAmount: paidAmount.toDouble(),
              remainingAmount: remainingAmount.toDouble(),
              status: status,
              paymentHistory: paymentHistory,
            ));
          } catch (e) {
            continue; // Skip invalid bills
          }
        }
      }

      // Parse payment methods
      List<PaymentMethod> paymentMethods = [];
      if (responseData['data'] != null &&
          responseData['data']['payment_method'] != null) {
        final paymentMethodsList =
            responseData['data']['payment_method'] as List;
        for (var methodData in paymentMethodsList) {
          try {
            paymentMethods.add(PaymentMethod.fromJson(methodData));
          } catch (e) {
            continue; // Skip invalid payment methods
          }
        }
      }

      emit(StudentFeesLoaded(
        bills: bills,
        paymentMethods: paymentMethods,
      ));
    } catch (e) {
      emit(StudentFeesLoadFailure(errorMessage: e.toString()));
    }
  }

  void refreshFees() {
    emit(StudentFeesInitial());
  }

  void updateBillStatus(int billId, String newStatus) {
    final currentState = state;
    if (currentState is StudentFeesLoaded) {
      final updatedBills = currentState.bills.map((bill) {
        if (bill.id == billId) {
          return Bill(
            id: bill.id,
            name: bill.name,
            dueDate: bill.dueDate,
            originalAmount: bill.originalAmount,
            type: bill.type,
            discount: bill.discount,
            penalty: bill.penalty,
            totalAmount: bill.totalAmount,
            paidAmount: bill.paidAmount,
            remainingAmount: bill.remainingAmount,
            status: newStatus,
            paymentHistory: bill.paymentHistory,
          );
        }
        return bill;
      }).toList();

      emit(StudentFeesLoaded(
        bills: updatedBills,
        paymentMethods: currentState.paymentMethods,
      ));
    }
  }
}
