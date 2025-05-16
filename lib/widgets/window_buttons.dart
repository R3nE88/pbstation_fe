import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowButtons extends StatelessWidget{
  final buttonColors = WindowButtonColors(
    iconNormal: Colors.white,
    mouseOver: const Color.fromARGB(34, 0, 0, 0),
    mouseDown: const Color.fromARGB(96, 37, 37, 37),
    iconMouseOver: Colors.white,
    iconMouseDown: Colors.white,
  );

  WindowButtons({super.key});

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: buttonColors),
      ],
    );
  }
}