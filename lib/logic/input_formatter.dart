import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatos{
  static final numero = NumberFormat.currency(decimalDigits: 0, locale: 'es_MX', symbol: '');
  static final decimal = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: '');
  static final moneda = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: '\$');
  static final pesos = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: 'MX\$');
  static final dolares = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: 'MX\$');
}

class MoneyInputFormatter extends TextInputFormatter { //Formatear dinero con $ y , 
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Parte 1: Elimina todo lo que no sea dígito o punto y asegura que solo haya un punto
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Validar que no haya más de un punto
    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue; // Si hay más de un punto, regresamos el valor anterior
    }

    // Parte 2: Formatear con símbolo $ y comas
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Dividir en parte entera y decimal
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear la parte entera con comas
    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    // Combinar partes con el punto final si existe
    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    // Agregar símbolo $
    newFormatted = '\$$newFormatted';

    // Calcular nueva posición del cursor
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
    // Parte 1: Elimina todo lo que no sea dígito o punto y asegura que solo haya un punto
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Validar que no haya más de un punto
    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue; // Si hay más de un punto, regresamos el valor anterior
    }

    // Parte 2: Formatear con símbolo $ y comas
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Dividir en parte entera y decimal
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear la parte entera con comas
    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    // Combinar partes con el punto final si existe
    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    // Agregar símbolo $
    newFormatted = 'MX\$$newFormatted';

    // Calcular nueva posición del cursor
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
    // Parte 1: Elimina todo lo que no sea dígito o punto y asegura que solo haya un punto
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Validar que no haya más de un punto
    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue; // Si hay más de un punto, regresamos el valor anterior
    }

    // Parte 2: Formatear con símbolo $ y comas
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Dividir en parte entera y decimal
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear la parte entera con comas
    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    // Combinar partes con el punto final si existe
    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    // Agregar símbolo $
    newFormatted = 'US\$$newFormatted';

    // Calcular nueva posición del cursor
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
    // Parte 1: Elimina todo lo que no sea dígito o punto y asegura que solo haya un punto
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Validar que no haya más de un punto
    if (RegExp(r'\.').allMatches(digitsOnly).isNotEmpty) {
      return oldValue; // Si hay más de un punto, regresamos el valor anterior
    }

    // Parte 2: Formatear con símbolo $ y comas
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Dividir en parte entera y decimal
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear la parte entera con comas
    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    // Combinar partes con el punto final si existe
    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    // Calcular nueva posición del cursor
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
    // Parte 1: Elimina todo lo que no sea dígito o punto y asegura que solo haya un punto
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Validar que no haya más de un punto
    if (RegExp(r'\.').allMatches(digitsOnly).length > 1) {
      return oldValue; // Si hay más de un punto, regresamos el valor anterior
    }

    // Parte 2: Formatear con símbolo $ y comas
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Dividir en parte entera y decimal
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Formatear la parte entera con comas
    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    // Combinar partes con el punto final si existe
    String newFormatted = formattedInteger + (decimalPart.isNotEmpty ? '.$decimalPart' : (digitsOnly.endsWith('.') ? '.' : ''));

    // Calcular nueva posición del cursor
    int cursorPosition = newValue.selection.baseOffset;
    int offsetChange = newFormatted.length - newValue.text.length;
    int newCursorPosition = cursorPosition + offsetChange;

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, newFormatted.length)),
    );
  }
}
