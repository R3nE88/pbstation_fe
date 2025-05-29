import 'package:flutter/material.dart';

class DiagonalCornerContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double diagonalSize;

  const DiagonalCornerContainer({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.diagonalSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: DiagonalClipper(diagonalSize),
      child: Container(
        color: color,
        child: child,
      ),
    );
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  final double diagonalSize;

  DiagonalClipper(this.diagonalSize);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0); // top-left
    path.lineTo(size.width - diagonalSize, 0); // top before diagonal
    path.lineTo(size.width, diagonalSize); // diagonal corner
    path.lineTo(size.width, size.height); // right edge
    path.lineTo(0, size.height); // bottom edge
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
