import 'package:flutter/material.dart';

class CustomNavigationButton extends StatefulWidget {
  const CustomNavigationButton({
    Key? key, required this.label, required this.icon, required this.selected
  }) : super(key: key);

  final String label;
  final IconData icon;
  final bool selected;


  @override
  State<CustomNavigationButton> createState() => _CustomNavigationButtonState();
}

class _CustomNavigationButtonState extends State<CustomNavigationButton> {
  Color colorActive = Colors.white;
  Color colorInactive = Colors.white70;
  
  Color color = Colors.white70;


  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 15, right: 10),
      child: MouseRegion(
        onEnter: widget.selected ? null : (event) {
          
          setState(() {
            color = colorActive;
          });
          
        },
        onExit: (event) {
          
          setState(() {
            
            color = colorInactive;
          });
          
        },
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.selected ? colorActive : Colors.transparent,
                  border: Border.all(color: color),
                  borderRadius: const BorderRadius.all(Radius.circular(8))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(widget.icon, color: widget.selected ? Colors.blue : color, size: 20),
                )
              ),
              const SizedBox(width: 25),
              Text(
                widget.label, 
                style: TextStyle(
                  color: widget.selected ? colorActive : color,
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