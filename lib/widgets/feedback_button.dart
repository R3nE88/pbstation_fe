import 'package:flutter/material.dart';

class FeedBackButton extends StatefulWidget {
  const FeedBackButton({super.key, required this.onPressed, required this.child, this.valor});

  final void Function()? onPressed;
  final Widget child;
  final double? valor;

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
        child: Transform.scale(
          scale: _enter == false ? 1 : widget.valor== null ? 1.08 : widget.valor!,
          child: widget.child
        ),
      )
    );
  }
}