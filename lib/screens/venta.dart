import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/busqueda_field.dart';
import 'package:pbstation_frontend/widgets/seleccionador_hora.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class Venta extends StatefulWidget {
  const Venta({super.key, required this.clientesServices, required this.index, required this.productosServices});

  final ClientesServices clientesServices;
  final ProductosServices productosServices;
  final int index;

  @override
  State<Venta> createState() => _VentaState();
}

class _VentaState extends State<Venta> {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final ScrollController _scrollController = ScrollController();
    FocusNode checkboxFocus1 = FocusNode();
    FocusNode checkboxFocus2 = FocusNode();

    late Clientes? clienteSelected;
    late bool entregaInmediata;
    late DateTime? fechaEntrega;
    late Productos? productoSelected;
    late List<Productos> productos;
    late List<DetallesVenta> detallesVenta;
    late TextEditingController comentariosController;

    //Todos estos son para agregar al DetallesVentaelected
    late TextEditingController precioController;
    late TextEditingController cantidadController;
    late TextEditingController anchoController;
    late TextEditingController altoController;
    late TextEditingController comentarioController;
    late TextEditingController descuentoController;
    late double descuentoAplicado;
    late TextEditingController ivaController;
    late TextEditingController productoTotalController;

    late TextEditingController subtotalController;
    late TextEditingController totalDescuentoController;
    late TextEditingController totalIvaController;
    late TextEditingController totalController;

    bool anchoError = false;
    bool altoError = false;



  @override
  void initState() {
    super.initState();
    clienteSelected = VentaTabState.tabs[widget.index].clienteSelected;
    entregaInmediata = VentaTabState.tabs[widget.index].entregaInmediata;
    fechaEntrega = VentaTabState.tabs[widget.index].fechaEntrega;
    productoSelected = VentaTabState.tabs[widget.index].productoSelected;
    productos = VentaTabState.tabs[widget.index].productos;
    detallesVenta = VentaTabState.tabs[widget.index].detallesVenta;
    comentariosController = VentaTabState.tabs[widget.index].comentariosController;

    //Todos estos son para agregar al productoSelected
    precioController = VentaTabState.tabs[widget.index].precioController;
    cantidadController = VentaTabState.tabs[widget.index].cantidadController;
    anchoController = VentaTabState.tabs[widget.index].anchoController;
    altoController = VentaTabState.tabs[widget.index].altoController;
    comentarioController = VentaTabState.tabs[widget.index].comentarioController;
    descuentoController = VentaTabState.tabs[widget.index].descuentoController;
    descuentoAplicado = VentaTabState.tabs[widget.index].descuentoAplicado;
    ivaController = VentaTabState.tabs[widget.index].ivaController;
    productoTotalController = VentaTabState.tabs[widget.index].productoTotalController;

    subtotalController = VentaTabState.tabs[widget.index].subtotalController;
    totalDescuentoController = VentaTabState.tabs[widget.index].totalDescuentoController;
    totalIvaController = VentaTabState.tabs[widget.index].totalIvaController;
    totalController = VentaTabState.tabs[widget.index].totalController;
  }

