import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class AdvertenciaSucursal extends StatelessWidget {
  const AdvertenciaSucursal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Esta terminal aún no tiene una sucursal asignada.',
              style: AppTheme.tituloClaro.copyWith(
                color: AppTheme.colorContraste
              ),
              textScaler: const TextScaler.linear(1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ), 
        Transform.translate(
          offset: const Offset(0, -5),
          child: Text(
            'Asigne una para realizar ventas.',
            style: AppTheme.tituloClaro.copyWith(
              color: AppTheme.colorContraste
            ),
            textScaler: const TextScaler.linear(1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(text: 'Acceda a  ', style: AppTheme.subtituloConstraste),
              TextSpan(text: 'Catálogo', style: AppTheme.tituloClaro.copyWith(fontSize: 16, color: AppTheme.colorContraste)),
              TextSpan(text: ' > ', style: AppTheme.subtituloConstraste,),
              TextSpan(text: 'Sucursales', style: AppTheme.tituloClaro.copyWith(fontSize: 16, color: AppTheme.colorContraste)),
              TextSpan(text: '  con una cuenta de administrador y asigne una sucursal\na esta terminal para continuar.', style: AppTheme.subtituloConstraste),
            ],
          ),
        )
      ],
    );
  }
}