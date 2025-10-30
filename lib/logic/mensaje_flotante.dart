import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

void mostrarMensajeFlotante(BuildContext context, String message){
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(child: Text(message)),
      duration: const Duration(seconds: 3),
      backgroundColor: AppTheme.colorError2.withAlpha(200),
      behavior: SnackBarBehavior.floating,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height/2,
        left: 20,
        right: 20,
      ),
    ),
  );
}