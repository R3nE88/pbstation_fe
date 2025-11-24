import 'package:flutter/material.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class FacturaGlobalDialog extends StatelessWidget {
  const FacturaGlobalDialog({super.key, required this.caja});

  final Cajas caja;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor1,
      content: const Column(
        mainAxisSize: MainAxisSize.min
      )
    );
  }
}