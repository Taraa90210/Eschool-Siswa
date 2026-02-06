/// Xendit Fee Calculator
///
/// Calculates Xendit transaction fees for different payment methods.
/// Used when implementing "customer absorb fee" model where users pay the fee.
class XenditFeeCalculator {
  /// Fee configuration based on Xendit pricing
  /// Update these values based on your Xendit agreement

  // Virtual Account fees (flat rate)
  static const double virtualAccountFee = 4000.0; // Rp 4.000

  // E-Wallet fees (percentage)
  static const double eWalletFeePercentage = 0.02; // 2%

  // QRIS fee (percentage)
  static const double qrisFeePercentage = 0.007; // 0.7%

  // Credit Card fee (percentage + flat)
  static const double creditCardFeePercentage = 0.029; // 2.9%
  static const double creditCardFlatFee = 2000.0; // Rp 2.000

  // Retail (Alfamart/Indomaret) fee (flat rate)
  static const double retailFee = 5000.0; // Rp 5.000

  // Default fee for invoice (before payment method selected)
  // Use average or highest fee to be safe
  static const double defaultFeePercentage = 0.03; // 3%

  /// Calculate total amount including fee (for invoice creation)
  ///
  /// Since user hasn't selected payment method yet, we use default fee.
  /// This ensures sekolah receives the full base amount.
  static double calculateTotalWithFee(double baseAmount) {
    final fee = baseAmount * defaultFeePercentage;
    return baseAmount + fee;
  }

  /// Calculate fee amount only
  static double calculateFee(double baseAmount) {
    return baseAmount * defaultFeePercentage;
  }

  /// Calculate fee for specific payment method (for display purposes)
  static double calculateFeeForMethod({
    required double baseAmount,
    required String paymentMethod,
  }) {
    switch (paymentMethod.toLowerCase()) {
      case 'virtual_account':
      case 'va':
        return virtualAccountFee;

      case 'ewallet':
      case 'e-wallet':
        return baseAmount * eWalletFeePercentage;

      case 'qris':
        return baseAmount * qrisFeePercentage;

      case 'credit_card':
      case 'card':
        return (baseAmount * creditCardFeePercentage) + creditCardFlatFee;

      case 'retail':
      case 'alfamart':
      case 'indomaret':
        return retailFee;

      default:
        // Use default percentage for unknown methods
        return baseAmount * defaultFeePercentage;
    }
  }

  /// Get fee description for UI display
  static String getFeeDescription(double baseAmount) {
    final fee = calculateFee(baseAmount);
    final feePercentage = (defaultFeePercentage * 100).toStringAsFixed(1);
    return 'Biaya Admin ($feePercentage%) - ${formatCurrency(fee)}';
  }

  /// Format amount to IDR currency
  static String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  /// Get breakdown for display
  static Map<String, double> getBreakdown(double baseAmount) {
    final fee = calculateFee(baseAmount);
    final total = baseAmount + fee;

    return {
      'base_amount': baseAmount,
      'fee': fee,
      'total': total,
    };
  }
}
