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

  final Cliente? cliEdit; 
  final bool? onlyRead;
}

class _ClientesFormState extends State<ClientesFormDialog> {
  bool onlyRead = false;
  final formKey = GlobalKey<FormState>();
  TextEditingController nombreController = TextEditingController();
  TextEditingController correoController = TextEditingController();
  TextEditingController telefonoController = TextEditingController();
  TextEditingController razonController = TextEditingController();
  TextEditingController rfcController = TextEditingController();

  TextEditingController cpController = TextEditingController();
  TextEditingController direccionController = TextEditingController();
  
  TextEditingController noExtController = TextEditingController();
  TextEditingController noIntController = TextEditingController();
  TextEditingController coloniaController = TextEditingController();
  TextEditingController ciudadController = TextEditingController();
  TextEditingController estadoController = TextEditingController();
  TextEditingController paisController = TextEditingController();

  String? regimenFiscal;
  String titulo = 'Agregar nuevo Cliente';

  late final List<DropdownMenuItem<String>> dropdownItems;

  @override
  void initState() {
    super.initState();

    if(widget.cliEdit!=null){
      if (widget.onlyRead!=null){
        if(widget.onlyRead==true){
          titulo = 'Datos del Cliente';
          onlyRead = true;
        }
      } else {
        titulo = 'Editar Cliente';
      }
      nombreController.text = widget.cliEdit!.nombre;
      correoController.text = widget.cliEdit!.correo ?? '';
      telefonoController.text = widget.cliEdit!.telefono ?? '';
      razonController.text = widget.cliEdit!.razonSocial ?? '';
      rfcController.text = widget.cliEdit!.rfc ?? '';
      cpController.text = widget.cliEdit!.codigoPostal ?? '';
      direccionController.text = widget.cliEdit!.direccion ?? '';
      noExtController.text = widget.cliEdit!.noExt ?? '';
      noIntController.text = widget.cliEdit!.noInt ?? '';
      coloniaController.text = widget.cliEdit!.colonia ?? '';
      if (widget.cliEdit!.localidad!=null){
        String localidad = widget.cliEdit!.localidad!;
        List<String> partes = localidad.split(',');
        ciudadController.text = partes[0].trim();
        estadoController.text = partes[1].trim();
        paisController.text = partes[2].trim();
      }
      regimenFiscal = widget.cliEdit!.regimenFiscal;
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
    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      title: Text(titulo),
      content: SizedBox(
        width: 600,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeparadorConTexto(texto: 'General'),
              
              Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        autofocus: !onlyRead,
                        readOnly:  onlyRead,
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: AppTheme.labelStyle
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un Nombre';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        readOnly: onlyRead,
                        controller: telefonoController,
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Telefono 10 digitos',
                          labelStyle: AppTheme.labelStyle
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // Acepta solo dígitos
                        ],
                      ),
                    ),
                  ),
                ],
              ), SizedBox(height: 15),

              Flexible(
                child: IgnorePointer(
                  ignoring: onlyRead,
                  child: TextFormField(
                    controller: correoController,
                    readOnly: onlyRead,
                    decoration: InputDecoration(
                      labelText: 'Correo Electronico',
                      labelStyle: AppTheme.labelStyle
                    ),
                  ),
                ),
              ), SizedBox(height: 15),

              SeparadorConTexto(texto: 'Datos para Facturacion'),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: razonController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Razon Social',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: rfcController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'RFC',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
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

                  !onlyRead ? IconButton(onPressed:  () => setState(() => regimenFiscal = null), icon: Icon(Icons.clear)) : SizedBox()
                ], 
              ), const SizedBox(height: 15),

              SeparadorConTexto(texto: 'Direccion'),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: direccionController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Calle',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: noExtController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'No. Exterior',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: noIntController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'No. Interior',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ),
                ],
              ), const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: coloniaController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Colonia',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),

                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: cpController,
                        readOnly: onlyRead,
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: 'Codigo Postal',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ),
                ],
              ), const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: ciudadController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Ciudad',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: estadoController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: paisController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'País',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
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
            if (formKey.currentState!.validate()) {
              final clientesServices = Provider.of<ClientesServices>(context, listen: false);

              Loading().displaySpinLoading(context);
              
              Future<void> faltanDatos(String mensaje) async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return CustomErrorDialog(respuesta: mensaje);
                  },
                );
                // Aquí se ejecuta después de cerrar el diálogo
                if (!context.mounted) return;
                Navigator.pop(context);
              }

              String? localidad;
              int count = 0;
              if (ciudadController.text.isNotEmpty || estadoController.text.isNotEmpty || paisController.text.isNotEmpty){
                if (ciudadController.text.isEmpty){
                  count++;
                }
                if (estadoController.text.isEmpty){
                  count++;
                }
                if (paisController.text.isEmpty) {
                  count++;                  
                }
              }

              if (count > 0 && count < 3){
                faltanDatos("Los campos Ciudad, Estado y País deben completarse todos o dejarse vacíos. No se permiten datos parciales.");
                return;

              } else {
                localidad = "${ciudadController.text}, ${estadoController.text}, ${paisController.text}";
              }

              

              Cliente cliente = Cliente(
                nombre: nombreController.text,
                correo: correoController.text.isEmpty ? null : correoController.text,
                telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                razonSocial: razonController.text.isEmpty ? null : razonController.text,
                rfc: rfcController.text.isEmpty ? null : rfcController.text,
                codigoPostal: cpController.text.isEmpty ? null : cpController.text,
                direccion: direccionController.text.isEmpty ? null : direccionController.text,
                noExt: noExtController.text.isEmpty ? null : noExtController.text,
                noInt: noIntController.text.isEmpty ? null : noIntController.text,
                colonia: coloniaController.text.isEmpty ? null : coloniaController.text,
                localidad:  localidad,
                regimenFiscal: regimenFiscal
              );

              late String respuesta;
              if (widget.cliEdit==null){
                respuesta = await clientesServices.createCliente(cliente);
              } else {
                String id = widget.cliEdit!.id!;
                respuesta = await clientesServices.updateCliente(cliente, id);
              }

              if (!context.mounted) return;
              Navigator.pop(context); // Cierra el loading

              if (!context.mounted) return;
              if (respuesta == 'exito') {
                Navigator.pop(context); // Cierra el formulario o vuelve atrás
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CustomErrorDialog(respuesta: respuesta);
                  },
                );
              }
            }
          }, 
          style: AppTheme.botonGuardar,
          child: Text('Guardar Cliente')
        ) : SizedBox()
      ],
    );
  }
}