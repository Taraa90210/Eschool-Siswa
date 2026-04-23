class PaymentHistory {
  final int? id;
  final String? status;
  final double? amount;
  final String? date;
  final String? paymentMethod;
  final int? paymentMethodId;
  final String? proofImage;
  final String? transactionId;
  final String? notes;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectedReason;
  final int? billId;

  PaymentHistory({
    this.id,
    this.status,
    this.amount,
    this.date,
    this.paymentMethod,
    this.paymentMethodId,
    this.proofImage,
    this.transactionId,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.rejectedReason,
    this.billId,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    print('PaymentHistory.fromJson called with: $json');

    // Handle different possible field names for payment_method
    String? paymentMethod;
    if (json['payment_method'] != null) {
      paymentMethod = json['payment_method'] as String?;
    } else if (json['paymentMethod'] != null) {
      paymentMethod = json['paymentMethod'] as String?;
    } else if (json['method'] != null) {
      paymentMethod = json['method'] as String?;
    }

    // Handle different possible field names for proof_image
    String? proofImage;
    if (json['proof_image'] != null) {
      proofImage = json['proof_image'] as String?;
    } else if (json['proofImage'] != null) {
      proofImage = json['proofImage'] as String?;
    } else if (json['image'] != null) {
      proofImage = json['image'] as String?;
    } else if (json['paymentProof'] != null) {
      proofImage = json['paymentProof'] as String?;
    }

    var result = PaymentHistory(
      id: json['id'] as int?,
      status: json['status'] as String?,
      amount: _parseDouble(json['amount']),
      date: json['date'] as String? ?? json['created_at'] as String?,
      paymentMethod: paymentMethod,
      paymentMethodId: json['payment_method_id'] != null
          ? int.tryParse(json['payment_method_id'].toString())
          : null,
      proofImage: proofImage,
      transactionId:
          json['transaction_id'] as String? ?? json['trx_id'] as String?,
      notes: json['notes'] as String? ?? json['description'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] as String?,
      rejectedReason: json['rejected_reason'] as String? ??
          json['reject_reason'] as String?,
      billId: json['bill_id'] as int?,
    );

    print('PaymentHistory.fromJson result:');
    print('  - status: ${result.status}');
    print('  - amount: ${result.amount}');
    print('  - date: ${result.date}');
    print('  - paymentMethod: ${result.paymentMethod}');
    print('  - proofImage: ${result.proofImage}');

    return result;
  }

  // Handle dynamic objects from existing API
  factory PaymentHistory.fromDynamic(dynamic payment) {
    if (payment == null) return PaymentHistory();

    try {
      print('=== PaymentHistory.fromDynamic ===');
      print('Payment type: ${payment.runtimeType}');
      print('Payment: $payment');

      Map<String, dynamic> jsonData = {};

      // Check if it's already a Map
      if (payment is Map<String, dynamic>) {
        print('Payment is already a Map<String, dynamic>');
        jsonData = payment;
      } else if (payment is Map) {
        print('Payment is a Map, converting to Map<String, dynamic>');
        jsonData = Map<String, dynamic>.from(payment);
      } else {
        print('Payment is not a Map, trying to extract properties');

        // Try to call toJson() first
        try {
          var toJsonResult = payment.toJson();
          if (toJsonResult is Map<String, dynamic>) {
            jsonData = toJsonResult;
            print('Successfully got JSON from toJson(): $jsonData');
          } else if (toJsonResult is Map) {
            jsonData = Map<String, dynamic>.from(toJsonResult);
            print('Converted toJson() result: $jsonData');
          }
        } catch (e) {
          print('toJson() method failed: $e');

          // Manual property extraction as fallback
          try {
            dynamic paymentDynamic = payment;

            // Extract basic properties with error handling
            try {
              if (paymentDynamic.status != null) {
                jsonData['status'] = paymentDynamic.status.toString();
              }
            } catch (e) {
              print('Could not extract status: $e');
            }

            try {
              if (paymentDynamic.amount != null) {
                jsonData['amount'] = paymentDynamic.amount.toString();
              }
            } catch (e) {
              print('Could not extract amount: $e');
            }

            try {
              if (paymentDynamic.date != null) {
                jsonData['date'] = paymentDynamic.date.toString();
              }
            } catch (e) {
              print('Could not extract date: $e');
            }

            // Try multiple field names for payment method
            try {
              var pm = paymentDynamic.paymentMethod ??
                  paymentDynamic.payment_method ??
                  paymentDynamic.method;
              if (pm != null) {
                jsonData['payment_method'] = pm.toString();
              }
              if (paymentDynamic.paymentMethodId != null) {
                jsonData['payment_method_id'] = paymentDynamic.paymentMethodId;
              } else if (paymentDynamic.payment_method_id != null) {
                jsonData['payment_method_id'] =
                    paymentDynamic.payment_method_id;
              }
            } catch (e) {
              print('Could not extract payment_method: $e');
            }

            // Try multiple field names for proof image
            try {
              var pi = paymentDynamic.proofImage ??
                  paymentDynamic.proof_image ??
                  paymentDynamic.image ??
                  paymentDynamic.paymentProof;
              if (pi != null) {
                jsonData['proof_image'] = pi.toString();
              }
            } catch (e) {
              print('Could not extract proof_image: $e');
            }

            print('Manual extraction completed: $jsonData');
          } catch (e) {
            print('Manual property extraction failed: $e');
          }
        }
      }

      print('Final jsonData for fromJson: $jsonData');
      return PaymentHistory.fromJson(jsonData);
    } catch (e) {
      print('Error in PaymentHistory.fromDynamic: $e');
      return PaymentHistory();
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  PaymentHistory copyWith({
    int? id,
    String? status,
    double? amount,
    String? date,
    String? paymentMethod,
    String? proofImage,
    String? transactionId,
    String? notes,
    String? approvedBy,
    String? approvedAt,
    String? rejectedReason,
    int? billId,
  }) {
    return PaymentHistory(
      id: id ?? this.id,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      proofImage: proofImage ?? this.proofImage,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      billId: billId ?? this.billId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'amount': amount,
      'date': date,
      'payment_method': paymentMethod,
      'payment_method_id': paymentMethodId,
      'proof_image': proofImage,
      'transaction_id': transactionId,
      'notes': notes,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejected_reason': rejectedReason,
      'bill_id': billId,
    };
  }

  @override
  String toString() {
    return 'PaymentHistory(id: $id, status: $status, amount: $amount, date: $date, paymentMethod: $paymentMethod, proofImage: $proofImage)';
  }
}