  @override
  Widget build(BuildContext context) {  
    
    void calcularSubtotal(){
      if (productoSelected== null) {
        return;
      }

      final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
      double precio = productoSelected?.precio ?? 0;
      precioController.text = formatoMoneda.format(precio);//'${productoSelected?.precio.toString() ?? '0.00'}\$';
      int cantidad = 0;
      if (cantidadController.text.isNotEmpty){
        cantidad = int.parse(cantidadController.text.replaceAll(',', ''));
      } else {
        cantidad = 0;
      }

      int descuento = int.tryParse(descuentoController.text.replaceAll('%', '')) ?? 0;

      if (productoSelected?.requiereMedida == true && anchoController.text.isNotEmpty && altoController.text.isNotEmpty) {
        double totalSinIva = (productoSelected?.precio ?? 0) * cantidad;
        double ancho = double.tryParse(anchoController.text) ?? 0;
        double alto = double.tryParse(altoController.text) ?? 0;
        double totalMedida = ((ancho * alto) * totalSinIva);

        descuentoAplicado = totalSinIva * (descuento / 100);
        double total = totalMedida-descuentoAplicado;

        double iva = total * 0.08;
        total = total + iva;

        ivaController.text = formatoMoneda.format(iva);
        productoTotalController.text = formatoMoneda.format(total);
        VentaTabState.tabs[widget.index].descuentoAplicado = descuentoAplicado;        
      } else {
        double totalSinIva = (productoSelected?.precio ?? 0) * cantidad;

        descuentoAplicado = totalSinIva * (descuento / 100);
        double total = totalSinIva-descuentoAplicado;

        double iva = total * 0.08;
        total = total + iva; 

        ivaController.text = formatoMoneda.format(iva);
        productoTotalController.text = formatoMoneda.format(total);
        VentaTabState.tabs[widget.index].descuentoAplicado = descuentoAplicado;
      }
    }

    void limpiarCamposProducto() {
      productoSelected = null;
      VentaTabState.tabs[widget.index].productoSelected = productoSelected;
      precioController.text = '\$0.00';
      cantidadController.text = '1';
      anchoController.text = '1';
      altoController.text = '1';
      comentarioController.clear();
      descuentoController.text = '0%';
      ivaController.text = '\$0.00';
      productoTotalController.text = '\$0.00';
    }

    void calcularTotal(){
      final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
      double subtotal = 0;
      double totalDescuento = 0;
      double totalIva = 0;
      double total = 0;

      for (var detalle in detallesVenta) {
        subtotal += detalle.subtotal-detalle.iva+detalle.descuentoAplicado;
        totalDescuento += detalle.descuentoAplicado; // Asumiendo que descuento es un porcentaje
        totalIva += detalle.iva; // Asumiendo que iva ya está calculado
        total += detalle.subtotal; // Total final
      }

      subtotalController.text = formatoMoneda.format(subtotal);
      totalDescuentoController.text = formatoMoneda.format(totalDescuento);
      totalIvaController.text = formatoMoneda.format(totalIva);
      totalController.text = formatoMoneda.format(total);
    }

    Future<void> elegirFecha()async{
      final DateTime? selectedDate = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: AppTheme.containerColor1,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.height * 0.5,
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: TextTheme(
                    bodyMedium: TextStyle(color: Colors.white), // Cambia el color del texto
                  ),
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.tablaColor2, // Color principal (por ejemplo, para el encabezado)
                    onSurface: Colors.white, // Color del texto en general
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 31)),
                  onDateChanged: (selectedDate) {
                    Navigator.pop(context, selectedDate);
                  },
                ),
              ),
            ),
          );
        },
      );

      if (!context.mounted) return;
      
      final TimeOfDay? selectedTime = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SeleccionadorDeHora();
        },
      );

      if (selectedDate == null || selectedTime == null) {
        setState(() {
          entregaInmediata = true;
          fechaEntrega = null;
          VentaTabState.tabs[widget.index].fechaEntrega = null;
          checkboxFocus1.requestFocus();
        });
        return; // Si no se seleccionó fecha o hora, no hacer nada
      }

      //print('Fecha seleccionada: $selectedDate y Hora seleccionada: $selectedTime');
      DateTime fechaSeleccionada = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );                                        

      setState(() {
        checkboxFocus2.requestFocus();
        entregaInmediata = false;
        VentaTabState.tabs[widget.index].entregaInmediata = false;    
        fechaEntrega = fechaSeleccionada;
        VentaTabState.tabs[widget.index].fechaEntrega = fechaSeleccionada;                                    
      });

      if (!context.mounted) return;
      FocusScope.of(context).nextFocus();

    }
    

    return Flexible( //Contenido (Body)
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row( 
                  children: [
                    
                    Expanded(
                      child: Column( //Formulario de clientes
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   Cliente *', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: BusquedaField<Clientes>(
                                  items: widget.clientesServices.clientes,
                                  selectedItem: clienteSelected,
                                  onItemSelected: (Clientes? selected) {
                                    clienteSelected = selected;
                                    VentaTabState.tabs[widget.index].clienteSelected = selected; // Actualizar el estado global
                                  },
                                  displayStringForOption: (cliente) => cliente.nombre, 
                                  normalBorder: false, 
                                  icono: Icons.perm_contact_cal_sharp, 
                                  defaultFirst: true, 
                                  hintText: 'Buscar Cliente', 
                                )
                              ),
                              Container(
                                height: 40,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.letraClara,
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))
                                ),
                                child: Center(
                                  child: FeedBackButton(
                                    onPressed: () {
                                    },
                                    child: Icon(Icons.add, color: AppTheme.containerColor1, size: 28)
                                  )
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Column( //Fecha de Entrega
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(' Fecha de Entrega:', style: AppTheme.subtituloPrimario),
                        SizedBox(height: 2),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(43, 255, 255, 255),
                            border: Border.all(color: AppTheme.letraClara),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              children: [
                                Checkbox(
                                  focusNode: checkboxFocus1,
                                  value: entregaInmediata, 
                                  focusColor: AppTheme.focusColor,
                                  onChanged: (value){
                                    if (entregaInmediata==true){
                                      return;
                                    }
                                    setState(() {
                                      fechaEntrega = null;
                                      VentaTabState.tabs[widget.index].fechaEntrega = null;
                                      checkboxFocus1.requestFocus();
                                      entregaInmediata = value!;
                                      VentaTabState.tabs[widget.index].entregaInmediata = value;
                                    });
                                  } 
                                ),
                                Text('Se entrega en este momento  ')
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    
                    //SizedBox(width: 15),
                    
                    Column( 
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(''),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(43, 255, 255, 255),
                                border: Border.all(color: AppTheme.letraClara),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      focusNode: checkboxFocus2,
                                      focusColor: AppTheme.focusColor,
                                      value: !entregaInmediata, 
                                      onChanged: (value)async {
                                        await elegirFecha();
                                      } 
                                    ),
                                    SizedBox(
                                      width: 140,
                                      child: fechaEntrega==null? Text(
                                        'Entregar en otro día  '
                                      ) :
                                      Center(child: Text(
                                        '${fechaEntrega!.day}/${fechaEntrega!.month}/${fechaEntrega!.year}',
                                        style: AppTheme.tituloClaro,
                                      ))
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.letraClara,
                                borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      fechaEntrega == null ? '--:--:--   ' : DateFormat('hh:mm a', 'en_US').format(fechaEntrega!), 
                                      style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700)
                                    ),
                                  ),
                                  Center(
                                    child: FeedBackButton(
                                      onPressed: () async {
                                        await elegirFecha();
                                      },
                                      child: Icon(Icons.calendar_month, color: AppTheme.containerColor1, size: 28)
                                    )
                                  ),
                                  SizedBox(width: 10)
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
                    
                SizedBox(height: 10),
                    
                Row(
                  children: [
                    
                    Expanded(
                      child: Column( //Formulario de Producto
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   Producto *', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          BusquedaField<Productos>(
                            items: widget.productosServices.productos,
                            selectedItem: productoSelected,
                            onItemSelected: (Productos? selected) {
                              setState(() {
                                productoSelected = selected;
                                VentaTabState.tabs[widget.index].productoSelected = selected; // Actualizar el estado global
                                calcularSubtotal();
                              });
                            },
                            displayStringForOption: (producto) => producto.descripcion, 
                            normalBorder: true, 
                            icono: Icons.copy, 
                            defaultFirst: false, 
                            secondaryDisplayStringForOption: (producto) => producto.codigo.toString(), 
                            hintText: 'F2', 
                            teclaFocus: LogicalKeyboardKey.f2,
                          )
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Column( //Precio por unidad
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(' Precio/Unidad', style: AppTheme.subtituloPrimario),
                        SizedBox(height: 2),
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: TextFormField(
                            controller: precioController,
                            canRequestFocus: false,
                            readOnly: true,
                            //initialValue: '0.00',
                          ),
                        )
                      ],
                    ),
                    
                    SizedBox(width: 15),
                    
                    Column( //Precio por unidad
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('   Cantidad', style: AppTheme.subtituloPrimario),
                        SizedBox(height: 2),
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: TextFormField(
                            controller: cantidadController,
                            //initialValue: '1',
                            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly, // Solo números enteros positivos
                              CurrencyInputFormatter(
                                leadingSymbol: '',
                                useSymbolPadding: false,
                                thousandSeparator: ThousandSeparator.Comma,
                                mantissaLength: 0, // sin decimales
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                calcularSubtotal();
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    
                    SizedBox(width: 15),
                    
                    productoSelected?.requiereMedida==true ? Row(
                      children: [
                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   Ancho', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField(
                                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                maxLength: 4,
                                controller: anchoController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: anchoError ? AppTheme.inputError : AppTheme.inputNormal,
                                onChanged: (value) {
                                  if (value.isNotEmpty && value != '0') {
                                    setState(() {
                                      anchoError = false;
                                    });
                                  } else {
                                    setState(() {
                                      anchoError = true;
                                    });
                                  }
                                  if (anchoController.text.isNotEmpty && altoController.text.isNotEmpty) {
                                    if (anchoController.text != '0' && altoController.text != '0') {
                                      setState(() {
                                        calcularSubtotal();
                                      });
                                    }
                                  }
                                },
                              ),
                            )
                          ],
                        ),
              
                        SizedBox(width: 15),
              
                        Column( //Precio por unidad
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   Alto', style: AppTheme.subtituloPrimario),
                            SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextFormField(
                                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                maxLength: 4,
                                controller: altoController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: altoError ? AppTheme.inputError : AppTheme.inputNormal,
                                onChanged: (value) {
                                  if (value.isNotEmpty && value != '0') {
                                    setState(() {
                                      altoError = false;
                                    });
                                  } else {
                                    setState(() {
                                      altoError = true;
                                    });
                                  }
                                  if (anchoController.text.isNotEmpty && altoController.text.isNotEmpty) {
                                    if (anchoController.text != '0' && altoController.text != '0') {
                                      setState(() {
                                        calcularSubtotal();
                                      });
                                    }
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ],
                    ) : SizedBox(),
                    
                    
                  ],
                ),
                    
                SizedBox(height: 10),
                    
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    Expanded(
                      flex: 2,
                      child: Column( //Formulario de Producto
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   Comentario', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          TextFormField(
                            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                            maxLength: 100,
                            controller: comentarioController,
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(Icons.comment, size: 25, color: AppTheme.letra70),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Expanded(
                      child: Column( //Formulario de Producto
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   % Descuento', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          Focus(
                            canRequestFocus: false,
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) {
                                if (descuentoController.text.isEmpty) {
                                  descuentoController.text = '0';
                                  calcularSubtotal();
                                }
                                descuentoController.text = '${descuentoController.text.replaceAll('%', '')}%';
                              } else {
                                descuentoController.text = '';
                                calcularSubtotal();
                              }
                            },
                            child: TextFormField(
                              buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                              maxLength: 4,
                              controller: descuentoController,
                              //canRequestFocus: false,
                              //readOnly: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
                              ),
                              onChanged: (value) {
                                if (descuentoController.text.isEmpty) {
                                  descuentoController.text = '0';
                                }
                                if (int.parse(descuentoController.text) > 100) {
                                  descuentoController.text = '100';
                                } 
                                calcularSubtotal();
                              },
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Expanded(
                      child: Column( //Formulario de Producto
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   IVA (8%)', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          SizedBox(
                            height: 40,
                            child: TextFormField( //TODO: iva
                              buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                              maxLength: 3,
                              controller: ivaController,
                              canRequestFocus: false,
                              readOnly: true,
                              //initialValue: '\$0.00',
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Expanded(
                      child: Column( //Formulario de Producto
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('   Total', style: AppTheme.subtituloPrimario),
                          SizedBox(height: 2),
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              controller: productoTotalController,
                              canRequestFocus: false,
                              readOnly: true,
                              //initialValue: '\$0.00',
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    ElevatedButton(
                      onPressed: (){
                        if (productoSelected == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Center(child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Text('Seleccione un producto antes de agregarlo.'),
                              )),
                              backgroundColor: Colors.red.withAlpha(100),
                            )
                          );
                          return;
                        }

                        if (productoSelected!.requiereMedida == true){
                          bool isValid = true;
                          if (anchoController.text.isEmpty || anchoController.text == '0') {
                            isValid = false;
                            setState(() {
                              anchoError = true;
                            });                            
                          }
                          if (altoController.text.isEmpty || altoController.text == '0') {
                            isValid = false;
                            setState(() {
                              altoError = true;
                            });
                          }
                          if (!isValid) {
                            return;
                          }
                        }

                        DetallesVenta detalle = DetallesVenta(
                          productoId: productoSelected!.id!,
                          cantidad: int.parse(cantidadController.text.replaceAll(',', '')),
                          ancho: double.tryParse(anchoController.text) ?? 0,
                          alto: double.tryParse(altoController.text) ?? 0,
                          comentarios: comentarioController.text,
                          descuento: int.tryParse(descuentoController.text.replaceAll('%', '').replaceAll(',', '')) ?? 0,
                          descuentoAplicado: descuentoAplicado,
                          iva: double.tryParse(ivaController.text.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
                          subtotal: double.tryParse(productoTotalController.text.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
                        );
            
                        productos.add(productoSelected!);

                        FocusScope.of(context).previousFocus();
                        FocusScope.of(context).previousFocus();
                        FocusScope.of(context).previousFocus();
                        FocusScope.of(context).previousFocus();
                        if (productoSelected!.requiereMedida){
                          FocusScope.of(context).previousFocus();
                          FocusScope.of(context).previousFocus();
                        }

                        setState(() {
                          detallesVenta.add(detalle);
                          calcularTotal();
                          limpiarCamposProducto();
                        });

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });             
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Agregar Producto', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                      ),
                    )
                    
                  ],
                ),
                    
                SizedBox(height: 30),
                    
                Expanded(
                  child: Column(
                    children: [
                      // Cabecera
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          color: AppTheme.tablaColorHeader,
                        ),
                        child: Row(
                          children: const [
                            Expanded(child: Text('Cantidad', textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('Producto', textAlign: TextAlign.center)),
                            Expanded(child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                            Expanded(child: Text('Descuento', textAlign: TextAlign.center)),
                            Expanded(child: Text('Subtotal', textAlign: TextAlign.center)),
                            Expanded(child: Text('IVA', textAlign: TextAlign.center)),
                            Expanded(child: Text('Total', textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      // Lista de datos
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: detallesVenta.isNotEmpty ? ListView.builder(
                            controller: _scrollController,
                            itemCount: detallesVenta.length,
                            itemBuilder: (context, index) {
                              return FilaDetalles(index: index, detalle: detallesVenta[index], producto: productos[index]);
                            },
                          ) : FilaDetalles(index: -1),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                    
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                        maxLength: 250,
                        controller: comentariosController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Comentarios de la venta',
                          hintStyle: TextStyle(color: AppTheme.letra70),
                          isDense: true,
                          //prefixIcon: Icon(Icons.comment, size: 25, color: AppTheme.letra70),
                          contentPadding: const EdgeInsets.only(left: 10, top: 20),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: const BorderRadius.all(Radius.circular(12))
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                            borderRadius: const BorderRadius.all(Radius.circular(12))
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: (){},
                                  style: AppTheme.botonSecStyle,
                                  child: Text('      Procesar Pago (f8)     ', 
                                    style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: (){},
                                  child: Text('Guardar como cotizacion', 
                                    style: TextStyle(color: AppTheme.isDarkTheme==true?AppTheme.containerColor1:Colors.black54, fontWeight: FontWeight.w700)
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Subtotal:  ', style: AppTheme.subtituloPrimario),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: subtotalController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: AppTheme.inputDecorationCustom,
                                    )
                                  )
                                ],
                              ), SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('- Descuento:  ', style: AppTheme.subtituloPrimario),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: totalDescuentoController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: AppTheme.inputDecorationCustom,
                                    )
                                  )
                                ],
                              ), SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('+ IVA:  ', style: AppTheme.subtituloPrimario),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: totalIvaController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: AppTheme.inputDecorationCustom,
                                    )
                                  )
                                ],
                              ), SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Total:  ', style: AppTheme.tituloPrimario),
                                  SizedBox(
                                    height: 36,
                                    width: 150,
                                    child: TextFormField(
                                      controller: totalController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: AppTheme.inputDecorationCustom.copyWith(
                                      ),
                                      style: TextStyle(fontSize: 22),
                                    )
                                  )
                                ],
                              ), SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilaDetalles extends StatelessWidget {
  const FilaDetalles({
    super.key, required this.index, this.detalle, this.producto,
  });

  final int index;
  final DetallesVenta? detalle;
  final Productos? producto;

  @override
  Widget build(BuildContext context) {
    if (index == -1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorFondo,
            ),
            child: Center(child: Text('No hay productos agregados', style: TextStyle(color: Colors.transparent)))
          ),
        ],
      );
    } 

    final formatoNumero = NumberFormat.currency(decimalDigits: 0, locale: 'es_MX', symbol: '');
    final formatoMoneda = NumberFormat.currency(decimalDigits: 2, locale: 'es_MX', symbol: '\$');

    String descripcionProducto = producto!.descripcion;
    if(producto!.requiereMedida){
      descripcionProducto += ' (${detalle!.ancho} x ${detalle!.alto})';
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: index % 2 == 0
          ? AppTheme.tablaColor1
          : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Text(formatoNumero.format(detalle!.cantidad), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(descripcionProducto, textAlign: TextAlign.center)),
          Expanded(child: Text(formatoMoneda.format(producto!.precio), textAlign: TextAlign.center)),
          Expanded(child: Text(formatoMoneda.format(detalle!.descuentoAplicado), textAlign: TextAlign.center)),
          Expanded(child: Text(formatoMoneda.format(detalle!.subtotal - detalle!.iva), textAlign: TextAlign.center)),
          Expanded(child: Text(formatoMoneda.format(detalle!.iva), textAlign: TextAlign.center)),
          Expanded(child: Text(formatoMoneda.format(detalle!.subtotal), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}