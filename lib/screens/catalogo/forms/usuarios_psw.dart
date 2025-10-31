import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class UsuariosPswForm extends StatefulWidget {
  const UsuariosPswForm({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<UsuariosPswForm> createState() => _UsuariosPswFormState();
}

class _UsuariosPswFormState extends State<UsuariosPswForm> {
  final _formKey = GlobalKey<FormState>();
  final _psw1Ctlr = TextEditingController();
  final _psw2Ctlr = TextEditingController();
  bool _pswIncorrecto = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Text('Restablecer Contraseña'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _psw1Ctlr,
                      buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      autofocus: true,
                      maxLength: 30,
                      obscureText: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return !_pswIncorrecto ? 'Por favor ingrese una contraseña' : 'Las contraseñas no coinciden';
                        }
                        return null;
                      }
                    ) 
                  ), const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _psw2Ctlr,
                      buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                      decoration: const InputDecoration(
                        labelText: 'Vuelva a introducir la contraseña',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      autofocus: true,
                      maxLength: 30,
                      obscureText: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return !_pswIncorrecto ? 'Por favor ingrese una contraseña' : 'Las contraseñas no coinciden';
                        }
                        return null;
                      }
                    ) 
                  ),
                ],
              )
            ]
          )
        )
      ),
      actions: [
          ElevatedButton(
            onPressed: () async{
              if (!_formKey.currentState!.validate()) return;

              if(_psw1Ctlr.text !=_psw2Ctlr.text){
                _pswIncorrecto=true;
                _psw1Ctlr.clear();
                _psw2Ctlr.clear();
                return;
              }

              final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
              loadingSvc.show();   

              final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
              bool respusta = await usuariosSvc.cambiarPsw(widget.usuarioId, _psw2Ctlr.text);

              loadingSvc.hide();

              if(!context.mounted) return;
              if (respusta){
                Navigator.pop(context);
              }

            }, 
            style: AppTheme.botonGuardar,
            child: const Text('Restablecer')
          )
        ],
    );
  }
}