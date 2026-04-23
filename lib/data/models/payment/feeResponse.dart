class FeeResponse {
  final bool error;
  final String message;
  final FeeData data;
  final int code;

  FeeResponse({
    required this.error,
    required this.message,
    required this.data,
    required this.code,
  });

  factory FeeResponse.fromJson(Map<String, dynamic> json) {
    return FeeResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: FeeData.fromJson(json['data'] ?? {}),
      code: json['code'] ?? 200,
    );
  }

  Map<String, dynamic> toJson() => {
        'error': error,
        'message': message,
        'data': data.toJson(),
        'code': code,
      };
}

class FeeData {
  final List<Bill> bills;
  final List<PaymentMethod> paymentMethods;

  FeeData({
    required this.bills,
    required this.paymentMethods,
  });

  factory FeeData.fromJson(Map<String, dynamic> json) {
    return FeeData(
      bills: ((json['bills'] ?? []) as List)
          .map((e) => Bill.fromJson(Map.from(e ?? {})))
          .toList(),
      paymentMethods: ((json['payment_method'] ?? []) as List)
          .map((e) => PaymentMethod.fromJson(Map.from(e ?? {})))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'bills': bills.map((e) => e.toJson()).toList(),
        'payment_method': paymentMethods.map((e) => e.toJson()).toList(),
      };
}

class Bill {
  final int id;
  final String name;
  final String dueDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final List<PaymentHistory> paymentHistory;

  Bill({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.paymentHistory,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      dueDate: json['due_date'] ?? '',
      totalAmount: double.parse((json['total_amount'] ?? 0).toString()),
      paidAmount: double.parse((json['paid_amount'] ?? 0).toString()),
      remainingAmount: double.parse((json['remaining_amount'] ?? 0).toString()),
      status: json['status'] ?? 'unpaid',
      paymentHistory: ((json['payment_history'] ?? []) as List)
          .map((e) => PaymentHistory.fromJson(Map.from(e ?? {})))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'due_date': dueDate,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'remaining_amount': remainingAmount,
        'status': status,
        'payment_history': paymentHistory.map((e) => e.toJson()).toList(),
      };

  // Helper methods
  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
  bool get isPartiallyPaid => status == 'partially_paid';
  
  bool get isOverdue {
    try {
      final now = DateTime.now();
      final due = DateTime.parse(dueDate);
      return now.isAfter(due) && !isPaid;
    } catch (e) {
      return false;
    }
  }

  String get formattedDueDate {
    try {
      final date = DateTime.parse(dueDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dueDate;
    }
  }

  double get paymentPercentage {
    if (totalAmount == 0) return 0;
    return (paidAmount / totalAmount) * 100;
  }
}

class PaymentMethod {
  final int id;
  final String name;
  final String accountNumber;
  final String accountHolder;
  final String? image;
  final String createdAt;
  final String updatedAt;
  final String imageUrl;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.accountHolder,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountHolder: json['account_holder'] ?? '',
      image: json['image'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        'image': image,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'image_url': imageUrl,
      };

  // Helper methods
  String get fullImageUrl {
    if (image != null && image!.isNotEmpty) {
      return imageUrl + image!;
    }
    return imageUrl;
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return accountNumber.replaceRange(
      4,
      accountNumber.length - 4,
      '*' * (accountNumber.length - 8),
    );
  }
}

class PaymentHistory {
  final int? id;
  final double? amount;
  final String? date;
  final String? method;
  final String? reference;
  final String? status;

  PaymentHistory({
    this.id,
    this.amount,
    this.date,
    this.method,
    this.reference,
    this.status,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'],
      amount: json['amount'] != null 
          ? double.parse(json['amount'].toString()) 
          : null,
      date: json['date'],
      method: json['method'],
      reference: json['reference'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date,
        'method': method,
        'reference': reference,
        'status': status,
      };

  String get formattedDate {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date!);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return date!;
    }
  }
}