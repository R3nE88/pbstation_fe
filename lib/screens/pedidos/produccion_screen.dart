import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class ProduccionScreen extends StatelessWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BodyPadding(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Produccion',
                style: AppTheme.tituloClaro,
                textScaler: TextScaler.linear(1.7),
              ),
            ],
          )
        ],
      )
    );
  }
}