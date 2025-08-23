import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
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
  String titulo = 'Agregar nuevo Producto';
  late final List<DropdownMenuItem<String>> dropdownItemsTipo;
  late final List<DropdownMenuItem<String>> dropdownItemsCat;
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'clave': TextEditingController(),
    'descripcion': TextEditingController(),
    'precio': TextEditingController(),
    'precio_iva': TextEditingController(),
    'valorImpresion': TextEditingController(),
  };
  bool requiereMedida = false;
  bool inventariable = false;
  bool imprimible = false;
  bool tipoEmpty = false;
  bool categoriaEmpty = false;
  String? tipoSeleccionado;
  String? categoriaSeleccionada;

  //METODOS
  Future<void> guardarProducto() async {
    if (tipoSeleccionado==null) tipoEmpty = true;
    if (categoriaSeleccionada==null) categoriaEmpty = true;
    if (categoriaEmpty || tipoEmpty) setState(() {});
    if (formKey.currentState!.validate() && !tipoEmpty && !categoriaEmpty) {

      final productosServices = Provider.of<ProductosServices>(context, listen: false);
      Loading.displaySpinLoading(context);      

      Productos producto = Productos(
        codigo: int.parse(controllers['clave']!.text),
        descripcion: controllers['descripcion']!.text,
        tipo: tipoSeleccionado!,
        categoria: categoriaSeleccionada!,
        precio: Decimal.parse(controllers['precio']!.text.replaceAll('MX\$', '').replaceAll(',', '')),
        requiereMedida: requiereMedida,
        inventariable: inventariable,
        imprimible: imprimible,
        valorImpresion: int.tryParse(controllers['valorImpresion']!.text) ?? 0,
      );
      
      late String respuesta;
      if (widget.prodEdit==null){
        respuesta = await productosServices.createProducto(producto);
      } else {
        String id = widget.prodEdit!.id!;
        respuesta = await productosServices.updateProducto(producto, id);
      }      
      if (!mounted) return;
      Navigator.pop(context); // Cierra el loading      
      if (!context.mounted) return;
      if (respuesta == 'exito') {
        Navigator.pop(context); // Cierra el formulario o vuelve atrás
      } else {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(titulo:'Hubo un problema al crear', respuesta: respuesta),
        );
      }
    }
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
        controller: controller,
        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
        readOnly: readOnly,
        canRequestFocus: !readOnly,
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

    if (widget.prodEdit != null) {
      onlyRead = widget.onlyRead ?? false;
      titulo = onlyRead ? 'Datos del Cliente' : 'Editar Cliente';

      final producto = widget.prodEdit!;
      controllers['clave']!.text = producto.codigo.toString();
      controllers['descripcion']!.text = producto.descripcion;
      controllers['precio']!.text = Formatos.pesos.format(producto.precio.toDouble());
      controllers['precio_iva']!.text = Formatos.pesos.format(CalculosDinero().calcularConIva(producto.precio).toDouble());
      imprimible = widget.prodEdit!.imprimible;
      if (imprimible) controllers['valorImpresion']!.text = producto.valorImpresion.toString();
      requiereMedida = widget.prodEdit!.requiereMedida;
      inventariable = widget.prodEdit!.inventariable;
      imprimible = widget.prodEdit!.imprimible;
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
    return FocusScope(
      canRequestFocus: !onlyRead,
      child: AlertDialog(
        backgroundColor: AppTheme.containerColor2,
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
                    SizedBox(
                      width: 120,
                      child: buildTextFormField(
                        controller: controllers['clave']!,
                        labelText: 'Codigo',
                        autoFocus: !onlyRead,
                        readOnly: onlyRead,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese un codigo';
                          }
                          return null;
                        },
                      ),
                    ), const SizedBox(width: 10),
                    Expanded(
                      child: buildTextFormField(
                        controller: controllers['descripcion']!,
                        labelText: 'Descripcion',
                        readOnly: onlyRead,
                        maxLength: 50,
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
                      flex: 3,
                      child: IgnorePointer(
                        ignoring: onlyRead,
                        child: Focus(
                          canRequestFocus: false,
                          onFocusChange: (hasFocus) {
                            /*if (!hasFocus) {
                              if (controllers['precio']!.text.isEmpty) {
                                controllers['precio']!.text = Formatos.pesos.format(0);
                              }
                            }*/
                          },
                          child: TextFormField(
                            readOnly: onlyRead,
                            canRequestFocus: !onlyRead,
                            controller: controllers['precio']!,
                            inputFormatters: [ PesosInputFormatter() ],
                            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                            maxLength: 12,
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
                            onChanged: (value) {
                              if (value.isNotEmpty){
                                String valueForm = value.replaceAll("MX\$", "").replaceAll(",", "");
                                double result = CalculosDinero().calcularConIva(Decimal.parse(valueForm)).toDouble();
                                controllers['precio_iva']!.text = Formatos.pesos.format(result);
                              } else {
                                controllers['precio_iva']!.text = '';
                              }
                            },
                          ),
                        ),
                      ),
                    ), const SizedBox(width: 10),

                    Expanded(
                      flex: 2,
                      child: IgnorePointer(
                        ignoring: true,
                        child: TextFormField(
                          readOnly: true,
                          canRequestFocus: false,
                          controller: controllers['precio_iva']!,
                          inputFormatters: [ PesosInputFormatter() ],
                          decoration: InputDecoration(
                            labelText: 'Precio con Iva',
                            labelStyle: AppTheme.labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const SeparadorConTexto(texto: 'Caracteristicas'), 
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
                      const Text('Requiere Medidas para calcular precio'),
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
                          const Text('Inventariable   '),
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
                          const Text('Contar como impresion  '),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: controllers['valorImpresion']!,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                              readOnly: imprimible==false?true : onlyRead, //si esta marcado el checkbox habilitar
                              maxLines: 1,
                              buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                              maxLength: 3,
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
            onPressed: () async => guardarProducto(),
            style: AppTheme.botonGuardar,
            child: const Text('Guardar Producto')
          ) : const SizedBox(),
        ],
      ),
    );
  }
}