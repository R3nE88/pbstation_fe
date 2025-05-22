import 'package:flutter/material.dart';

class ChangeTheme with ChangeNotifier{
  bool _isDarkTheme = true;
  bool get isDarkTheme => _isDarkTheme;

  set isDarkTheme(bool value){
    _isDarkTheme = value;
    notifyListeners();
  }
}