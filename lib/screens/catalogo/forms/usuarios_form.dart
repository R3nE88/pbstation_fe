import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
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

class _UsuariosFormState extends State<UsuariosFormDialog> {
  //TODO: si es edit, no introducir la contraseña, en backend no pedir el parametro psw y no retornar psw al crear post

  //Varaibles
  bool _onlyRead = false;
  final _formKey = GlobalKey<FormState>();
  String _titulo = 'Agregar nuevo Usuario';
  /*late final Map<String, String> _dropdownItemsPermisos;
  late final Map<String, String> _dropdownItemsTipo;*/
  late final Map<String, String> _dropdownItemsRol;
  final Map<String, TextEditingController> _controllers = {
    'nombre': TextEditingController(),
    'correo': TextEditingController(),
    'telefono': TextEditingController(),
    'psw': TextEditingController(),
    'psw2': TextEditingController(),
  };
  Permiso? _permisoSeleccionado;
  //bool _permisoEmpty = false;
  TipoUsuario? _tipoSeleccionado;
  //bool _tipoEmpty = false;
  
  String? _rolSeleccionado;
  bool _rolEmpty = false;

  bool _pswIncorrecto = false;
  bool _noPermisoEditarAdmin = false;

  @override
  void initState() {
    super.initState();

    //opciones para DropDownButtons
    _dropdownItemsRol = {
      '1': 'Ventas',
      '2': 'Gerencia',
      '3': 'Administracion',
      '4': 'Maquila',
      if (Login.usuarioLogeado.permisos == Permiso.admin) '5': 'SuperAdmin',
    };

    //Si ya existe un usuario, cargar los datos
    if (widget.usuEdit != null) {
      _onlyRead = widget.onlyRead ?? false;
      _titulo = _onlyRead ? 'Datos del Usuario' : 'Editar Usuario';

      final usuario = widget.usuEdit!;
      _controllers['nombre']!.text = usuario.nombre;
      _controllers['correo']!.text = usuario.correo;
      _controllers['telefono']!.text = '${usuario.telefono ?? ''}';
      _permisoSeleccionado = usuario.permisos;
      _tipoSeleccionado = usuario.rol;

      // Asignar _rolSeleccionado basado en el tipo y permisos
      if (_permisoSeleccionado == Permiso.admin) {
        _rolSeleccionado = '5';
      } else if (_tipoSeleccionado == TipoUsuario.administrativo) {
        _rolSeleccionado = '3';
      } else if (_tipoSeleccionado == TipoUsuario.maquilador) {
        _rolSeleccionado = '4';
      } else if (_tipoSeleccionado == TipoUsuario.vendedor && _permisoSeleccionado == Permiso.elevado) {
        _rolSeleccionado = '2';
      } else {
        _rolSeleccionado = '1'; // Vendedor normal por defecto
      }

      // Prevenir crash y bloquear edición si un usuario que no es Admin está viendo a un usuario SuperAdmin
      if (_rolSeleccionado == '5' && Login.usuarioLogeado.permisos != Permiso.admin) {
        if (!_dropdownItemsRol.containsKey('5')) {
          _dropdownItemsRol['5'] = 'SuperAdmin';
        }
        
        if (widget.onlyRead != true) {
          _noPermisoEditarAdmin = true;
        }
        
        _onlyRead = true;
        _titulo = 'Datos del Usuario (Solo lectura)';
      }
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
    if (!_formKey.currentState!.validate() ||
        _rolSeleccionado == null ) {
      
      if (_rolSeleccionado == null) {
        setState(() {
          _rolEmpty = true;
        });
      }
      return;
    }

    //Definir roles
    switch (_rolSeleccionado) {
      case '1':
        _tipoSeleccionado = TipoUsuario.vendedor;
        _permisoSeleccionado = Permiso.normal;
        break;
      case '2':
        _tipoSeleccionado = TipoUsuario.vendedor;
        _permisoSeleccionado = Permiso.elevado;
        break;
      case '3':
        _tipoSeleccionado = TipoUsuario.administrativo;
        _permisoSeleccionado = Permiso.elevado;
        break;
      case '4':
        _tipoSeleccionado = TipoUsuario.maquilador;
        _permisoSeleccionado = Permiso.normal;
        break;
      case '5':
        _tipoSeleccionado = TipoUsuario.vendedor;
        _permisoSeleccionado = Permiso.admin;
        break;
    }

    if (widget.usuEdit == null) {
      if (_controllers['psw']!.text != _controllers['psw2']!.text) {
        _pswIncorrecto = true;
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
      telefono:
          _controllers['telefono']!.text.isEmpty
              ? null
              : int.tryParse(_controllers['telefono']!.text),
      psw: widget.usuEdit == null ? _controllers['psw']!.text : null,
      rol: _tipoSeleccionado!,
      permisos: _permisoSeleccionado!,
      activo: true,
    );

    final respuesta =
        widget.usuEdit == null
            ? await usuarioSvc.createUsuario(usuario)
            : await usuarioSvc.updateUsuario(usuario, widget.usuEdit!.id!);

    loadingSvc.hide();

    if (!mounted) return;
    if (respuesta == 'exito') {
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder:
            (context) => Stack(
              alignment: Alignment.topRight,
              children: [
                CustomErrorDialog(
                  titulo: 'Hubo un problema al crear',
                  respuesta: respuesta,
                ),
                const WindowBar(overlay: true),
              ],
            ),
      );
    }
  }

  String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return !_pswIncorrecto
          ? 'Por favor ingrese $fieldName'
          : 'Las contraseñas no coinciden';
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
        buildCounter:
            (
              _, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) => null,
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
        backgroundColor:
            AppTheme.isDarkTheme
                ? AppTheme.containerColor1
                : AppTheme.containerColor2,
        title: Text(_titulo),
        content: SizedBox(
          width: 600,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Separador(),
                const SizedBox(height: 15),

                if (_noPermisoEditarAdmin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No tienes los permisos necesarios para modificar este usuario administrador.',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: buildTextFormField(
                        controller: _controllers['nombre']!,
                        labelText: '* Nombre',
                        autoFocus: !_onlyRead && widget.usuEdit == null,
                        readOnly: _onlyRead,
                        maxLength: 40,
                        validator:
                            (value) =>
                                validateRequiredField(value, 'el nombre'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: _controllers['telefono']!,
                        labelText: 'Telefono 10 digitos',
                        readOnly: _onlyRead,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        //validator: (value) => validateRequiredField(value, 'el telefono'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Flexible(
                      flex: 4,
                      child: buildTextFormField(
                        controller: _controllers['correo']!,
                        labelText: '* Correo Electronico',
                        readOnly: _onlyRead,
                        maxLength: 40,
                        validator:
                            (value) => validateRequiredField(
                              value,
                              'el correo electronico',
                            ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    Expanded(
                      flex: 2,
                      child: SearchableDropdown(
                        empty: _rolEmpty,
                        isReadOnly: _onlyRead,
                        items: _dropdownItemsRol,
                        value: _rolSeleccionado,
                        hint: '* Tipo de Usuario',
                        onChanged: (value) {
                          setState(() {
                            _rolEmpty = false;
                            _rolSeleccionado = value;
                          });
                        },
                        searchMoreInfo: false,
                      ),
                    ),
                    /*const SizedBox(width: 15),

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
                    ),*/
                  ],
                ),
                const SizedBox(height: 15),

                widget.usuEdit == null
                    ? Row(
                      children: [
                        Expanded(
                          child: buildTextFormField(
                            controller: _controllers['psw']!,
                            labelText: '* Contraseña',
                            autoFocus: !_onlyRead && widget.usuEdit == null,
                            readOnly: _onlyRead,
                            maxLength: 30,
                            obscureText: true,
                            validator:
                                (value) => validateRequiredField(
                                  value,
                                  'la contraseña',
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextFormField(
                            controller: _controllers['psw2']!,
                            labelText: '* Vuelva a introducir la contraseña',
                            autoFocus: !_onlyRead && widget.usuEdit == null,
                            readOnly: _onlyRead,
                            maxLength: 30,
                            obscureText: true,
                            validator:
                                (value) => validateRequiredField(
                                  value,
                                  'la contraseña',
                                ),
                          ),
                        ),
                      ],
                    )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
        actions: [
          !_onlyRead
              ? ElevatedButton(
                onPressed: () async {
                  await guardarUsuario();
                },
                style: AppTheme.botonGuardar,
                child: const Text('Guardar Usuario'),
              )
              : const SizedBox(),
        ],
      ),
    );
  }
}
