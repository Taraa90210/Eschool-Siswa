import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

/// Dialog shown when payment is still pending
class PaymentPendingDialog extends StatelessWidget {
  const PaymentPendingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Utils.getTranslatedLabel('paymentPending')),
      content: const Text(
        'Pembayaran Anda masih dalam proses. Silakan selesaikan pembayaran atau cek status nanti.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Utils.getTranslatedLabel('okayKey')),
        ),
      ],
    );
  }
}

/// Dialog shown when invoice has expired
class PaymentExpiredDialog extends StatelessWidget {
  const PaymentExpiredDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invoice Kadaluarsa'),
      content: const Text(
        'Invoice pembayaran telah kadaluarsa. Silakan buat invoice baru.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Close payment screen
          },
          child: Text(Utils.getTranslatedLabel('okayKey')),
        ),
      ],
    );
  }
}

/// Dialog shown when there's an error checking payment status
class PaymentErrorDialog extends StatelessWidget {
  final String message;

  const PaymentErrorDialog({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Utils.getTranslatedLabel('error')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Utils.getTranslatedLabel('okayKey')),
        ),
      ],
    );
  }
}
