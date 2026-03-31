import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat.decimalPattern('id');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    // Format angka
    String formatted = formatter.format(int.parse(digitsOnly));

    // Hitung posisi kursor baru
    int offset = formatted.length - (oldValue.text.length - oldValue.selection.end);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset.clamp(0, formatted.length)),
    );
  }
}
