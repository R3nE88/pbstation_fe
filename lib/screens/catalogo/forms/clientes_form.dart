import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ClientesFormDialog extends StatefulWidget {
  const ClientesFormDialog({super.key, this.cliEdit, this.onlyRead});

  final Clientes? cliEdit; 
  final bool? onlyRead;

  @override
  State<ClientesFormDialog> createState() => _ClientesFormState();
}

class _ClientesFormState extends State<ClientesFormDialog> {
  //Varaibles
  bool _onlyRead = false;
  final _formKey = GlobalKey<FormState>();
  String? _regimenFiscal;
  String _titulo = 'Agregar nuevo Cliente';
  final Map<String, TextEditingController> _controllers = {
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

  @override
  void initState() {
    super.initState();

    if (widget.cliEdit != null) {
      _onlyRead = widget.onlyRead ?? false;
      _titulo = _onlyRead ? 'Datos del Cliente' : 'Editar Cliente';

      final cliente = widget.cliEdit!;
      _controllers['nombre']!.text = cliente.nombre;
      _controllers['correo']!.text = cliente.correo ?? '';
      _controllers['telefono']!.text = '${cliente.telefono ?? ''}';
      _controllers['razon']!.text = cliente.razonSocial ?? '';
      _controllers['rfc']!.text = cliente.rfc ?? '';
      _controllers['cp']!.text = '${cliente.codigoPostal ?? ''}';
      _controllers['direccion']!.text = cliente.direccion ?? '';
      _controllers['noExt']!.text = '${cliente.noExt ?? ''}';
      _controllers['noInt']!.text = '${cliente.noInt ?? ''}';
      _controllers['colonia']!.text = cliente.colonia ?? '';
      if (cliente.localidad != null) {
        final partes = cliente.localidad!.split(',');
        _controllers['ciudad']!.text = partes[0].trim();
        _controllers['estado']!.text = partes[1].trim();
        _controllers['pais']!.text = partes[2].trim();
      }
      _regimenFiscal = cliente.regimenFiscal;
    }
  }

  @override
  void dispose() {
    _controllers['nombre']!.dispose();
    _controllers['correo']!.dispose();
    _controllers['telefono']!.dispose();
    _controllers['razon']!.dispose();
    _controllers['rfc']!.dispose();
    _controllers['cp']!.dispose();
    _controllers['direccion']!.dispose();
    _controllers['noExt']!.dispose();
    _controllers['noInt']!.dispose();
    _controllers['colonia']!.dispose();
    _controllers['ciudad']!.dispose();
    _controllers['estado']!.dispose();
    _controllers['pais']!.dispose();
    super.dispose();
  }

  //METODOS
  Future<void> guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final clientesServices = Provider.of<ClientesServices>(context, listen: false);
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    String? localidad;
    if (_controllers['ciudad']!.text.isNotEmpty ||
        _controllers['estado']!.text.isNotEmpty ||
        _controllers['pais']!.text.isNotEmpty) {
      if ([_controllers['ciudad']!.text, _controllers['estado']!.text, _controllers['pais']!.text]
          .any((text) => text.isEmpty)) {
        await showDialog(
          context: context,
          builder: (context) => const Stack(
            alignment: Alignment.topRight,
            children: [
              CustomErrorDialog(
                titulo: 'No se permiten datos parciales.',
                respuesta: 'Los campos Ciudad, Estado y País deben completarse todos o dejarse vacíos.',
              ),
              WindowBar(overlay: true),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }
      localidad = "${_controllers['ciudad']!.text}, ${_controllers['estado']!.text}, ${_controllers['pais']!.text}";
    }

    final cliente = Clientes(
      nombre: _controllers['nombre']!.text,
      correo: _controllers['correo']!.text.isEmpty ? null : _controllers['correo']!.text,
      telefono: _controllers['telefono']!.text.isEmpty ? null : int.tryParse(_controllers['telefono']!.text),        
      razonSocial: _controllers['razon']!.text.isEmpty ? null : _controllers['razon']!.text,
      rfc: _controllers['rfc']!.text.isEmpty ? null : _controllers['rfc']!.text,
      codigoPostal: _controllers['cp']!.text.isEmpty ? null : int.tryParse(_controllers['cp']!.text),
      direccion: _controllers['direccion']!.text.isEmpty ? null : _controllers['direccion']!.text,
      noExt: _controllers['noExt']!.text.isEmpty ? null : int.tryParse(_controllers['noExt']!.text),
      noInt: _controllers['noInt']!.text.isEmpty ? null : int.tryParse(_controllers['noInt']!.text),
      colonia: _controllers['colonia']!.text.isEmpty ? null : _controllers['colonia']!.text,
      localidad: localidad,
      regimenFiscal: _regimenFiscal, 
      adeudos: widget.cliEdit==null ? [] : widget.cliEdit!.adeudos,
    );

    final respuesta = widget.cliEdit == null
        ? await clientesServices.createCliente(cliente)
        : await clientesServices.updateCliente(cliente, widget.cliEdit!.id!);

    loadingSvc.hide();

    if (!mounted) return;
    if (respuesta?.contains('error')??true) {
      showDialog(
        context: context,
        builder: (context) => Stack(
          alignment: Alignment.topRight,
          children: [
            CustomErrorDialog(titulo:'Hubo un problema al crear', respuesta: respuesta??''),
            const WindowBar(overlay: true),
          ],
        ),
      );
    } else {
      widget.cliEdit == null ? 
      cliente.id = respuesta : cliente.id = widget.cliEdit!.id;
      Navigator.pop(context, cliente);
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
          width: 600,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Separador(texto: 'General'),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['nombre']!, 
                        labelText: 'Nombre',
                        autoFocus: !_onlyRead && widget.cliEdit == null,
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
                        validator: (value) => validateRequiredField(value, 'el telefono'),
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Flexible(
                  child: buildTextFormField(
                    controller: _controllers['correo']!,
                    labelText: 'Correo Electronico',
                    readOnly: _onlyRead,
                    maxLength: 30,
                    //validator: (value) => validateRequiredField(value, 'el correo electronico'),
                  ),
                ), const SizedBox(height: 15),
                const Separador(texto: 'Datos para Facturacion'),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildTextFormField(
                        controller: _controllers['razon']!,
                        labelText: 'Razon Social',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['rfc']!,
                        labelText: 'RFC',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
      
                Row(
                  children: [

                    Expanded(
                      child: SearchableDropdown(
                        isReadOnly: _onlyRead,
                        items: Constantes.regimenFiscal,
                        value: _regimenFiscal,
                        showMoreInfo: true,
                        hint: 'Regimen Fiscal',
                        onChanged: (value) {
                          setState(() {
                            _regimenFiscal = value;
                          });
                        },
                      ),
                    ), SizedBox(width: _onlyRead ? 0 : 10),
      
                    !_onlyRead 
                    ? IconButton(
                      onPressed:  () => setState(() => _regimenFiscal = null), 
                      icon: const Icon(Icons.clear, color: AppTheme.letraClara,)
                    ) 
                    : const SizedBox()
                  ], 
                ), const SizedBox(height: 15),
                const Separador(texto: 'Direccion'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: buildTextFormField(
                        controller: _controllers['direccion']!,
                        labelText: 'Calle',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['noExt']!,
                        labelText: 'No. Exterior',
                        readOnly: _onlyRead,
                        maxLength: 6,
                        
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['noInt']!,
                        labelText: 'No. Interior',
                        readOnly: _onlyRead,
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
                        controller: _controllers['colonia']!,
                        labelText: 'Colonia',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
      
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['cp']!,
                        labelText: 'Codigo Postal',
                        readOnly: _onlyRead,
                        maxLength: 5,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ), const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['ciudad']!,
                        labelText: 'Ciudad',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['estado']!,
                        labelText: 'Estado',
                        readOnly: _onlyRead,
                        maxLength: 30,
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: _controllers['pais']!,
                        labelText: 'País',
                        readOnly: _onlyRead,
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
          !_onlyRead ? ElevatedButton(
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