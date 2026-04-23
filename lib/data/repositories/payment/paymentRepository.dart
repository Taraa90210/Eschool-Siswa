import 'package:eschool/data/models/payment/paymentTransaction.dart';
import 'package:eschool/utils/system/api.dart';
import 'dart:convert';

class PaymentRepository {
  ///[Make it more flexible to support more payment method]
  Future<PaymentTransaction> confirmPayment(
      {required int paymentTransactionId}) async {
    try {
      final result = await Api.get(
          url: Api.confirmPayment,
          useAuthToken: true,
          queryParameters: {"payment_transaction_id": paymentTransactionId});

      return PaymentTransaction.fromJson(Map.from(result['data'] ?? {}));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<dynamic>> getTransactions(
      {bool? fetchLatest, int? studentId}) async {
    try {
      final result = await Api.get(
          url: Api.getTransactions,
          queryParameters: {
            "latest_only": (fetchLatest ?? false) ? 1 : 0,
            if (studentId != null) "student_id": studentId,
          },
          useAuthToken: true);

      // Add this after the API call
      final prettyJson = JsonEncoder.withIndent('  ').convert(result);
      final lines = prettyJson.split('\n');
      for (String line in lines) {
        print(line);
      }

      // Return the raw data array for the new grouped payment structure
      return (result['data'] ?? []) as List;
    } catch (e) {
      print(e.toString());
      throw ApiException(e.toString());
    }
  }
}
