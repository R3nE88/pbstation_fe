import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ProductoFormDialog extends StatefulWidget {
  const ProductoFormDialog({super.key});

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  TextEditingController claveController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  TextEditingController precioController = TextEditingController();
  TextEditingController valorImpresionController = TextEditingController();
  bool inventariable = false;
  bool imprimible = false;
  String tipoSeleccionado = 'producto';
  String categoriaSeleccionada = 'general';
  final formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      title: const Text('Datos del Producto'),
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
                    child: TextFormField(
                      autofocus: true,
                      controller: claveController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Acepta solo dígitos
                      ],
                      decoration: InputDecoration(
                        labelText: 'Codigo',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un codigo';
                        }
                        return null;
                      },
                    ),
                  ), SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripcion',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una descripcion';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),const SizedBox(height: 10),
          
              Row(
                children: [
                  Row(
                    children: [
                      
                      CustomDropDown<String>(
                        value: tipoSeleccionado,
                        hintText: 'Tipo',
                        items: const [
                          DropdownMenuItem(value: 'producto', child: Text('Producto')),
                          DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
                        ],
                        onChanged: (val) => setState(() => tipoSeleccionado = val!),
                      ), const SizedBox(width: 10),

                      CustomDropDown<String>(
                        value: categoriaSeleccionada,
                        hintText: 'Categoría',
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'impresion', child: Text('Impresión Digital')),
                          DropdownMenuItem(value: 'diseño', child: Text('Diseño')),
                        ],
                        onChanged: (val) => setState(() => categoriaSeleccionada = val!),
                      ),
                    ],
                  ), const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: precioController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Acepta solo dígitos
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un precio';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SeparadorConTexto(texto: 'Caracteristicas'), 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        focusColor: AppTheme.focusColor,
                        value: inventariable,
                        onChanged: (value) {
                          setState(() {
                            inventariable = value ?? false;
                          });
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
                          setState(() {
                            imprimible = value ?? false;
                          });
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
                          readOnly: imprimible==false?true:false, //si esta marcado el checkbox habilitar
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
              
          
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final productosServices = Provider.of<ProductosServices>(context, listen: false);
              
              Loading().displaySpinLoading(context);

              Producto producto = Producto(
                codigo: int.parse(claveController.text),
                descripcion: descripcionController.text,
                tipo: tipoSeleccionado,
                categoria: categoriaSeleccionada,
                precio: double.parse(precioController.text),
                inventariable: inventariable,
                imprimible: imprimible,
                valorImpresion: int.tryParse(valorImpresionController.text) ?? 0,
              );

              String respuesta = await productosServices.createProducto(producto);

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

          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.focused)) {
                return AppTheme.letra70; // Color cuando está enfocado
              }
              return AppTheme.letraClara; // Color normal
            }),
            foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
          ),
          child: Text('Guardar Producto')
        ),
      ],
    );
  }
}