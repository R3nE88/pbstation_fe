import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class Separador extends StatelessWidget {
  const Separador({
    super.key, 
    this.texto,
    this.reducido,
  });

  final String? texto;
  final bool? reducido;

  @override
  Widget build(BuildContext context) {
    late bool realReducido;
    if (reducido!=null){
      if (reducido!){
        realReducido=true;
      } else {
        realReducido=false;
      } 
    } else {
      realReducido=false;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            height: 1,
            width: !realReducido ? 50 : 15,
            color: AppTheme.letraClara,
          ),
          texto!=null ? 
          Transform.translate(
            offset: const Offset(0, -3),
            child: Text(' $texto ', style: const TextStyle(color: AppTheme.letra70, fontWeight: FontWeight.w700))
          ) : Expanded(
            child: Container(
              height: 1,
              color: AppTheme.letraClara,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.letraClara,
            ),
          ),
        ],
      ),
    );
  }
}