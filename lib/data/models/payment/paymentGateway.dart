import 'package:eschool/data/models/payment/paymentMethod.dart';

class PaymentGeteway {
  final int? id;
  final String? paymentMethod;
  final String? apiKey;
  final String? currencyCode;
  final List<XenditPaymentMethod>? allowedMethods;

  PaymentGeteway({
    this.id,
    this.paymentMethod,
    this.apiKey,
    this.currencyCode,
    this.allowedMethods,
  });

  PaymentGeteway copyWith({
    int? id,
    String? paymentMethod,
    String? apiKey,
    String? currencyCode,
    List<XenditPaymentMethod>? allowedMethods,
  }) {
    return PaymentGeteway(
      id: id ?? this.id,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      apiKey: apiKey ?? this.apiKey,
      currencyCode: currencyCode ?? this.currencyCode,
      allowedMethods: allowedMethods ?? this.allowedMethods,
    );
  }

  PaymentGeteway.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        paymentMethod = json['payment_method'] as String?,
        apiKey = json['api_key'] as String?,
        currencyCode = json['currency_code'] as String?,
        allowedMethods = json['allowed_methods'] is List
            ? (json['allowed_methods'] as List)
                .map((e) {
                  if (e is Map<String, dynamic>) {
                    return XenditPaymentMethod.fromJson(e);
                  } else if (e != null) {
                    // Backward compatibility: If the backend still sends a list of IDs instead of objects
                    return XenditPaymentMethod.getById(e);
                  }
                  return null;
                })
                .whereType<XenditPaymentMethod>()
                .toList()
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_method': paymentMethod,
        'api_key': apiKey,
        'currency_code': currencyCode
      };
}
