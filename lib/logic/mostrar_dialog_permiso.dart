import 'package:flutter/material.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

Future<bool?> mostrarDialogoPermiso(BuildContext context) async {
  final emailController = TextEditingController();
  final pswController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> verificar() async {
    if (!formKey.currentState!.validate()) return;
    Loading.displaySpinLoading(context);

    final login = Login();
    bool success = await login.permisoDeAdmin(emailController.text, pswController.text);

    if (!context.mounted) return;
    Navigator.pop(context); // Cierra loading

    if (success) {
      Navigator.pop(context, true); // Cierra diálogo con éxito
    } else {
      showDialog(
        context: context,
        builder: (context) => Stack(
          alignment: Alignment.topRight,
          children: [
            CustomErrorDialog(
              titulo: '',
              respuesta: 'Correo o contraseña inválidos o\npermisos insuficientes.'
            ),
            const WindowBar(overlay: true),
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
            title: const Text(
              'Ingresa las credenciales de un administrador para continuar.',
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(0.9),
            ),
            backgroundColor: AppTheme.containerColor2,
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
                        hintText: 'Email',
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Campo obligatorio' : null,
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
