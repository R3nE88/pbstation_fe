import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class BodyPadding extends StatelessWidget {
  const BodyPadding({super.key, required this.child, this.hasSubModules=true});
  final Widget child;
  final bool hasSubModules;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 5, left: 54, right: hasSubModules ? 52 : 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: child,
        )
      )
    );
  }
}