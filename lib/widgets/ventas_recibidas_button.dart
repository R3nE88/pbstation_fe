import 'package:flutter/material.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class VentasRecibidasButton extends StatefulWidget {
  const VentasRecibidasButton({super.key, required this.onPressed});

  final Function() onPressed;

  @override
  State<VentasRecibidasButton> createState() => _VentasRecibidasButtonState();
}

class _VentasRecibidasButtonState extends State<VentasRecibidasButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.yellow.shade200,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasEnviadasServices>(
      builder: (context, value, child) {
        final tieneVentas = value.ventas.isNotEmpty;

        if (!tieneVentas) {
          _controller.stop();
        } else {
          _controller.repeat(reverse: true);
        }

        return tieneVentas ? AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: const Offset(0, -8),
              child: ElevatedButton( //TODO: Agregar F4 como tecla de acceso directo
                style: ElevatedButton.styleFrom(
                  backgroundColor: tieneVentas ? _colorAnimation.value : Colors.white,
                  elevation: tieneVentas ? 3 : 1,
                ),
                onPressed: tieneVentas ? widget.onPressed : null,
                child: Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(-8, 1),
                      child: Icon(Icons.call_received, color: AppTheme.containerColor1, size: 26),
                    ),
                    Text(
                      'Ventas Recibidas',
                      style: TextStyle(
                        color: AppTheme.containerColor1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tieneVentas)
                      Transform.translate(
                        offset: const Offset(0, -1),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            '   (${value.ventas.length})',
                            style: TextStyle(
                              color: AppTheme.containerColor1.withAlpha(180),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ) : const SizedBox();
      },
    );
  }
}
