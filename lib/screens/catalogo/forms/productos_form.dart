import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
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
  bool _onlyRead = false;
  String _titulo = 'Agregar nuevo Producto';
  late final List<DropdownMenuItem<String>> _dropdownItemsTipo;
  late final List<DropdownMenuItem<String>> _dropdownItemsCat;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'clave': TextEditingController(),
    'descripcion': TextEditingController(),
    'precio': TextEditingController(),
    'precio_iva': TextEditingController(),
    'valor_impresion': TextEditingController(),
  };
  bool _requiereMedida = false;
  bool _inventariable = false;
  bool _imprimible = false;
  bool _tipoEmpty = false;
  bool _categoriaEmpty = false;
  String? _tipoSeleccionado;
  String? _categoriaSeleccionada;
  Decimal _precioSinIva = Decimal.zero;

  @override
  void initState() {
    super.initState();
    if (widget.prodEdit != null) {
      _onlyRead = widget.onlyRead ?? false;
      _titulo = _onlyRead ? 'Datos del Cliente' : 'Editar Cliente';

      final producto = widget.prodEdit!;
      _controllers['clave']!.text = producto.codigo.toString();
      _controllers['descripcion']!.text = producto.descripcion;
      _controllers['precio']!.text = Formatos.pesos.format(CalculosDinero().calcularConIva(producto.precio).toDouble());
      _precioSinIva = producto.precio;
      _controllers['precio_iva']!.text =  Formatos.pesos.format(producto.precio.toDouble());
      _imprimible = widget.prodEdit!.imprimible;
      if (_imprimible) _controllers['valor_impresion']!.text = producto.valorImpresion.toString();
      _requiereMedida = widget.prodEdit!.requiereMedida;
      _inventariable = widget.prodEdit!.inventariable;
      _imprimible = widget.prodEdit!.imprimible;
      _tipoSeleccionado = widget.prodEdit!.tipo;
      _categoriaSeleccionada = widget.prodEdit!.categoria;
    }

    _dropdownItemsTipo = Constantes.tipo.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
    _tipoSeleccionado = _dropdownItemsTipo.first.value;

    _dropdownItemsCat = Constantes.categoria.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
    _categoriaSeleccionada = _dropdownItemsCat.first.value;
  }

  @override
  void dispose() {
    _controllers['clave']!.dispose();
    _controllers['descripcion']!.dispose();
    _controllers['precio']!.dispose();
    _controllers['precio_iva']!.dispose();
    _controllers['valor_impresion']!.dispose();
    super.dispose();
  }

  //METODOS
  Future<void> guardarProducto() async {
    if (_tipoSeleccionado==null) _tipoEmpty = true;
    if (_categoriaSeleccionada==null) _categoriaEmpty = true;
    if (_categoriaEmpty || _tipoEmpty) setState(() {});
    if (_formKey.currentState!.validate() && !_tipoEmpty && !_categoriaEmpty) {

      final productosServices = Provider.of<ProductosServices>(context, listen: false);
      final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
      loadingSvc.show();   

      Productos producto = Productos(
        codigo: int.parse(_controllers['clave']!.text),
        descripcion: _controllers['descripcion']!.text,
        tipo: _tipoSeleccionado!,
        categoria: _categoriaSeleccionada!,
        precio: _precioSinIva,
        requiereMedida: _requiereMedida,
        inventariable: _inventariable,
        imprimible: _imprimible,
        valorImpresion: int.tryParse(_controllers['valor_impresion']!.text) ?? 0,
      );
      
      late String respuesta;
      if (widget.prodEdit==null){
        respuesta = await productosServices.createProducto(producto);
      } else {
        String id = widget.prodEdit!.id!;
        respuesta = await productosServices.updateProducto(producto, id);
      }    

      loadingSvc.hide();

      if (!mounted) return;
      if (!context.mounted) return;
      if (respuesta == 'exito') {
        Navigator.pop(context); // Cierra el formulario o vuelve atrás
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
  Widget build(BuildContext context) {
    return FocusScope(
      canRequestFocus: !_onlyRead,
      child: AlertDialog(
        backgroundColor: AppTheme.containerColor2,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_titulo),
            Text('IVA: ${Configuracion.iva}%', style: AppTheme.labelStyle, textScaler: const TextScaler.linear(0.7)),
          ],
        ),
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
                    SizedBox(
                      width: 120,
                      child: buildTextFormField(
                        controller: _controllers['clave']!,
                        labelText: 'Codigo',
                        autoFocus: !_onlyRead,
                        readOnly: _onlyRead,
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
                        controller: _controllers['descripcion']!,
                        labelText: 'Descripcion',
                        readOnly: _onlyRead,
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
                          isReadOnly: _onlyRead,
                          value: _tipoSeleccionado,
                          hintText: 'Tipo',
                          empty: _tipoEmpty,
                          items: _dropdownItemsTipo,
                          onChanged: (val) => setState(() {
                            _tipoEmpty = false;
                            _tipoSeleccionado = val!;
                          }),
                        ), const SizedBox(width: 10),
                        CustomDropDown<String>(
                          isReadOnly: _onlyRead,
                          value: _categoriaSeleccionada,
                          hintText: 'Categoría',
                          empty: _categoriaEmpty,
                          items: _dropdownItemsCat,
                          onChanged: (val) => setState(() {
                            _categoriaEmpty = false;
                            _categoriaSeleccionada = val!;
                          })
                        ),
                      ],
                    ), const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: IgnorePointer(
                        ignoring: _onlyRead,
                        child: Focus(
                          canRequestFocus: false,
                          child: TextFormField(
                            readOnly: _onlyRead,
                            canRequestFocus: !_onlyRead,
                            controller: _controllers['precio']!,
                            inputFormatters: [ PesosInputFormatter() ],
                            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                            maxLength: 12,
                            decoration: const InputDecoration(
                              labelText: 'Precio con IVA',
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
                                String valueForm = value.replaceAll('MX\$', '').replaceAll(',', '');
                                if (valueForm!='.') {
                                  _precioSinIva = CalculosDinero().calcularSinIva(Decimal.parse(valueForm));//CalculosDinero().calcularConIva(Decimal.parse(valueForm)).toDouble();
                                  _controllers['precio_iva']!.text = Formatos.pesos.format(_precioSinIva.toDouble());
                                }
                              } else {
                                _controllers['precio_iva']!.text = '';
                              }
                            },
                          ),
                        ),
                      ),
                    ), const SizedBox(width: 10),

                    Expanded(
                      flex: 2,
                      child: IgnorePointer(
                        child: TextFormField(
                          readOnly: true,
                          canRequestFocus: false,
                          controller: _controllers['precio_iva']!,
                          inputFormatters: [ PesosInputFormatter() ],
                          decoration: const InputDecoration(
                            labelText: 'Precio sin IVA',
                            labelStyle: AppTheme.labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Separador(texto: 'Caracteristicas'), 
                IgnorePointer(
                  ignoring: _onlyRead,
                  child: Row(
                    children: [
                      Checkbox(
                        focusColor: AppTheme.focusColor,
                        value: _requiereMedida,
                        onChanged: (value) {
                          if (_onlyRead==false){
                            setState(() {
                              _requiereMedida = value ?? false;
                            });
                          }
                        }
                      ),
                      const Text('Requiere Medidas para calcular precio'),
                    ],
                  ),
                ),
                IgnorePointer(
                  ignoring: _onlyRead,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            focusColor: AppTheme.focusColor,
                            value: _inventariable,
                            onChanged: (value) {
                              if (_onlyRead==false){
                                setState(() {
                                  _inventariable = value ?? false;
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
                            value: _imprimible,
                            onChanged: (value) {
                              if (_onlyRead==false){
                                setState(() {
                                  _imprimible = value ?? false;
                                });
                              }
                            }
                          ),
                          const Text('Contar como impresion  '),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: _controllers['valor_impresion']!,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                              readOnly: _imprimible==false?true : _onlyRead, //si esta marcado el checkbox habilitar
                              buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                              maxLength: 3,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                errorStyle: const TextStyle(height: 0),
                                contentPadding: EdgeInsets.zero,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: AppTheme.letraClara),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: AppTheme.letraClara),
                                ),
                              ),
                              validator: (value) {
                                if (_imprimible && (value == null || value.isEmpty)) {
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
          !_onlyRead ? ElevatedButton(
            onPressed: () async => guardarProducto(),
            style: AppTheme.botonGuardar,
            child: const Text('Guardar Producto')
          ) : const SizedBox(),
        ],
      ),
    );
  }
}