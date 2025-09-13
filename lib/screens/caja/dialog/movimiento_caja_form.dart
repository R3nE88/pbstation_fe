import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:provider/provider.dart';

class MovimientoCajaForm extends StatelessWidget {
  const MovimientoCajaForm({super.key, required this.isRetiro});

  final bool isRetiro;


  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController montoCtrl = TextEditingController();
    final TextEditingController motivoCtrl = TextEditingController();

    void submit() async{
      if (formKey.currentState!.validate()){
        Loading.displaySpinLoading(context);  
        MovimientosCajas movimiento = MovimientosCajas(
          usuarioId: Login.usuarioLogeado.id!, 
          monto:  double.parse(montoCtrl.text.replaceAll('MX\$', '').replaceAll(',', '')),
          motivo: motivoCtrl.text, 
          fecha: DateTime.now().toIso8601String(), 
          tipo: isRetiro ? 'retiro' : 'entrada', 
        );
        final cajaSvc = Provider.of<CajasServices>(context, listen: false);
        await cajaSvc.agregarMovimiento(movimiento);
        if(!context.mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      title: Text(
        isRetiro ?
        "Retirar Efectivo" : "Agregar Efectivo"
      ),
      content: SizedBox(
        width: 350,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: true,
                controller: montoCtrl,
                inputFormatters: [ PesosInputFormatter() ],
                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  labelStyle: AppTheme.labelStyle,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un monto';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ), const SizedBox(height: 15),
              TextFormField(
                controller: motivoCtrl,
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  labelStyle: AppTheme.labelStyle,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el motivo';
                  }
                  return null;
                },
                onFieldSubmitted: (value) => submit(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async{
                  submit();
                }, 
                child: Text('Aceptar')
              )
            ],
          )
        )
      )
    );
  }
}