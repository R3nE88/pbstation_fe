import 'package:flutter/material.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class CerrarDialog extends StatelessWidget {
  const CerrarDialog({super.key});
  final titulo = 'Cerrar Caja';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: Text(titulo),

      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          
        )
      )
    );
  }
}
