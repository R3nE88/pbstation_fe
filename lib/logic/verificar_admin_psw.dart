  import 'package:flutter/material.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/custom_error_dialog.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:pbstation_frontend/widgets/windows_bar.dart';

Future<dynamic> verificarAdminPsw(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  Future<void> submited() async{
    if (!formKey.currentState!.validate()) return;
    Loading.displaySpinLoading(context);

    final login = Login();
    bool success = await login.permisoDeAdmin(Login.usuarioLogeado.correo, controller.text);

    if (success){
      if(!context.mounted) return;
      Navigator.pop(context, true);
      Navigator.pop(context, true);
    } else {
      if(!context.mounted) return;
      Navigator.pop(context, false);
      showDialog(
        context: context,
        builder: (context) => Stack(
          alignment: Alignment.topRight,
          children: [
            CustomErrorDialog(
              titulo: 'No puedes continuar',
              respuesta: 'Correo o contraseña inválidos o\npermisos insuficientes.'
            ),
            const WindowBar(overlay: true),
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
            backgroundColor: AppTheme.containerColor2,
            title: Text('Para continuar ingrese su contraseña\nde Administrador',textAlign: TextAlign.center, textScaler: TextScaler.linear(0.8)),
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
                      decoration: InputDecoration(
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
                          child: Text('Regresar')
                        ),

                        ElevatedButton(
                          onPressed: () => submited(),
                          child: Text('Continuar')
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