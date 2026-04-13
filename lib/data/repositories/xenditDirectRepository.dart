import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eschool/data/models/xenditInvoice.dart';

/// Direct Xendit API Repository (for testing without backend)
///
/// This repository calls Xendit API directly for demo/testing purposes.
/// In production, use XenditRepository which calls your backend API.
class XenditDirectRepository {
  // ⚠️ SECURITY WARNING: Never hardcode API keys in production!
  // This is ONLY for testing/demo purposes
  // In production, API keys should be stored securely on backend
  static const String _xenditTestApiKey =
      'xnd_development_fNP3jWfjIwCG544DFMPljDoLwjlQwybezqukRijnZG33CyQS4wIDTtGqa7fCK';
  static const String _xenditBaseUrl = 'https://api.xendit.co';

  /// Create invoice directly via Xendit API
  ///
  /// This bypasses your backend and creates invoice directly with Xendit.
  /// Use this ONLY for testing the payment flow without backend.
  Future<XenditInvoice> createInvoice({
    required double amount,
    required double baseAmount,
    required double feeAmount,
    required String externalId,
    required String payerEmail,
    required String description,
    List<String>? paymentMethods,
  }) async {
    try {
      // Prepare request body
      final body = {
        'external_id': externalId,
        'amount': amount.toInt(),
        'payer_email': payerEmail,
        'description': description,
        'invoice_duration': 86400, // 24 hours
        'currency': 'IDR',
        'success_redirect_url': 'https://checkout.xendit.co/payment/success',
        'failure_redirect_url': 'https://checkout.xendit.co/payment/failed',
        if (paymentMethods != null) 'payment_methods': paymentMethods,
      };

      // Create Basic Auth header
      final credentials = base64Encode(utf8.encode('$_xenditTestApiKey:'));

      // Call Xendit API
      final response = await http.post(
        Uri.parse('$_xenditBaseUrl/v2/invoices'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Parse response to XenditInvoice model
        return XenditInvoice(
          id: data['id'],
          externalId: data['external_id'],
          status: data['status'].toString().toLowerCase(),
          amount: double.parse(data['amount'].toString()),
          baseAmount: baseAmount,
          feeAmount: feeAmount,
          invoiceUrl: data['invoice_url'],
          expiryDate: DateTime.parse(data['expiry_date']),
          payerEmail: data['payer_email'],
          description: data['description'],
          createdAt: DateTime.parse(data['created']),
          paidAt: null,
        );
      } else {
        throw Exception('Failed to create invoice: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating Xendit invoice: $e');
    }
  }

  /// Get invoice status directly from Xendit
  Future<XenditInvoice> getInvoiceStatus(String invoiceId) async {
    try {
      final credentials = base64Encode(utf8.encode('$_xenditTestApiKey:'));

      final response = await http.get(
        Uri.parse('$_xenditBaseUrl/v2/invoices/$invoiceId'),
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return XenditInvoice(
          id: data['id'],
          externalId: data['external_id'],
          status: data['status'].toString().toLowerCase(),
          amount: double.parse(data['amount'].toString()),
          baseAmount: double.parse(
              data['amount'].toString()), // Fallback in status check
          feeAmount: 0,
          invoiceUrl: data['invoice_url'],
          expiryDate: DateTime.parse(data['expiry_date']),
          payerEmail: data['payer_email'],
          description: data['description'],
          createdAt: DateTime.parse(data['created']),
          paidAt:
              data['paid_at'] != null ? DateTime.parse(data['paid_at']) : null,
        );
      } else {
        throw Exception('Failed to get invoice status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting invoice status: $e');
    }
  }
}
