import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

Future<bool?> mostrarDialogoPermiso(BuildContext context) async {
  final emailController = TextEditingController();
  final pswController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> verificar() async {
    if (!formKey.currentState!.validate()) return;
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    final login = Login();
    bool success = await login.permisoDeAdmin(emailController.text, pswController.text);

    loadingSvc.hide();

    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context, true); // Cierra diálogo con éxito
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

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          AlertDialog(
            title: const Text('🔒 Para continuar ingrese las credenciales\nde algun usuario con permisos elevados.',textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.75)),
            backgroundColor: AppTheme.containerColor1,
            elevation: 6,
            shadowColor: Colors.black54,
            shape: AppTheme.borde,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      autofocus: true,
                      style: AppTheme.textFormField,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Email o Telefono',
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Campo obligatorio' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: pswController,
                      obscureText: true,
                      style: AppTheme.textFormField,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Contraseña',
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Campo obligatorio' : null,
                      onFieldSubmitted: (_) => verificar(),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: verificar,
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const WindowBar(overlay: true),
        ],
      );
    },
  );
}
