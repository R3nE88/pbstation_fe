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

class _HoverSideMenuState extends State<HoverSideMenu> {
  bool _hovering = false;

  void _onEnter(PointerEnterEvent event){
    if (widget.enabled==true){
      setState(() => _hovering = true);
    }
  } 
  void _onExit(PointerExitEvent event) => setState(() => _hovering = false);

  @override
  Widget build(BuildContext context) {
    // Factor t de 0 a 1 según hover
    final tween = Tween(begin: _hovering ? 1.0 : 0.0, end: _hovering ? 1.0 : 0.0);
    return Positioned(
      bottom:0,
      left: widget.side == MenuSide.left ? 0 : null,
      right: widget.side == MenuSide.right ? 0 : null,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: tween,
            duration: widget.duration,
            builder: (context, t, child) {
              final width = widget.collapsedWidth +
                  (widget.expandedWidth - widget.collapsedWidth) * t;
              final showContent = width >= widget.contentSwitchThreshold;
              
              return ClipRRect(
                child: Stack(
                  alignment: widget.side == MenuSide.right 
                  ? Alignment.topRight
                  : Alignment.topLeft,
                  children: [
                    Transform.translate(
                      offset: Offset(0, widget.side == MenuSide.right ?1.2:0),
                      child: InverseBorder(extraWidth: width, side: widget.side)
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
                            color: widget.enabled==true?Colors.white70:Colors.transparent,
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
