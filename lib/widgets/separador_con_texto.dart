import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class SeparadorConTexto extends StatelessWidget {
  const SeparadorConTexto({
    super.key, required this.texto,
  });

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            height: 1,
            width: 50,
            color: AppTheme.letraClara,
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Text(' $texto ', style: TextStyle(color: AppTheme.letra70, fontWeight: FontWeight.w700))
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.letraClara,
            ),
          ),
        ],
      ),
    );
  }
}