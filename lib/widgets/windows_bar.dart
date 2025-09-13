// WindowBar Widget
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/window_buttons.dart';

class WindowBar extends StatelessWidget {
  const WindowBar({super.key, required this.overlay});

  final bool overlay;

  @override
  Widget build(BuildContext context) {
    const double height = 35;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: overlay ? Colors.transparent : AppTheme.secundario1,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
      ),
      child: WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MoveWindow(),
                ],
              )
            ),
            WindowButtons(),
          ],
        ),
      ),
    );
  }
}