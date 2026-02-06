class XenditInvoice {
  final String id;
  final String externalId;
  final String status;
  final double amount;
  final String invoiceUrl;
  final DateTime expiryDate;
  final String? payerEmail;
  final String? description;
  final DateTime createdAt;
  final DateTime? paidAt;

  XenditInvoice({
    required this.id,
    required this.externalId,
    required this.status,
    required this.amount,
    required this.invoiceUrl,
    required this.expiryDate,
    this.payerEmail,
    this.description,
    required this.createdAt,
    this.paidAt,
  });

  factory XenditInvoice.fromJson(Map<String, dynamic> json) {
    return XenditInvoice(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      status: json['status'] as String,
      amount: double.parse(json['amount'].toString()),
      invoiceUrl: json['invoice_url'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      payerEmail: json['payer_email'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  /// Parse backend API response format
  /// Backend returns: { error: false, invoice_id: "...", invoice_url: "...", ... }
  factory XenditInvoice.fromBackendResponse(Map<String, dynamic> json) {
    return XenditInvoice(
      id: json['invoice_id'] as String, // Backend uses 'invoice_id' not 'id'
      externalId: json['external_id'] as String,
      status: json['status'] as String,
      amount: double.parse(json['amount'].toString()),
      invoiceUrl: json['invoice_url'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      payerEmail: json['payer_email'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'status': status,
      'amount': amount,
      'invoice_url': invoiceUrl,
      'expiry_date': expiryDate.toIso8601String(),
      'payer_email': payerEmail,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isFailed => status.toLowerCase() == 'failed';

  bool get isActive => isPending && DateTime.now().isBefore(expiryDate);

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'paid':
        return 'Sudah Dibayar';
      case 'expired':
        return 'Kadaluarsa';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  XenditInvoice copyWith({
    String? id,
    String? externalId,
    String? status,
    double? amount,
    String? invoiceUrl,
    DateTime? expiryDate,
    String? payerEmail,
    String? description,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return XenditInvoice(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      payerEmail: payerEmail ?? this.payerEmail,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
