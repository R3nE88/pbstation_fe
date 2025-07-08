import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('CAJA!!!', style: AppTheme.subtituloConstraste),
    );
  }
}