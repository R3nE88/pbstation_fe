import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? message;

  bool get isLoading => _isLoading;

  void show([String? str]) {
    if (_isLoading) return;
    message = str;
    _isLoading = true;
    notifyListeners();
  }
  

  void hide() {
    if (!_isLoading) return;
    message = null;
    _isLoading = false;
    notifyListeners();
  }

  void toggle() {
    _isLoading = !_isLoading;
    notifyListeners();
  }
}
