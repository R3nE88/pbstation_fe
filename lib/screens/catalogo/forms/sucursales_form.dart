import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class SucursalesFormDialog extends StatefulWidget {
  const SucursalesFormDialog({super.key, this.sucEdit, this.onlyRead});

  final Sucursales? sucEdit; 
  final bool? onlyRead;

  @override
  State<SucursalesFormDialog> createState() => _SucursalesFormDialogState();
}

class _SucursalesFormDialogState extends State<SucursalesFormDialog> {
  bool _onlyRead = false;
  final _formKey = GlobalKey<FormState>();
  String _titulo = 'Agregar nueva Sucursal';
  final Map<String, TextEditingController> _controllers = {
    'nombre': TextEditingController(),
    'telefono': TextEditingController(),
    'correo': TextEditingController(),
    'direccion': TextEditingController(),
    'ciudad': TextEditingController(),
    'estado': TextEditingController(),
    'pais': TextEditingController(),
  };
  
  @override
  void initState() {
    super.initState();
    if (widget.sucEdit != null) {
      _onlyRead = widget.onlyRead ?? false;
      _titulo = _onlyRead ? 'Datos de la Sucursal' : 'Editar Sucursal';

      final sucursal = widget.sucEdit!;
      _controllers['nombre']!.text = sucursal.nombre;
      _controllers['telefono']!.text = sucursal.telefono;
      _controllers['correo']!.text = sucursal.correo;
      _controllers['direccion']!.text = sucursal.direccion;
      final partes = sucursal.localidad.split(',');
      _controllers['ciudad']!.text = partes[0].trim();
      _controllers['estado']!.text = partes[1].trim();
      _controllers['pais']!.text = partes[2].trim();
    }
  }

  @override
  void dispose() {
    _controllers['nombre']!.dispose();
    _controllers['telefono']!.dispose();
    _controllers['correo']!.dispose();
    _controllers['direccion']!.dispose();
    _controllers['ciudad']!.dispose();
    _controllers['estado']!.dispose();
    _controllers['pais']!.dispose();
    super.dispose();
  }

  //METODOS
  Future<void> guardarSucursal() async {
    if (!_formKey.currentState!.validate()) return;

    final sucursalesServices = Provider.of<SucursalesServices>(context, listen: false);
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();   

    String localidad = "${_controllers['ciudad']!.text}, ${_controllers['estado']!.text}, ${_controllers['pais']!.text}";
    
    final sucursal = Sucursales(
      nombre: _controllers['nombre']!.text,
      correo: _controllers['correo']!.text,
      telefono: _controllers['telefono']!.text,
      direccion: _controllers['direccion']!.text,
      localidad: localidad,
      activo: true,
      prefijoFolio: widget.sucEdit?.prefijoFolio ?? ''

    );

    final respuesta = widget.sucEdit == null
      ? await sucursalesServices.createSucursal(sucursal)
      : await sucursalesServices.updateSucursal(sucursal, widget.sucEdit!.id!);

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
      return 'Por favor ingrese $fieldName';
    }
    return null;
  }

  String? validateRequiredField2(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese $fieldName';
    }
    if (value.length < 3) {
      return 'Ingresa al menos 3 caracteres';
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
    required AutovalidateMode autovalidateMode,
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
        backgroundColor: AppTheme.isDarkTheme ? AppTheme.containerColor1 : AppTheme.containerColor2,
        title: Text(_titulo),
        content: SizedBox(
          width: 550,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Separador(), const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: buildTextFormField(
                        controller: _controllers['nombre']!, 
                        labelText: 'Nombre de la Sucursal',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField(value, 'el nombre'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: _controllers['telefono']!,
                        labelText: 'Telefono 10 digitos',
                        readOnly: _onlyRead,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => validateRequiredField(value, 'el telefono'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['correo']!, 
                        labelText: 'Correo Electronico',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField(value, 'el correo'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['direccion']!, 
                        labelText: 'Direccion de la Sucursal',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField(value, 'la direccion'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      )
                    ),
                  ],
                ), const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['ciudad']!, 
                        labelText: 'Ciudad',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField2(value, 'el correo'),
                        autovalidateMode: AutovalidateMode.onUnfocus,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['estado']!, 
                        labelText: 'Estado',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField2(value, 'la direccion'),
                        autovalidateMode: AutovalidateMode.onUnfocus,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['pais']!, 
                        labelText: 'Pais',
                        autoFocus: !_onlyRead && widget.sucEdit == null,
                        readOnly:  _onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField2(value, 'la direccion'),
                        autovalidateMode: AutovalidateMode.onUnfocus,
                      )
                    ),
                  ],
                ), const SizedBox(height: 15),
              ]
            )
          )
        ),
        actions: [
          !_onlyRead ? ElevatedButton(
            onPressed: () async{
              await guardarSucursal();
            }, 
            style: AppTheme.botonGuardar,
            child: const Text('Guardar Sucursal')
          ) : const SizedBox()
        ],
      )
    );
  }
}