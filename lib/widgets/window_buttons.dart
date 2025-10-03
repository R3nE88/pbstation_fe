import 'package:bitsdojo_window/bitsdojo_window.dart' as window;
import 'package:flutter/material.dart';

class WindowButtons extends StatelessWidget{
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context){
    final buttonColors = window.WindowButtonColors(
      iconNormal: Colors.white,
      mouseOver: const Color.fromARGB(20, 255, 255, 255),
      mouseDown: const Color.fromARGB(96, 37, 37, 37),
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );
    
    return Row(
      children: [
        window.MinimizeWindowButton(colors: buttonColors),
        window.MaximizeWindowButton(colors: buttonColors),
        window.CloseWindowButton(colors: buttonColors),
      ],
    );
  }
}