import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  TextEditingController rfcController = TextEditingController();
  TextEditingController cpController = TextEditingController();
  TextEditingController direccionController = TextEditingController();
  //String? usoCfdi;//'G03';
  String? regimenFiscal; //'601';
  String titulo = 'Agregar nuevo Cliente';

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
      rfcController.text = widget.cliEdit!.rfc ?? '';
      cpController.text = widget.cliEdit!.codigoPostal ?? '';
      direccionController.text = widget.cliEdit!.direccion ?? '';
      //usoCfdi = widget.prodEdit!.usoCfdi ?? '';
      regimenFiscal = widget.cliEdit!.regimenFiscal;
    }
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
                        controller: rfcController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'RFC',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 2,
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
                  ), SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        controller: direccionController,
                        readOnly: onlyRead,
                        decoration: InputDecoration(
                          labelText: 'Direccion',
                          labelStyle: AppTheme.labelStyle
                        ),
                      ),
                    ),
                  ),
                ],
              ), const SizedBox(height: 15),

              /*CustomDropDown<String>(
                isReadOnly: onlyRead,
                value: usoCfdi,
                hintText: 'Uso CFDI',
                expanded: true,
                items: const [
                  DropdownMenuItem(value: 'G01', child: Text('G01 - Adquisición de mercancías')),
                  DropdownMenuItem(value: 'G02', child: Text('G02 - Devoluciones, descuentos o bonificaciones')),
                  DropdownMenuItem(value: 'G03', child: Text('G03 - Gastos en general')),
                  DropdownMenuItem(value: 'D04', child: Text('D04 - Donativos')),
                  DropdownMenuItem(value: 'G02', child: Text('G02 - Devoluciones, descuentos o bonificaciones')),
                  DropdownMenuItem(value: 'S01', child: Text('S01 - Sin efectos fiscales (usado en algunas notas de crédito)')),
                ],
                onChanged: (val) => setState(() => usoCfdi = val!),
              ), 
              const SizedBox(height: 15),*/
              CustomDropDown<String>(
                isReadOnly: onlyRead,
                value: regimenFiscal,
                hintText: 'Regimen Fiscal',
                expanded: true,
                items: const [
                  DropdownMenuItem(value: '601', child: Text('601 - General de Ley Personas Morales')),
                  DropdownMenuItem(value: '603', child: Text('603 - Personas Morales con Fines no Lucrativos')),
                  DropdownMenuItem(value: '605', child: Text('605 - Sueldos y Salarios e Ingresos Asimilados a Salarios')),
                  DropdownMenuItem(value: '610', child: Text('610 - Residentes en el extranjero sin establecimiento permanente en México')),
                  DropdownMenuItem(value: '616', child: Text('603 - Sin obligaciones fiscales')),

                ],
                onChanged: (val) => setState(() => regimenFiscal = val!),
              ), 
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

              Cliente cliente = Cliente(
                nombre: nombreController.text,
                correo: correoController.text.isEmpty ? null : correoController.text,
                telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                rfc: rfcController.text.isEmpty ? null : rfcController.text,
                codigoPostal: cpController.text.isEmpty ? null : cpController.text,
                direccion: direccionController.text.isEmpty ? null : direccionController.text,
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