  import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/loading_state.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/custom_error_dialog.dart';
import 'package:pbstation_frontend/widgets/windows_bar.dart';
import 'package:provider/provider.dart';

Future<bool?> verificarAdminPsw(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  Future<void> submited() async{
    if (!formKey.currentState!.validate()) return;
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    final login = Login();
    bool success = await login.permisoDeAdmin(Login.usuarioLogeado.correo, controller.text);

    loadingSvc.hide();

    if(!context.mounted) return;
    if (success){
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (context) => const Stack(
          alignment: Alignment.topRight,
          children: [
            CustomErrorDialog(
              titulo: 'No puedes continuar',
              respuesta: 'Correo o contraseña inválidos o\npermisos insuficientes.'
            ),
            WindowBar(overlay: true),
          ],
        ),
      );
    }
  }

    return showDialog(
      context: context, 
      builder: (_) => Stack(
        alignment: Alignment.topRight,
        children: [
          AlertDialog(
            elevation: 6,
            shadowColor: Colors.black54,
            backgroundColor: AppTheme.containerColor1,
            shape: AppTheme.borde,
            title: const Text('🔒 Para continuar ingrese su contraseña.',textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.75)),
            content: SizedBox(
              width: 300,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    TextFormField(
                      controller: controller,
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
                          return 'Por favor ingrese la contraseña';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) => submited(),
                    ),const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: (){
                            Navigator.pop(context, false);
                          }, 
                          child: const Text('Regresar')
                        ),

                        ElevatedButton(
                          onPressed: () => submited(),
                          child: const Text('Continuar')
                        ),
                      ],
                    ),
                  ],
                )
              )
            ),
          ),
          const WindowBar(overlay: true),
        ]
      )
    );
  }