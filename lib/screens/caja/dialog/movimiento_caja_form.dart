import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class MovimientoCajaForm extends StatefulWidget {
  const MovimientoCajaForm({super.key, required this.isRetiro});

  final bool isRetiro;

  @override
  State<MovimientoCajaForm> createState() => _MovimientoCajaFormState();
}

class _MovimientoCajaFormState extends State<MovimientoCajaForm> {
  final formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _montoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  void submit() async{
    if (formKey.currentState!.validate()){
      final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
      loadingSvc.show();

      MovimientosCajas movimiento = MovimientosCajas(
        usuarioId: Login.usuarioLogeado.id!, 
        monto:  double.parse(_montoCtrl.text.replaceAll('MX\$', '').replaceAll(',', '')),
        motivo: _motivoCtrl.text, 
        fecha: DateTime.now().toIso8601String(), 
        tipo: widget.isRetiro ? 'retiro' : 'entrada', 
      );

      await Provider.of<CajasServices>(context, listen: false).agregarMovimiento(movimiento);

      loadingSvc.hide();

      if(!mounted) return;
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 6,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: AppTheme.borde,
      title: Text(
        widget.isRetiro ?
        'Retirar Efectivo' : 'Agregar Efectivo'
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
                controller: _montoCtrl,
                inputFormatters: [ PesosInputFormatter() ],
                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                maxLength: 12,
                decoration: const InputDecoration(
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
                controller: _motivoCtrl,
                decoration: const InputDecoration(
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
                child: const Text('Aceptar')
              )
            ],
          )
        )
      )
    );
  }
}