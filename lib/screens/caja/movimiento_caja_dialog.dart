import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/movimiento_cajas.dart';
import 'package:pbstation_frontend/screens/caja/forms/movimiento_caja_form.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class MovimientoCajaDialog extends StatefulWidget {
  const MovimientoCajaDialog({super.key});

  @override
  State<MovimientoCajaDialog> createState() => _MovimientoCajaDialogState();
}

class _MovimientoCajaDialogState extends State<MovimientoCajaDialog> {
  final titulo = 'Movimientos';
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const MovimientoCajaForm(isRetiro: false)
                ), 
                child: Text('+ Entrada de Efectivo', textScaler: const TextScaler.linear(0.9))
              ), const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const MovimientoCajaForm(isRetiro: true)
                ), 
                child: Text('- Retiro de Efectivo', textScaler: const TextScaler.linear(0.9))
              ),
            ],
          )
        ],
      ),
      content: SizedBox(
        width: 800,
        child: Consumer<CajasServices>(
          builder: (context, cs, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: AppTheme.tablaColorHeader,
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex:4, child: Text('Usuario', textAlign: TextAlign.center)),
                      Expanded(flex:3, child: Text('Tipo', textAlign: TextAlign.center)),
                      Expanded(flex:4, child: Text('Motivo', textAlign: TextAlign.center)),
                      Expanded(flex:3, child: Text('Monto', textAlign: TextAlign.center)),
                      Expanded(flex:4, child: Text('Fecha', textAlign: TextAlign.center)),
                    ],
                  ),
                ),
            
                
                    Container(
                      height: 200,
                      color: cs.movimientos.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                      child: ListView.builder(
                        itemCount: cs.movimientos.length,
                        itemBuilder: (context, index) {
                          return FilaMovimintos(movimiento: cs.movimientos[index], index: index);
                        },
                      ),
                    ),
                  
            
            
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: AppTheme.tablaColorHeader,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        '  Total: ${cs.movimientos.length}   ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        )
      )
    );
  }
}

class FilaMovimintos extends StatelessWidget {
  const FilaMovimintos({super.key, required this.movimiento, required this.index});

  final MovimientoCajas movimiento;
  final int index;

  @override
  Widget build(BuildContext context) {
    //Conseguir usuario
    final usuariioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final usuarioNombre = usuariioSvc.obtenerNombreUsuarioPorId(movimiento.usuarioId);

    //fecha
    DateTime dt = DateTime.parse(movimiento.fecha);
    final DateFormat fFormatter = DateFormat('dd-MM-yyyy');
    final DateFormat hFormatter = DateFormat('hh:mm a');
    final String fecha = fFormatter.format(dt);
    final String hora = hFormatter.format(dt);

    return Container(
      color: index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(flex:4, child: Text(usuarioNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex:3, child: Text(capitalizarPrimeraLetra(movimiento.tipo), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex:4, child: Text(movimiento.motivo, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex:3, child: Text(Formatos.pesos.format(movimiento.monto), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex:4, child: Row( mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$fecha  ', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: TextScaler.linear(0.8)),
              Text(hora, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: TextScaler.linear(1.05)),
            ],
          )),
        ],
      ),
    );
  }
}