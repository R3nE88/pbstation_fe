import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class SucursalesFormDialog extends StatefulWidget {
  const SucursalesFormDialog({super.key, this.sucEdit, this.onlyRead});

  @override
  State<SucursalesFormDialog> createState() => _SucursalesFormDialogState();

  final Sucursales? sucEdit; 
  final bool? onlyRead;
}

class _SucursalesFormDialogState extends State<SucursalesFormDialog> {
  bool onlyRead = false;
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'nombre': TextEditingController(),
    'telefono': TextEditingController(),
    'correo': TextEditingController(),
    'direccion': TextEditingController(),
    'ciudad': TextEditingController(),
    'estado': TextEditingController(),
    'pais': TextEditingController(),

  };
  String titulo = 'Agregar nueva Sucursal';

  //METODOS
  Future<void> guardarSucursal() async {
    if (!formKey.currentState!.validate()) return;

    final sucursalesServices = Provider.of<SucursalesServices>(context, listen: false);
    Loading.displaySpinLoading(context);

    String localidad = "${controllers['ciudad']!.text}, ${controllers['estado']!.text}, ${controllers['pais']!.text}";
    
    final sucursal = Sucursales(
      nombre: controllers['nombre']!.text,
      correo: controllers['correo']!.text,
      telefono: controllers['telefono']!.text,
      direccion: controllers['direccion']!.text,
      localidad: localidad,
      activo: true
    );

    final respuesta = widget.sucEdit == null
      ? await sucursalesServices.createSucursal(sucursal)
      : await sucursalesServices.updateSucursal(sucursal, widget.sucEdit!.id!);

    if (!mounted) return;
    Navigator.pop(context);

    if (respuesta == 'exito') {
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(titulo:'Hubo un problema al crear', respuesta: respuesta),
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
        canRequestFocus: !onlyRead,
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
  void initState() {
    super.initState();
    if (widget.sucEdit != null) {
      onlyRead = widget.onlyRead ?? false;
      titulo = onlyRead ? 'Datos de la Sucursal' : 'Editar Sucursal';

      final sucursal = widget.sucEdit!;
      controllers['nombre']!.text = sucursal.nombre;
      controllers['correo']!.text = sucursal.correo;
      controllers['telefono']!.text = sucursal.telefono;
      controllers['direccion']!.text = sucursal.direccion;
      final partes = sucursal.localidad.split(',');
      controllers['ciudad']!.text = partes[0].trim();
      controllers['estado']!.text = partes[1].trim();
      controllers['pais']!.text = partes[2].trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      canRequestFocus: !onlyRead,
      child: AlertDialog(
        backgroundColor: AppTheme.containerColor2,
        title: Text(titulo),
        content: SizedBox(
          width: 550,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Separador(texto: 'General'),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: buildTextFormField(
                        controller: controllers['nombre']!, 
                        labelText: 'Nombre de la Sucursal',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField(value, 'el nombre'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: controllers['telefono']!,
                        labelText: 'Telefono 10 digitos',
                        readOnly: onlyRead,
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
                        controller: controllers['correo']!, 
                        labelText: 'Correo Electronico',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField(value, 'el correo'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['direccion']!, 
                        labelText: 'Direccion de la Sucursal',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
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
                        controller: controllers['ciudad']!, 
                        labelText: 'Ciudad',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField2(value, 'el correo'),
                        autovalidateMode: AutovalidateMode.onUnfocus,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['estado']!, 
                        labelText: 'Estado',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
                        maxLength: 30,
                        validator: (value) => validateRequiredField2(value, 'la direccion'),
                        autovalidateMode: AutovalidateMode.onUnfocus,
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['pais']!, 
                        labelText: 'Pais',
                        autoFocus: !onlyRead && widget.sucEdit == null,
                        readOnly:  onlyRead,
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
          !onlyRead ? ElevatedButton(
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