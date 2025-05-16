import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

enum MenuSide { left, right }

class HoverSideMenu extends StatefulWidget {
  /// Contenido que se muestra dentro del menú cuando está abierto.
  final Widget menuContent;
  /// Ancho de la pestaña cuando está colapsada.
  final double collapsedWidth;
  /// Ancho total del menú cuando está abierto.
  final double expandedWidth;
  final double height;
  final Duration duration;
  /// A partir de qué ancho en píxeles empezamos a mostrar el contenido.
  final double contentSwitchThreshold;
  final MenuSide side;
  final bool enabled;

  final BoxDecoration boxDecoration;

  const HoverSideMenu({
    super.key,
    required this.menuContent,
    this.collapsedWidth = 20,
    this.expandedWidth = 200,
    required this.height,
    this.duration = const Duration(milliseconds: 150),
    this.contentSwitchThreshold = 200,
    this.side = MenuSide.right,
    required this.boxDecoration,
    required this.enabled
  });

  @override
  State<HoverSideMenu> createState() => _HoverSideMenuState();
}

class _HoverSideMenuState extends State<HoverSideMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
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
    final collapsedWidth = widget.collapsedWidth;
    final expandedWidth = widget.expandedWidth;
    final contentSwitchThreshold = widget.contentSwitchThreshold;

    return Positioned(
      bottom: 0,
      left: widget.side == MenuSide.left ? 0 : null,
      right: widget.side == MenuSide.right ? 0 : null,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: Material(
          color: Colors.red,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;
              final width = collapsedWidth + (expandedWidth - collapsedWidth) * t;
              final showContent = width >= contentSwitchThreshold;

              return RepaintBoundary(
                child: Stack(
                  alignment: widget.side == MenuSide.right
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  children: [
                    if (widget.side == MenuSide.right || widget.side == MenuSide.left)
                      Transform.translate(
                        offset: Offset(0, widget.side == MenuSide.right ? 1.2 : 0),
                        child: InverseBorder(extraWidth: width, side: widget.side),
                      ),
                    Container(
                      width: width,
                      height: widget.height,
                      decoration: widget.boxDecoration,
                      child: showContent
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: widget.menuContent,
                            )
                          : Center(
                              child: RotatedBox(
                                quarterTurns: widget.side == MenuSide.right ? 1 : 3,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: widget.enabled ? Colors.white70 : Colors.transparent,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class InverseBorder extends StatelessWidget {
  const InverseBorder({
    super.key, required this.extraWidth, required this.side,
  });

  final double extraWidth;
  final MenuSide side;

  @override
  Widget build(BuildContext context) {
    double size = 35;
    if (side==MenuSide.right){
      size = 10;
    }

    return Row(
      children: [
        SizedBox(width: side==MenuSide.left?extraWidth:0),
        Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -0.5),
              child: Container(
                height: size, 
                width: size,
                decoration: BoxDecoration(
                  color: side==MenuSide.left 
                  ? AppTheme.azulPrimario2
                  : AppTheme.azulSecundario1,
                  border: Border(
                    left: side==MenuSide.right ? BorderSide(color: AppTheme.backgroundColor) : BorderSide.none,
                    bottom: side==MenuSide.right ? BorderSide(color: AppTheme.backgroundColor): BorderSide.none,
                    right: side==MenuSide.left ? BorderSide(color: AppTheme.azulSecundario1): BorderSide.none,
                  )
                ),
              ),
            ),
            Container(
              height: size, 
              width: size,
              decoration: side==MenuSide.left? BoxDecoration(
                color: AppTheme.azulSecundario1,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50)
                )
              ): BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(50)
                )
              ),
            ),
          ],
        ),
        SizedBox(width: side==MenuSide.right?extraWidth:0),
      ],
    );
  }
}
