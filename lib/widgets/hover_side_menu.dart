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
    required this.enabled
  });

  @override
  State<HoverSideMenu> createState() => _HoverSideMenuState();
}

class _HoverSideMenuState extends State<HoverSideMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final ValueNotifier<double> _widthNotifier;
  late BoxDecoration gradiante;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _widthNotifier = ValueNotifier(widget.collapsedWidth);

    _animation.addListener(() {
      final t = _animation.value;
      _widthNotifier.value = widget.collapsedWidth + (widget.expandedWidth - widget.collapsedWidth) * t;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _widthNotifier.dispose();
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
    final contentSwitchThreshold = widget.contentSwitchThreshold;

    if (widget.side == MenuSide.left){
      gradiante = BoxDecoration(
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
    } else {
      gradiante = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.1,0.9],
          colors: [
            AppTheme.secundario1,
            AppTheme.secundario2,
          ]
        )
      );
    }

    return Positioned(
      bottom: 0,
      left: widget.side == MenuSide.left ? 0 : null,
      right: widget.side == MenuSide.right ? 0 : null,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: widget.side == MenuSide.left ? Alignment.topLeft : Alignment.topRight,
          children: [
            if(widget.side == MenuSide.left)
            ValueListenableBuilder<double>(
              valueListenable: _widthNotifier,
              builder: (context, width, child) {
                return InverseBorder(extraWidth: width);
              },
            ),
            MouseRegion(
              onEnter: _onEnter,
              onExit: _onExit,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final t = _animation.value;
                  final width = widget.collapsedWidth + (widget.expandedWidth - widget.collapsedWidth) * t;
                  final showContent = width >= contentSwitchThreshold;

                  return RepaintBoundary(
                    child: Container(
                      width: width,
                      height: widget.height,
                      decoration: gradiante,
                      child: showContent
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: widget.menuContent,
                            )
                          : Align(
                              alignment: Alignment.topCenter,
                              child: widget.menuContentColapsed ?? SizedBox(),
                            )
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
  const InverseBorder({
    super.key, required this.extraWidth,
  });

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
              offset: Offset(0, -0.5),
              child: Container(
                height: size, 
                width: size,
                decoration: BoxDecoration(
                  color: AppTheme.primario2,
                  border: Border(
                    left: BorderSide.none,
                    bottom: BorderSide.none,
                    right: BorderSide(color: AppTheme.secundario1)
                  )
                ),
              ),
            ),
            Container(
              height: size, 
              width: size,
              decoration:BoxDecoration(
                color: AppTheme.secundario1,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50)
                )
              ),
            ),
          ],
        ),
        const SizedBox(width: 0),
      ],
    );
  }
}
