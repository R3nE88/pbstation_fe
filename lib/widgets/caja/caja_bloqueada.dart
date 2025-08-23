import 'package:flutter/material.dart';

class CajaBloqueada extends StatelessWidget {
  const CajaBloqueada({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(80),
      child: ColoredBox(color: Colors.red),
    );
  }
}