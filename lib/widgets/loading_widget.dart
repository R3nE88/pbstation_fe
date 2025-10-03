import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Espere un momento\n', style: AppTheme.subtituloConstraste),
        CircularProgressIndicator(color: AppTheme.primario1),
        Text('\ncargando datos...', style: AppTheme.subtituloConstraste),
      ],
    );
  }
}