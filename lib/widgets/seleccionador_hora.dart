
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class SeleccionadorDeHora extends StatefulWidget {
  const SeleccionadorDeHora({
    super.key,
  });

  @override
  State<SeleccionadorDeHora> createState() => _SeleccionadorDeHoraState();
}

class _SeleccionadorDeHoraState extends State<SeleccionadorDeHora> {
  final focusNode1 = FocusNode();
  final focusNode2 = FocusNode();
  final focusNode3 = FocusNode();
  final focusNode4 = FocusNode();
  final focusNode5 = FocusNode();
  final focusNode6 = FocusNode();
  final focusNode7 = FocusNode();
  final focusNode8 = FocusNode();
  final focusNode9 = FocusNode();
  final focusNode10 = FocusNode();
  final focusNode11 = FocusNode();
  final focusNode12 = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode12.requestFocus();
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    focusNode5.dispose();
    focusNode6.dispose();
    focusNode7.dispose();
    focusNode8.dispose();
    focusNode9.dispose();
    focusNode10.dispose();
    focusNode11.dispose();
    focusNode12.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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