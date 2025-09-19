import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CustomNavigationButton extends StatefulWidget {
  const CustomNavigationButton({
    super.key, required this.label, required this.icon, required this.selected, required this.first, required this.inhabilitado
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool first;
  final bool inhabilitado;

  @override
  State<CustomNavigationButton> createState() => _CustomNavigationButtonState();
}

class _CustomNavigationButtonState extends State<CustomNavigationButton> {
  Color _colorActive = AppTheme.letraClara;
  Color _colorInactive = AppTheme.letra70;
  Color _color = AppTheme.letra70;

  @override
  void initState() {
    super.initState();
    if (widget.inhabilitado){
      _color = Colors.white24;
      _colorInactive = Colors.white24;
      _colorActive = Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 13, top: widget.first ? 0 : 15),
      child: MouseRegion(
        onEnter: widget.selected ? null : (event) {
          setState(() {
            _color = _colorActive;
          });
        },
        onExit: (event) {
          setState(() {
            _color = _colorInactive;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.selected ? _colorActive : Colors.transparent,
                  border: Border.all(color: _color),
                  borderRadius: const BorderRadius.all(Radius.circular(8))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(!widget.inhabilitado ? widget.icon : Icons.lock, color: widget.selected ? AppTheme.primario1 : _color, size: 23),
                )
              ),
              const SizedBox(width: 10),
              Text(
                widget.label, 
                style: TextStyle(
                  color: widget.selected ? _colorActive : _color,
                  fontWeight: FontWeight.w500
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}