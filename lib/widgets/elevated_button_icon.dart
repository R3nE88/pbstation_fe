import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class ElevatedButtonIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const ElevatedButtonIcon({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Transform.translate(
              offset: const Offset(8, 0),
              child: Text(
                '  $text',
                style: TextStyle(
                  color: AppTheme.containerColor1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}
