import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class Loading{

  static void displaySpinLoading(BuildContext context){
    showDialog(
      barrierDismissible: true,
      context: context, 
      builder: (context){    
        return PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    );
  }

  static void mostrarMensaje(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    barrierDismissible: false, // Evita que se cierre al hacer clic fuera
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: 1), () {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Cierra el cuadro después de 2 segundos
      });

      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.containerColor2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            mensaje,
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}

}