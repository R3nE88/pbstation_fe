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
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: MinimizeWindowButton(colors: buttonColors),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: MaximizeWindowButton(colors: buttonColors)
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: CloseWindowButton(colors: buttonColors)
        ),
      ],
    );
  }
}