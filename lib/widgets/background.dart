import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class Background extends StatelessWidget {

    final BoxDecoration boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.1,0.9],
        colors: [
          AppTheme.primario2,
          AppTheme.primario1,
        ]
      )
    );

    final BoxDecoration boxDecoration2 = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        stops: [0.1,0.9],
        colors: [
          AppTheme.backgroundWidgetColor1,
          AppTheme.backgroundWidgetColor2,
        ]
      )
    );

  Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: boxDecoration,
        ),

        Positioned(
          top: -100,
          left: -30,
          child: _Box(48.0, AppTheme.backgroundWidgetFormColor1,AppTheme.backgroundWidgetFormColor2)
        ),

        Positioned(
          bottom: -100,
          right: -80,
          child: _Box(68.5, AppTheme.backgroundWidgetFormColor3,AppTheme.backgroundWidgetFormColor4)
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {

  final double angle;
  final Color color1;
  final Color color2;

  const _Box(this.angle, this.color1, this.color2);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(125),
          gradient: LinearGradient(
            colors: [
              color1,
              color2,
            ]
          )
        ),
      ),
    );
  }
}