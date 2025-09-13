
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class SimpleLoading extends StatelessWidget {
  const SimpleLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppTheme.primario1));
  }
}