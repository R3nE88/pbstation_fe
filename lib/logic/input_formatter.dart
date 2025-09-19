import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatos{
  static final numero = NumberFormat.currency(decimalDigits: 0, locale: 'es_MX', symbol: '');
  static final decimal = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: '');
  static final moneda = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: '\$');
  static final pesos = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: 'MX\$');
  static final dolares = NumberFormat.currency(decimalDigits: 2, locale: 'en_US', symbol: 'US\$');
}

class MoneyInputFormatter extends TextInputFormatter { //Formatear dinero con $ y , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    newFormatted = '\$$newFormatted';

    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}

class PesosInputFormatter extends TextInputFormatter { //Formatear dinero con $ y , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    newFormatted = 'MX\$$newFormatted';

    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}

class DolaresInputFormatter extends TextInputFormatter { //Formatear dinero con $ y , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    newFormatted = 'US\$$newFormatted';

    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}

class NumericFormatter extends TextInputFormatter { //Formatear numeros enteros con , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (RegExp(r'\.').allMatches(digitsOnly).isNotEmpty) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter { //Formatear numeros decimales con , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}
