import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/login_screen.dart';
import 'package:pbstation_frontend/screens/screens.dart';


final Map<String, Widget Function(BuildContext)> appRoutes = {
  'login': ( _ ) => const LoginScreen(),
  'home': ( _ ) => HomeScreen()
};