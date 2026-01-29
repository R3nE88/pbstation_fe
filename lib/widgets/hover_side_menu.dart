import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

enum MenuSide { left, right }

class HoverSideMenu extends StatefulWidget {
  final Widget menuContent;
  final Widget? menuContentColapsed;
  final double collapsedWidth;
  final double expandedWidth;
  final double height;
  final Duration duration;
  final double contentSwitchThreshold;
  final MenuSide side;
  final bool enabled;

  const HoverSideMenu({
    super.key,
    required this.menuContent,
    this.menuContentColapsed,
    this.collapsedWidth = 66,
    this.expandedWidth = 200,
    required this.height,
    this.duration = const Duration(milliseconds: 150),
    this.contentSwitchThreshold = 200,
    this.side = MenuSide.right,
    required this.enabled,
  });

  @override
  State<HoverSideMenu> createState() => _HoverSideMenuState();
}

class _HoverSideMenuState extends State<HoverSideMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late BoxDecoration _gradient;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Animación con curva suave para las transiciones visuales
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _initGradient();
  }

  void _initGradient() {
    _gradient =
        widget.side == MenuSide.left
            ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.1, 0.9],
                colors: [AppTheme.primario2, AppTheme.primario1],
              ),
            )
            : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.1, 0.9],
                colors: [AppTheme.secundario1, AppTheme.secundario2],
              ),
            );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent event) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onExit(PointerExitEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: widget.side == MenuSide.left ? 0 : null,
      right: widget.side == MenuSide.right ? 0 : null,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment:
              widget.side == MenuSide.left
                  ? Alignment.topLeft
                  : Alignment.topRight,
          children: [
            // InverseBorder solo para lado izquierdo
            if (widget.side == MenuSide.left)
              AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  final width =
                      widget.collapsedWidth +
                      (widget.expandedWidth - widget.collapsedWidth) *
                          _curvedAnimation.value;
                  return InverseBorder(extraWidth: width);
                },
              ),

            // Contenido principal del menú
            MouseRegion(
              onEnter: _onEnter,
              onExit: _onExit,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  final t = _curvedAnimation.value;
                  final width =
                      widget.collapsedWidth +
                      (widget.expandedWidth - widget.collapsedWidth) * t;

                  // Opacidades con mayor overlap para evitar parpadeo
                  // Colapsado: 100% en t=0, empieza a desvanecerse en t=0.3, 0% en t=0.7
                  // Expandido: 0% en t=0.3, gradualmente aparece, 100% en t=0.7
                  final collapsedOpacity = ((0.7 - t) / 0.4).clamp(0.0, 1.0);
                  final expandedOpacity = ((t - 0.3) / 0.4).clamp(0.0, 1.0);

                  return RepaintBoundary(
                    child: Container(
                      width: width,
                      height: widget.height,
                      decoration: _gradient,
                      clipBehavior: Clip.hardEdge,
                      // Stack con crossfade suave usando opacidades superpuestas
                      child: Stack(
                        children: [
                          // Contenido colapsado
                          if (collapsedOpacity > 0)
                            Opacity(
                              opacity: collapsedOpacity,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child:
                                    widget.menuContentColapsed ??
                                    const SizedBox(),
                              ),
                            ),
                          // Contenido expandido
                          if (expandedOpacity > 0)
                            Opacity(
                              opacity: expandedOpacity,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: widget.menuContent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InverseBorder extends StatelessWidget {
  const InverseBorder({super.key, required this.extraWidth});

  final double extraWidth;

  @override
  Widget build(BuildContext context) {
    double size = 35;
    return Row(
      children: [
        SizedBox(width: extraWidth),
        Stack(
          children: [
            Transform.translate(
              offset: const Offset(0, -0.5),
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  color: AppTheme.primario2,
                  border: Border(
                    right: BorderSide(color: AppTheme.secundario1),
                  ),
                ),
              ),
            ),
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: AppTheme.secundario1,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 0),
      ],
    );
  }
}
