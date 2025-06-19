import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CustomErrorDialog extends StatelessWidget {
  const CustomErrorDialog({
    super.key,
    required this.respuesta,
  });

  final String respuesta;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      title: Center(child: Text('Hubo un problema al crear', textScaler: TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(respuesta, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Aceptar', style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700))
        )
      ],
    );
  }
}