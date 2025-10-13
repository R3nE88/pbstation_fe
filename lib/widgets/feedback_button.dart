import 'package:flutter/material.dart';

class FeedBackButton extends StatefulWidget {
  const FeedBackButton({super.key, required this.onPressed, required this.child, this.valor, this.onlyVertical = false});

  final void Function()? onPressed;
  final Widget child;
  final double? valor;
  final bool onlyVertical;

  @override
  State<FeedBackButton> createState() => _FeedBackButtonState();
}

class _FeedBackButtonState extends State<FeedBackButton> {
  bool _enter = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) {
          setState(() {
            _enter = true;
          });
        },
        onExit: (event) {
           setState(() {
            _enter = false;
          });
        },
        child: !widget.onlyVertical ? Transform.scale(
          scale: _enter == false ? 1 : widget.valor== null ? 1.08 : widget.valor!,
          child: widget.child
        ) : Transform.scale(
          scaleY: _enter == false ? 1 :  1.1,
          scaleX: _enter == false ? 1 :  1.002,
          child: widget.child
        ),
      )
    );
  }
}