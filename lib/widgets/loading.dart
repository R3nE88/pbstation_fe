import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class Loading{

  static void displaySpinLoading(BuildContext context){
    showDialog(
      context: context, 
      builder: (context){    
        return const Stack(
          alignment: Alignment.topRight,
          children: [
            PopScope(
              canPop: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            WindowBar(overlay: true),
          ],
        );
      }
    );
  }

  static void mostrarMensaje(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al hacer clic fuera
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          Navigator.of(context).pop(); // Cierra el cuadro después de 2 segundos
        });

        return Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.containerColor2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    );
  }

}