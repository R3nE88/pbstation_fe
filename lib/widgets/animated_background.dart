import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

/// Background con curvas diagonales que se cruzan - movimiento orgánico.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late double _phase1;
  late double _phase2;
  late double _phase3;

  @override
  void initState() {
    super.initState();

    // Fases aleatorias para iniciar en posiciones distintas cada restart
    final random = Random();
    _phase1 = random.nextDouble() * 2 * pi;
    _phase2 = random.nextDouble() * 2 * pi;
    _phase3 = random.nextDouble() * 2 * pi;

    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller1, _controller2, _controller3]),
      builder: (context, child) {
        return CustomPaint(
          painter: _DiagonalWavesPainter(
            progress1: _controller1.value,
            progress2: _controller2.value,
            progress3: _controller3.value,
            phase1: _phase1,
            phase2: _phase2,
            phase3: _phase3,
            baseColor1: AppTheme.primario1,
            baseColor2: AppTheme.primario2,
            waveColor1: AppTheme.backgroundWidgetFormColor1,
            waveColor2: AppTheme.backgroundWidgetFormColor2,
            waveColor3: AppTheme.backgroundWidgetFormColor3,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DiagonalWavesPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;
  final double phase1;
  final double phase2;
  final double phase3;
  final Color baseColor1;
  final Color baseColor2;
  final Color waveColor1;
  final Color waveColor2;
  final Color waveColor3;

  _DiagonalWavesPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    required this.phase1,
    required this.phase2,
    required this.phase3,
    required this.baseColor1,
    required this.baseColor2,
    required this.waveColor1,
    required this.waveColor2,
    required this.waveColor3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo gradiente base
    final basePaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [baseColor2, baseColor1],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Curva 1 - Con fase aleatoria
    _drawDiagonalCurve(
      canvas,
      size,
      startX: -size.width * 0.2,
      startY: size.height * (0.15 + 0.25 * sin(progress1 * pi * 2 + phase1)),
      controlX: size.width * (0.3 + 0.15 * cos(progress1 * pi * 1.5 + phase1)),
      controlY:
          size.height * (0.4 + 0.3 * sin(progress1 * pi * 2.5 + phase1 + 1.2)),
      endX: size.width * 1.2,
      endY: size.height * (0.6 + 0.25 * cos(progress1 * pi * 2 + phase1)),
      color: waveColor1.withValues(alpha: 0.09),
    );

    // Curva 2 - Con fase aleatoria
    _drawDiagonalCurve(
      canvas,
      size,
      startX: -size.width * 0.3,
      startY: size.height * (0.45 + 0.3 * cos(progress2 * pi * 2.2 + phase2)),
      controlX: size.width * (0.5 + 0.2 * sin(progress2 * pi * 1.8 + phase2)),
      controlY:
          size.height * (0.55 + 0.25 * cos(progress2 * pi * 2.3 + phase2)),
      endX: size.width * 1.3,
      endY: size.height * (0.75 + 0.2 * sin(progress2 * pi * 2 + phase2)),
      color: waveColor2.withValues(alpha: 0.18),
    );

    // Curva 3 - Con fase aleatoria
    _drawDiagonalCurve(
      canvas,
      size,
      startX: -size.width * 0.15,
      startY: size.height * (0.7 + 0.2 * sin(progress3 * pi * 2.4 + phase3)),
      controlX: size.width * (0.6 + 0.18 * cos(progress3 * pi * 2 + phase3)),
      controlY:
          size.height * (0.65 + 0.28 * sin(progress3 * pi * 2.6 + phase3)),
      endX: size.width * 1.15,
      endY: size.height * (0.88 + 0.15 * cos(progress3 * pi * 1.9 + phase3)),
      color: waveColor3.withValues(alpha: 1),
    );
  }

  void _drawDiagonalCurve(
    Canvas canvas,
    Size size, {
    required double startX,
    required double startY,
    required double controlX,
    required double controlY,
    required double endX,
    required double endY,
    required Color color,
  }) {
    final path = Path();

    path.moveTo(-50, size.height + 50);
    path.lineTo(startX, size.height + 50);
    path.lineTo(startX, startY);

    path.quadraticBezierTo(controlX, controlY, endX, endY);

    path.lineTo(endX, size.height + 50);
    path.close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalWavesPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 ||
        oldDelegate.progress2 != progress2 ||
        oldDelegate.progress3 != progress3;
  }
}
