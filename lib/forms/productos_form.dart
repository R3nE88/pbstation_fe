import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/currency_input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ProductoFormDialog extends StatefulWidget {
  const ProductoFormDialog({super.key, this.prodEdit, this.onlyRead});

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();

  final Productos? prodEdit; 
  final bool? onlyRead;
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  bool onlyRead = false;
  final formKey = GlobalKey<FormState>();
  TextEditingController claveController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  TextEditingController precioController = TextEditingController();
  TextEditingController valorImpresionController = TextEditingController();
  bool requiereMedida = false;
  bool inventariable = false;
  bool imprimible = false;
  String? tipoSeleccionado;
  String? categoriaSeleccionada;
  bool tipoEmpty = false;
  bool categoriaEmpty = false;
  String titulo = 'Agregar nuevo Producto';
  late final List<DropdownMenuItem<String>> dropdownItemsTipo;
  late final List<DropdownMenuItem<String>> dropdownItemsCat;
  

  @override
  void initState() {
    super.initState();

    if(widget.prodEdit!=null){
      if (widget.onlyRead!=null){
        if(widget.onlyRead==true){
          titulo = 'Datos del Producto';
          onlyRead = true;
        }
      } else {
        titulo = 'Editar Producto';
      }
      claveController.text = widget.prodEdit!.codigo.toString();
      descripcionController.text = widget.prodEdit!.descripcion;
      precioController.text = widget.prodEdit!.precio.toString();
      requiereMedida = widget.prodEdit!.requiereMedida;
      inventariable = widget.prodEdit!.inventariable;
      imprimible = widget.prodEdit!.imprimible;
      if (imprimible){
        valorImpresionController.text = widget.prodEdit!.valorImpresion.toString();
      }
      tipoSeleccionado = widget.prodEdit!.tipo;
      categoriaSeleccionada = widget.prodEdit!.categoria;
    }

    dropdownItemsTipo = Constantes.tipo.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();

    dropdownItemsCat = Constantes.categoria.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
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
                  SizedBox(
                    width: 120,
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: TextFormField(
                        readOnly: onlyRead,
                        autofocus: !onlyRead,
                        controller: claveController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // Acepta solo dígitos
                        ],
                        decoration: InputDecoration(
                          labelText: 'Codigo',
                          labelStyle: AppTheme.labelStyle
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un codigo';
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
                        controller: descripcionController,
                        decoration: InputDecoration(
                          labelText: 'Descripcion',
                          labelStyle: AppTheme.labelStyle
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una descripcion';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  ),
                ],
              ),const SizedBox(height: 10),
          
              Row(
                children: [
                  Row(
                    children: [
                      
                      CustomDropDown<String>(
                        isReadOnly: onlyRead,
                        value: tipoSeleccionado,
                        hintText: 'Tipo',
                        empty: tipoEmpty,
                        items: dropdownItemsTipo,
                        onChanged: (val) => setState(() {
                          tipoEmpty = false;
                          tipoSeleccionado = val!;
                        }),
                      ), const SizedBox(width: 10),

                      CustomDropDown<String>(
                        isReadOnly: onlyRead,
                        value: categoriaSeleccionada,
                        hintText: 'Categoría',
                        empty: categoriaEmpty,
                        items: dropdownItemsCat,
                        onChanged: (val) => setState(() {
                          categoriaEmpty = false;
                          categoriaSeleccionada = val!;
                        })
                      ),
                    ],
                  ), const SizedBox(width: 10),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: onlyRead,
                      child: Focus(
                        canRequestFocus: false,
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) {
                            if (precioController.text.isEmpty) {
                              precioController.text = '0';
                            }
                            precioController.text = '\$${precioController.text.replaceAll('\$', '')}';
                          } /*else {
                            precioController.text = '';
                          }*/
                        },
                        child: TextFormField(
                          controller: precioController,
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Precio',
                            labelStyle: AppTheme.labelStyle,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un precio';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SeparadorConTexto(texto: 'Caracteristicas'), 
              IgnorePointer(
                ignoring: onlyRead,
                child: Row(
                  children: [
                    Checkbox(
                      focusColor: AppTheme.focusColor,
                      value: requiereMedida,
                      onChanged: (value) {
                        if (onlyRead==false){
                          setState(() {
                            requiereMedida = value ?? false;
                          });
                        }
                      }
                    ),
                    Text('Requiere Medidas para calcular precio'),
                  ],
                ),
              ),

              IgnorePointer(
                ignoring: onlyRead,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          focusColor: AppTheme.focusColor,
                          value: inventariable,
                          onChanged: (value) {
                            if (onlyRead==false){
                              setState(() {
                                inventariable = value ?? false;
                              });
                            }
                          }
                        ),
                        Text('Inventariable   '),
                      ],
                    ), 
                          
                    Row(
                      children: [
                        Checkbox(
                          focusColor: AppTheme.focusColor,
                          value: imprimible,
                          onChanged: (value) {
                            if (onlyRead==false){
                              setState(() {
                                imprimible = value ?? false;
                              });
                            }
                          }
                        ),
                        Text('Contar como impresion  '),
                        SizedBox(
                          //height: 40,
                          width: 110,
                          child: TextFormField(
                            controller: valorImpresionController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly, // Acepta solo dígitos
                            ],
                            readOnly: imprimible==false?true : onlyRead, //si esta marcado el checkbox habilitar
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              errorStyle: TextStyle(height: 0),
                              contentPadding: EdgeInsets.zero,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.letraClara, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.letraClara, width: 1),
                              ),
                            ),
                            validator: (value) {
                              if (imprimible && (value == null || value.isEmpty)) {
                                return 'valor de impresion';
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
          
            ],
          ),
        ),
      ),
      actions: [
        !onlyRead ? ElevatedButton(
          onPressed: () async {
            if (tipoSeleccionado==null){
              tipoEmpty = true;
            }
            if (categoriaSeleccionada==null){
              categoriaEmpty = true;
            }

            if (categoriaEmpty || tipoEmpty){
              setState(() {});
            }

            if (formKey.currentState!.validate() && !tipoEmpty && !categoriaEmpty) {
              final productosServices = Provider.of<ProductosServices>(context, listen: false);
              
              Loading().displaySpinLoading(context);

              Productos producto = Productos(
                codigo: int.parse(claveController.text),
                descripcion: descripcionController.text,
                tipo: tipoSeleccionado!,
                categoria: categoriaSeleccionada!,
                precio: double.parse(precioController.text.replaceAll('\$', '').replaceAll(',', '')),
                requiereMedida: requiereMedida,
                inventariable: inventariable,
                imprimible: imprimible,
                valorImpresion: int.tryParse(valorImpresionController.text) ?? 0,
              );
              
              late String respuesta;
              if (widget.prodEdit==null){
                respuesta = await productosServices.createProducto(producto);
              } else {
                String id = widget.prodEdit!.id!;
                respuesta = await productosServices.updateProducto(producto, id);
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
          child: Text('Guardar Producto')
        ) : SizedBox(),
      ],
    );
  }
}