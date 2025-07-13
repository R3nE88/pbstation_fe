import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CustomErrorDialog extends StatelessWidget {
  const CustomErrorDialog({
    super.key,
    required this.respuesta, required this.titulo,
  });

  final String titulo;
  final String respuesta;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      title: Center(child: Text(titulo, textScaler: TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(respuesta, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Aceptar', style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700))
        )
      ],
    );
  }
}