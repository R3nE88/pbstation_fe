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
      elevation: 6,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: AppTheme.borde,
      title: Center(child: Text(titulo, textScaler: const TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(respuesta, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        Center(
          child: SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Center(child: Text('Regresar'))
            ),
          ),
        )
      ],
    );
  }
}