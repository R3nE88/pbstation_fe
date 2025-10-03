import 'package:flutter/material.dart';

class ChangeTheme with ChangeNotifier{
  bool isDarkTheme = true;

  void setIsDarkTheme(bool value, bool set){
    isDarkTheme = value;
    if (set==true){
      notifyListeners();
    }
  }
}