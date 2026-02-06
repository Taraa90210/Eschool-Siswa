/// Payment Method Model
///
/// Represents different Xendit payment methods with their respective fees
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final PaymentMethodType type;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
  });

  /// Calculate fee for this payment method
  double calculateFee(double baseAmount) {
    switch (type) {
      case PaymentMethodType.virtualAccount:
        return 4000.0; // Flat Rp 4.000

      case PaymentMethodType.eWallet:
        return baseAmount * 0.02; // 2%

      case PaymentMethodType.qris:
        return baseAmount * 0.007; // 0.7%

      case PaymentMethodType.creditCard:
        return (baseAmount * 0.029) + 2000.0; // 2.9% + Rp 2.000

      case PaymentMethodType.retail:
        return 5000.0; // Flat Rp 5.000
    }
  }

  /// Get total amount (base + fee)
  double getTotalAmount(double baseAmount) {
    return baseAmount + calculateFee(baseAmount);
  }

  /// Format fee description
  String getFeeDescription(double baseAmount) {
    final fee = calculateFee(baseAmount);
    final formatted = _formatCurrency(fee);

    switch (type) {
      case PaymentMethodType.virtualAccount:
        return 'Biaya Admin: $formatted';
      case PaymentMethodType.eWallet:
        return 'Biaya Admin (2%): $formatted';
      case PaymentMethodType.qris:
        return 'Biaya Admin (0.7%): $formatted';
      case PaymentMethodType.creditCard:
        return 'Biaya Admin (2.9% + Rp 2k): $formatted';
      case PaymentMethodType.retail:
        return 'Biaya Admin: $formatted';
    }
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  /// Predefined payment methods
  static List<PaymentMethod> getAllMethods() {
    return [
      PaymentMethod(
        id: 'virtual_account',
        name: 'Virtual Account',
        description: 'BCA, Mandiri, BNI, BRI, Permata',
        icon: '🏦',
        type: PaymentMethodType.virtualAccount,
      ),
      PaymentMethod(
        id: 'ewallet',
        name: 'E-Wallet',
        description: 'DANA, OVO, LinkAja, ShopeePay',
        icon: '💳',
        type: PaymentMethodType.eWallet,
      ),
      PaymentMethod(
        id: 'qris',
        name: 'QRIS',
        description: 'Scan QR dengan aplikasi bank/e-wallet',
        icon: '📱',
        type: PaymentMethodType.qris,
      ),
      PaymentMethod(
        id: 'credit_card',
        name: 'Credit/Debit Card',
        description: 'Visa, Mastercard, JCB',
        icon: '💰',
        type: PaymentMethodType.creditCard,
      ),
      PaymentMethod(
        id: 'retail',
        name: 'Retail',
        description: 'Alfamart, Indomaret',
        icon: '🛒',
        type: PaymentMethodType.retail,
      ),
    ];
  }

  /// Get method by ID
  static PaymentMethod? getById(String id) {
    try {
      return getAllMethods().firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Payment Method Types
enum PaymentMethodType {
  virtualAccount,
  eWallet,
  qris,
  creditCard,
  retail,
}
