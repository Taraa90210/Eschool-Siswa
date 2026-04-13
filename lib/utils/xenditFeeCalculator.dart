/// @deprecated
/// Kelas ini sudah tidak digunakan. Logika fee kini ada di:
/// - [XenditPaymentMethod.calculateFee] untuk fee berbasis metode pembayaran
/// - xenditInvoiceCubit.dart untuk fallback 3% flat
///
/// File ini aman untuk dihapus di masa depan.
class XenditFeeCalculator {
  /// Fee configuration based on Xendit pricing
  /// Update these values based on your Xendit agreement

  // Virtual Account fees (flat rate)
  static const double virtualAccountFee = 4000.0; // Rp 4.000

  // Legacy fallback constant; not used when selecting a DB-driven payment method.
  static const double defaultFeePercentage = 0.03; // 3%

  /// Calculate total amount including fee (for invoice creation)
  static double calculateTotalWithFee(double baseAmount) {
    // Legacy fallback, you should ideally use the DB value from XenditPaymentMethod
    final fee = baseAmount * defaultFeePercentage;
    return baseAmount + fee;
  }

  /// Calculate fee amount only
  static double calculateFee(double baseAmount) {
    return baseAmount * defaultFeePercentage;
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
