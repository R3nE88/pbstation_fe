import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ClientesFormDialog extends StatefulWidget {
  const ClientesFormDialog({super.key, this.cliEdit, this.onlyRead});

  @override
  State<ClientesFormDialog> createState() => _ClientesFormState();

  final Clientes? cliEdit; 
  final bool? onlyRead;
}

class _ClientesFormState extends State<ClientesFormDialog> {
  //Varaibles
  bool onlyRead = false;
  final formKey = GlobalKey<FormState>();
  String? regimenFiscal;
  String titulo = 'Agregar nuevo Cliente';
  late final List<DropdownMenuItem<String>> dropdownItems;
  final Map<String, TextEditingController> controllers = {
    'nombre': TextEditingController(),
    'correo': TextEditingController(),
    'telefono': TextEditingController(),
    'razon': TextEditingController(),
    'rfc': TextEditingController(),
    'cp': TextEditingController(),
    'direccion': TextEditingController(),
    'noExt': TextEditingController(),
    'noInt': TextEditingController(),
    'colonia': TextEditingController(),
    'ciudad': TextEditingController(),
    'estado': TextEditingController(),
    'pais': TextEditingController(),
  };

  //METODOS
  Future<void> guardarCliente() async {
    if (!formKey.currentState!.validate()) return;

    final clientesServices = Provider.of<ClientesServices>(context, listen: false);
    Loading.displaySpinLoading(context);

    String? localidad;
    if (controllers['ciudad']!.text.isNotEmpty ||
        controllers['estado']!.text.isNotEmpty ||
        controllers['pais']!.text.isNotEmpty) {
      if ([controllers['ciudad']!.text, controllers['estado']!.text, controllers['pais']!.text]
          .any((text) => text.isEmpty)) {
        await showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            respuesta: "Los campos Ciudad, Estado y País deben completarse todos o dejarse vacíos.\nNo se permiten datos parciales.",
          ),
        );
        if (!context.mounted) return;
        Navigator.pop(context);
        return;
      }
      localidad = "${controllers['ciudad']!.text}, ${controllers['estado']!.text}, ${controllers['pais']!.text}";
    }

    final cliente = Clientes(
      nombre: controllers['nombre']!.text,
      correo: controllers['correo']!.text.isEmpty ? null : controllers['correo']!.text,
      telefono: controllers['telefono']!.text.isEmpty ? null : int.tryParse(controllers['telefono']!.text),        
      razonSocial: controllers['razon']!.text.isEmpty ? null : controllers['razon']!.text,
      rfc: controllers['rfc']!.text.isEmpty ? null : controllers['rfc']!.text,
      codigoPostal: controllers['cp']!.text.isEmpty ? null : int.tryParse(controllers['cp']!.text),
      direccion: controllers['direccion']!.text.isEmpty ? null : controllers['direccion']!.text,
      noExt: controllers['noExt']!.text.isEmpty ? null : int.tryParse(controllers['noExt']!.text),
      noInt: controllers['noInt']!.text.isEmpty ? null : int.tryParse(controllers['noInt']!.text),
      colonia: controllers['colonia']!.text.isEmpty ? null : controllers['colonia']!.text,
      localidad: localidad,
      regimenFiscal: regimenFiscal,
    );

    final respuesta = widget.cliEdit == null
        ? await clientesServices.createCliente(cliente)
        : await clientesServices.updateCliente(cliente, widget.cliEdit!.id!);

    if (!mounted) return;
    Navigator.pop(context);

    if (respuesta == 'exito') {
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(respuesta: respuesta),
      );
    }
  }

  String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese $fieldName';
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

    if (widget.cliEdit != null) {
      onlyRead = widget.onlyRead ?? false;
      titulo = onlyRead ? 'Datos del Cliente' : 'Editar Cliente';

      final cliente = widget.cliEdit!;
      controllers['nombre']!.text = cliente.nombre;
      controllers['correo']!.text = cliente.correo ?? '';
      controllers['telefono']!.text = '${cliente.telefono ?? ''}';
      controllers['razon']!.text = cliente.razonSocial ?? '';
      controllers['rfc']!.text = cliente.rfc ?? '';
      controllers['cp']!.text = '${cliente.codigoPostal ?? ''}';
      controllers['direccion']!.text = cliente.direccion ?? '';
      controllers['noExt']!.text = '${cliente.noExt ?? ''}';
      controllers['noInt']!.text = '${cliente.noInt ?? ''}';
      controllers['colonia']!.text = cliente.colonia ?? '';
      if (cliente.localidad != null) {
        final partes = cliente.localidad!.split(',');
        controllers['ciudad']!.text = partes[0].trim();
        controllers['estado']!.text = partes[1].trim();
        controllers['pais']!.text = partes[2].trim();
      }
      regimenFiscal = cliente.regimenFiscal;
    }

    dropdownItems = Constantes.regimenFiscal.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text('${entry.key} - ${entry.value}'),
      );
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return FocusScope(
      canRequestFocus: !onlyRead,
      child: AlertDialog(
        backgroundColor: AppTheme.containerColor1,
        title: Text(titulo),
        content: SizedBox(
          width: 600,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SeparadorConTexto(texto: 'General'),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['nombre']!, 
                        labelText: 'Nombre',
                        autoFocus: !onlyRead && widget.cliEdit == null,
                        readOnly:  onlyRead,
                        validator: (value) => validateRequiredField(value, 'el nombre'),
                      )
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['telefono']!,
                        labelText: 'Telefono 10 digitos',
                        readOnly: onlyRead,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => validateRequiredField(value, 'el telefono'),
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Flexible(
                  child: buildTextFormField(
                    controller: controllers['correo']!,
                    labelText: 'Correo Electronico',
                    readOnly: onlyRead,
                    validator: (value) => validateRequiredField(value, 'el correo electronico'),
                  ),
                ), const SizedBox(height: 15),
                const SeparadorConTexto(texto: 'Datos para Facturacion'),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: controllers['razon']!,
                        labelText: 'Razon Social',
                        readOnly: onlyRead,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['rfc']!,
                        labelText: 'RFC',
                        readOnly: onlyRead,
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
      
                Row(
                  children: [
                    Flexible(
                      child: CustomDropDown<String>(
                        isReadOnly: onlyRead,
                        value: regimenFiscal,
                        hintText: 'Regimen Fiscal',
                        expanded: true,
                        items: dropdownItems,
                        onChanged: (val) => setState(() => regimenFiscal = val!),
                      ),
                    ), SizedBox(width: onlyRead ? 0 : 10),
      
                    !onlyRead ? IconButton(onPressed:  () => setState(() => regimenFiscal = null), icon: Icon(Icons.clear)) : const SizedBox()
                  ], 
                ), const SizedBox(height: 15),
                const SeparadorConTexto(texto: 'Direccion'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: buildTextFormField(
                        controller: controllers['direccion']!,
                        labelText: 'Calle',
                        readOnly: onlyRead,   
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['noExt']!,
                        labelText: 'No. Exterior',
                        readOnly: onlyRead,
                        maxLength: 6,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['noInt']!,
                        labelText: 'No. Interior',
                        readOnly: onlyRead,
                        maxLength: 6,
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
      
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: controllers['colonia']!,
                        labelText: 'Colonia',
                        readOnly: onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
      
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['cp']!,
                        labelText: 'Codigo Postal',
                        readOnly: onlyRead,
                        maxLength: 5,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['ciudad']!,
                        labelText: 'Ciudad',
                        readOnly: onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['estado']!,
                        labelText: 'Estado',
                        readOnly: onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: buildTextFormField(
                        controller: controllers['pais']!,
                        labelText: 'País',
                        readOnly: onlyRead,
                        maxLength: 30,
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
              ],
            ),
          )
        ),
        actions: [
          !onlyRead ? ElevatedButton(
            onPressed: () async{
              await guardarCliente();
            }, 
            style: AppTheme.botonGuardar,
            child: const Text('Guardar Cliente')
          ) : const SizedBox()
        ],
      ),
    );
  }
}