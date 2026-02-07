import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/login.dart';
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
  late final Map<String, String> _dropdownItemsPermisos;
  late final Map<String, String> _dropdownItemsTipo;
  final Map<String, TextEditingController> _controllers = {
    'nombre': TextEditingController(),
    'correo': TextEditingController(),
    'telefono': TextEditingController(),
    'psw': TextEditingController(),
    'psw2': TextEditingController(),
  };
  String? _permisoSeleccionado;
  bool _permisoEmpty = false;
  String? _tipoSeleccionado;
  bool _tipoEmpty = false;

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
    }

    //opciones para DropDownButtons
    _dropdownItemsPermisos = {
      for (var permiso in Permiso.values)
        'Nivel ${permiso.nivel}': capitalizarPrimeraLetra(permiso.name)
    };
    if (Login.usuarioLogeado.permisos.nivel == 2) {
      _dropdownItemsPermisos.remove('Nivel ${Permiso.admin.nivel}');
    }

    _dropdownItemsTipo = {
      for (var tipo in TipoUsuario.values)
        '${tipo.index}': capitalizarPrimeraLetra(tipo.name)
    };
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
    if (!_formKey.currentState!.validate() || _permisoSeleccionado==null || _tipoSeleccionado==null){
      if (_permisoSeleccionado==null){setState(() {_permisoEmpty = true;});}
      if (_tipoSeleccionado==null){setState(() {_tipoEmpty = true;});}
      return;
    } 

    if (widget.usuEdit==null){
      if(_controllers['psw']!.text !=_controllers['psw2']!.text){
        _pswIncorrecto=true;
        _controllers['psw']!.clear();
        _controllers['psw2']!.clear();
        return;
      }
    }

    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();   

    final usuario = Usuarios(
      nombre: _controllers['nombre']!.text,
      correo: _controllers['correo']!.text.toLowerCase(),
      telefono: _controllers['telefono']!.text.isEmpty ? null : int.tryParse(_controllers['telefono']!.text),
      psw: widget.usuEdit==null ? _controllers['psw']!.text : null,
      rol: TipoUsuario.values.firstWhere((element) => element.name == _tipoSeleccionado),
      permisos: Permiso.values.firstWhere((element) => element.name == _permisoSeleccionado),
      activo: true
    );

    final respuesta = widget.usuEdit == null
        ? await usuarioSvc.createUsuario(usuario)
        : await usuarioSvc.updateUsuario(usuario, widget.usuEdit!.id!);

    loadingSvc.hide();

    if (!mounted) return;
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
        elevation: 6,
        shadowColor: Colors.black54,
        shape: AppTheme.borde,
        backgroundColor: AppTheme.isDarkTheme ? AppTheme.containerColor1 : AppTheme.containerColor2,
        title: Text(_titulo),
        content: SizedBox(
          width: 600,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Separador(), const SizedBox(height: 15),
                
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
                    ), const SizedBox(width: 15),

                    Expanded(
                      child: SearchableDropdown(
                        empty: _tipoEmpty,
                        isReadOnly: _onlyRead,
                        items: _dropdownItemsTipo,
                        value: _tipoSeleccionado,
                        hint: 'Tipo de usuario',
                        onChanged: (value) {
                          setState(() {
                            _tipoEmpty = false;
                            _tipoSeleccionado = value;
                          });
                        },
                        searchMoreInfo: false,
                      ),
                    ), const SizedBox(width: 15),

                    Expanded(
                      child: SearchableDropdown(
                        empty: _permisoEmpty,
                        isReadOnly: _onlyRead,
                        items: _dropdownItemsPermisos,
                        value: _permisoSeleccionado,
                        hint: 'Permisos',
                        onChanged: (value) {
                          setState(() {
                            _permisoEmpty = false;
                            _permisoSeleccionado = value;
                          });
                        },
                        searchMoreInfo: false,
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