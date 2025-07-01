
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class SeleccionadorDeHora extends StatelessWidget {
  const SeleccionadorDeHora({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FocusNode focusNode1 = FocusNode();
    final FocusNode focusNode2 = FocusNode();
    final FocusNode focusNode3 = FocusNode();
    final FocusNode focusNode4 = FocusNode();
    final FocusNode focusNode5 = FocusNode();
    final FocusNode focusNode6 = FocusNode();
    final FocusNode focusNode7 = FocusNode();
    final FocusNode focusNode8 = FocusNode();
    final FocusNode focusNode9 = FocusNode();
    final FocusNode focusNode10 = FocusNode();
    final FocusNode focusNode11 = FocusNode();
    final FocusNode focusNode12 = FocusNode();

    focusNode12.requestFocus(); // Solicita el foco al primer nodo

    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mañana', textScaler: TextScaler.linear(1.2) ,style: AppTheme.tituloPrimario),
              HoraSeleccionable(hora: TimeOfDay(hour: 8, minute: 00), focusNode: focusNode1),
              HoraSeleccionable(hora: TimeOfDay(hour: 9, minute: 00), focusNode: focusNode2),
              HoraSeleccionable(hora: TimeOfDay(hour: 10, minute: 00), focusNode: focusNode3),
              HoraSeleccionable(hora: TimeOfDay(hour: 11, minute: 00), focusNode: focusNode4),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Medio Dia', textScaler: TextScaler.linear(1.2), style: AppTheme.tituloPrimario),
              HoraSeleccionable(hora: TimeOfDay(hour: 12, minute: 00), focusNode: focusNode5),
              HoraSeleccionable(hora: TimeOfDay(hour: 13, minute: 00), focusNode: focusNode6),
              HoraSeleccionable(hora: TimeOfDay(hour: 14, minute: 00), focusNode: focusNode7),
              HoraSeleccionable(hora: TimeOfDay(hour: 15, minute: 00), focusNode: focusNode8),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tarde', textScaler: TextScaler.linear(1.2), style: AppTheme.tituloPrimario),
              HoraSeleccionable(hora: TimeOfDay(hour: 16, minute: 00), focusNode: focusNode9),
              HoraSeleccionable(hora: TimeOfDay(hour: 17, minute: 00), focusNode: focusNode10),
              HoraSeleccionable(hora: TimeOfDay(hour: 18, minute: 00), focusNode: focusNode11),
              HoraSeleccionable(hora: TimeOfDay(hour: 19, minute: 00), focusNode: focusNode12),
            ],
          )
        ],
      ),
    );
  }
}

class HoraSeleccionable extends StatelessWidget {
  const HoraSeleccionable({
    super.key,
    required this.hora, 
    required this.focusNode,
  });

  final TimeOfDay hora;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    String formattedTime = '${hora.hourOfPeriod}:${hora.minute.toString().padLeft(2, '0')} ${hora.period == DayPeriod.am ? 'AM' : 'PM'}';

    return ElevatedButton(
      focusNode: focusNode,
      onPressed: () {
        focusNode.requestFocus(); // Solicita el foco al botón
        Navigator.of(context).pop(hora); // Cierra el diálogo y devuelve la hora seleccionada
      },
      style: ButtonStyle(
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          return 0.0;
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppTheme.tablaColor2; // Color cuando está enfocado
          }
          return AppTheme.containerColor1; // Color normal
        }),
      ),
      child: Text(
        formattedTime,
        style: const TextStyle(fontSize: 14, color:AppTheme.letraClara, letterSpacing: 1),
      ),
    );
  }
}