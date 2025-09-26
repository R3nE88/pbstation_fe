import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class UsuariosFormDialog extends StatefulWidget {
  const UsuariosFormDialog({super.key, this.usuEdit, this.onlyRead});
  final Usuarios? usuEdit; 
  final bool? onlyRead;

  @override
  State<UsuariosFormDialog> createState() => _UsuariosFormState();
}

class _UsuariosFormState extends State<UsuariosFormDialog> {           //TODO: si es edit, no introducir la contraseña, en backend no pedir el parametro psw y no retornar psw al crear post

  //Varaibles
  bool _onlyRead = false;
  final _formKey = GlobalKey<FormState>();
  String _titulo = 'Agregar nuevo Usuario';
  final Map<String, TextEditingController> _controllers = {
    'nombre': TextEditingController(),
    'correo': TextEditingController(),
    'telefono': TextEditingController(),
    'psw': TextEditingController(),
    'psw2': TextEditingController(),
  };
  bool _administrator = false;
  bool _pswIncorrecto = false;

  @override
  void initState() {
    super.initState();

    if (widget.usuEdit != null) {
      _onlyRead = widget.onlyRead ?? false;
      _titulo = _onlyRead ? 'Datos del Usuario' : 'Editar Usuario';

      final usuario = widget.usuEdit!;
      _controllers['nombre']!.text = usuario.nombre;
      _controllers['correo']!.text = usuario.correo;
      _controllers['telefono']!.text = '${usuario.telefono ?? ''}';
      _administrator = usuario.rol=="admin";
    }
  }

  @override
  void dispose() {
    _controllers['nombre']!.dispose();
    _controllers['correo']!.dispose();
    _controllers['telefono']!.dispose();
    _controllers['psw']!.dispose();
    _controllers['psw2']!.dispose();
    super.dispose();
  }

  //METODOS
  Future<void> guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.usuEdit==null){
      if(_controllers['psw']!.text !=_controllers['psw2']!.text){
        _pswIncorrecto=true;
        _controllers['psw']!.clear();
        _controllers['psw2']!.clear();
        return;
      }
    }

    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    Loading.displaySpinLoading(context);

    final usuario = Usuarios(
      nombre: _controllers['nombre']!.text,
      correo: _controllers['correo']!.text,
      telefono: _controllers['telefono']!.text.isEmpty ? null : int.tryParse(_controllers['telefono']!.text),
      psw: widget.usuEdit==null ? _controllers['psw']!.text : null,
      rol: _administrator==true ? 'admin' : 'empleado',
      activo: true
    );

    final respuesta = widget.usuEdit == null
        ? await usuarioSvc.createUsuario(usuario)
        : await usuarioSvc.updateUsuario(usuario, widget.usuEdit!.id!);

    if (!mounted) return;
    Navigator.pop(context);

    if (respuesta == 'exito') {
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => Stack(
          alignment: Alignment.topRight,
          children: [
            CustomErrorDialog(titulo:'Hubo un problema al crear', respuesta: respuesta),
            const WindowBar(overlay: true),
          ],
        ),
      );
    }
  }

  String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return !_pswIncorrecto ? 'Por favor ingrese $fieldName' : 'Las contraseñas no coinciden';
    }
    return null;
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool autoFocus = false,
    bool readOnly = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return IgnorePointer(
      ignoring: readOnly,
      child: TextFormField(
        autofocus: autoFocus,
        canRequestFocus: !_onlyRead,
        controller: controller,
        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
        readOnly: readOnly,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: AppTheme.labelStyle,
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return FocusScope(
      canRequestFocus: !_onlyRead,
      child: AlertDialog(
        backgroundColor: AppTheme.containerColor2,
        title: Text(_titulo),
        content: SizedBox(
          width: 600,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //const Separador(texto: 'General'),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['nombre']!, 
                        labelText: 'Nombre',
                        autoFocus: !_onlyRead && widget.usuEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 40,
                        validator: (value) => validateRequiredField(value, 'el nombre'),
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['telefono']!,
                        labelText: 'Telefono 10 digitos',
                        readOnly: _onlyRead,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        //validator: (value) => validateRequiredField(value, 'el telefono'),
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Row(
                  children: [
                    Flexible(
                      child: buildTextFormField(
                        controller: _controllers['correo']!,
                        labelText: 'Correo Electronico',
                        readOnly: _onlyRead,
                        maxLength: 40,
                        validator: (value) => validateRequiredField(value, 'el correo electronico'),
                      ),
                    ), 
                    IgnorePointer(
                      ignoring: _onlyRead,
                      child: Row(
                        children: [
                          Checkbox(
                            focusColor: AppTheme.focusColor,
                            value: _administrator,
                            onChanged: (value) {
                              if (_onlyRead==false){
                                setState(() {
                                  _administrator = value ?? false;
                                });
                              }
                            }
                          ),
                          const Text('Permisos de administrador'),
                        ],
                      ),
                    ), 
                  ],
                ), const SizedBox(height: 15),
                
                widget.usuEdit == null ?
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['psw']!, 
                        labelText: 'Contraseña',
                        autoFocus: !_onlyRead && widget.usuEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        obscureText: true,
                        validator: (value) => validateRequiredField(value, 'la contraseña'),
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['psw2']!, 
                        labelText: 'Vuelva a introducir la contraseña',
                        autoFocus: !_onlyRead && widget.usuEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        obscureText: true,
                        validator: (value) => validateRequiredField(value, 'la contraseña'),
                      ),
                    ),
                  ],
                ) : const SizedBox(),
                
    
              ],
            ),
          )
        ),
        actions: [
          !_onlyRead ? ElevatedButton(
            onPressed: () async{
              await guardarUsuario();
            }, 
            style: AppTheme.botonGuardar,
            child: const Text('Guardar Usuario')
          ) : const SizedBox()
        ],
      ),
    );
  }
}