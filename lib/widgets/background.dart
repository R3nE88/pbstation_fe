import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class Background extends StatelessWidget {

    final BoxDecoration boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.1,0.9],
        colors: [
          AppTheme.azulPrimario2,
          AppTheme.azulPrimario1,
        ]
      )
    );

    final BoxDecoration boxDecoration2 = const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        stops: [0.1,0.9],
        colors: [
          Color.fromARGB(255, 227, 247, 255),
          Color.fromARGB(255, 160, 201, 255),
        ]
      )
    );

  Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: boxDecoration,
        ),

        const Positioned(
          top: -100,
          left: -30,
          child: _Box(48.0,Color.fromARGB(30, 99, 180, 255),Color.fromARGB(123, 32, 103, 255))
        ),

        const Positioned(
          bottom: -100,
          right: -80,
          child: _Box(68.5,Color.fromARGB(50, 63, 162, 255),Color.fromARGB(167, 73, 158, 255))
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