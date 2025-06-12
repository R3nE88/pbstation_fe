import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/busqueda_field.dart';
import 'package:pbstation_frontend/widgets/cliente_field.dart';
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
    late Clientes? clienteSelected;
    late bool entregaInmediata;
    late Productos? productoSelected;
    late List<Productos> productosSelected;
    late TextEditingController comentariosController;

    //Todos estos son para agregar al productoSelected
    late TextEditingController precioController;
    late TextEditingController cantidadController;
    late TextEditingController anchoController;
    late TextEditingController altoController;
    late TextEditingController comentarioController;
    late TextEditingController descuentoController;
    late TextEditingController ivaController;
    late TextEditingController totalController;

  @override
  void initState() {
    super.initState();
    clienteSelected = VentaTabState.tabs[widget.index].clienteSelected;
    entregaInmediata = VentaTabState.tabs[widget.index].entregaInmediata;
    productoSelected = VentaTabState.tabs[widget.index].productoSelected;
    productosSelected = VentaTabState.tabs[widget.index].productosSelected;
    comentariosController = VentaTabState.tabs[widget.index].comentariosController;

    //Todos estos son para agregar al productoSelected
    precioController = VentaTabState.tabs[widget.index].precioController;
    cantidadController = VentaTabState.tabs[widget.index].cantidadController;
    anchoController = VentaTabState.tabs[widget.index].anchoController;
    altoController = VentaTabState.tabs[widget.index].altoController;
    comentarioController = VentaTabState.tabs[widget.index].comentarioController;
    descuentoController = VentaTabState.tabs[widget.index].descuentoController;
    ivaController = VentaTabState.tabs[widget.index].ivaController;
    totalController = VentaTabState.tabs[widget.index].totalController;
  }

  @override
  Widget build(BuildContext context) {  
    void calcularSubtotal(){
      final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
      double precio = productoSelected?.precio ?? 0;
      precioController.text = formatoMoneda.format(precio);//'${productoSelected?.precio.toString() ?? '0.00'}\$';
      int cantidad = 0;
      if (cantidadController.text.isNotEmpty){
        cantidad = int.parse(cantidadController.text.replaceAll(',', ''));
      } else {
        cantidad = 0;
      }
      double totalSinIva = (productoSelected?.precio ?? 0) * cantidad;
      double iva = totalSinIva * 0.16; //TODO: iva
      double total = totalSinIva + iva; 
      ivaController.text = formatoMoneda.format(iva);
      totalController.text = formatoMoneda.format(total);
    }

    return Flexible( //Contenido (Body)
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                                value: entregaInmediata, 
                                focusColor: AppTheme.focusColor,
                                onChanged: (value){
                                  if (entregaInmediata==true){
                                    return;
                                  }
                                  setState(() {
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
                                    focusColor: AppTheme.focusColor,
                                    value: !entregaInmediata, 
                                    onChanged: (value){
                                      if (entregaInmediata==false){
                                        return;
                                      }
                                      setState(() {
                                        entregaInmediata = !value!;
                                        VentaTabState.tabs[widget.index].entregaInmediata = !value;
                                      });
                                    } 
                                  ),
                                  Text('Entregar en otro día  ')
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.letraClara,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('07:55 P.M', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                                ),
                                Center(
                                  child: FeedBackButton(
                                    onPressed: () {
                                      
                                    },
                                    child: Icon(Icons.calendar_month, color: AppTheme.containerColor1, size: 28)
                                  )
                                ),
                                SizedBox(width: 6)
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
                          maxLength: 2,
                          controller: anchoController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Solo números enteros positivos
                          ],
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
                          maxLength: 2,
                          controller: altoController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Solo números enteros positivos
                          ],
                        ),
                      )
                    ],
                  ),
        
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
                        TextFormField(
                          buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                          maxLength: 3,
                          controller: descuentoController,
                          canRequestFocus: false,
                          readOnly: true,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
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
                        Text('   IVA (16%)', style: AppTheme.subtituloPrimario),
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
                            controller: totalController,
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
                    onPressed: (){}, 
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
                          Expanded(child: Text('Cant', textAlign: TextAlign.center)),
                          Expanded(child: Text('Producto', textAlign: TextAlign.center)),
                          Expanded(child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                          Expanded(child: Text('Descuento', textAlign: TextAlign.center)),
                          Expanded(child: Text('Subtotal', textAlign: TextAlign.center)),
                          Expanded(child: Text('Impuestos', textAlign: TextAlign.center)),
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
                        child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.all(8.0),
                              color: index % 2 == 0
                                  ? AppTheme.tablaColor1
                                  : AppTheme.tablaColor2,
                              child: Row(
                                children: [
                                  Expanded(child: Text('1', textAlign: TextAlign.center)),
                                  Expanded(child: Text('Producto $index', textAlign: TextAlign.center)),
                                  Expanded(child: Text('\$10.00', textAlign: TextAlign.center)),
                                  Expanded(child: Text('5%', textAlign: TextAlign.center)),
                                  Expanded(child: Text('\$9.50', textAlign: TextAlign.center)),
                                  Expanded(child: Text('\$0.50', textAlign: TextAlign.center)),
                                  Expanded(child: Text('\$10.00', textAlign: TextAlign.center)),
                                ],
                              ),
                            );
                          },
                        ),
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
                                child: Text('          Realizar Pago          ', 
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
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: AppTheme.inputDecorationCustom,
                                    initialValue: '\$0.00',
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
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: AppTheme.inputDecorationCustom,
                                    initialValue: '\$0.00',
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
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: AppTheme.inputDecorationCustom,
                                    initialValue: '\$0.00',
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
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: AppTheme.inputDecorationCustom.copyWith(
                                    ),
                                    initialValue: '\$0.00',
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
    );
  }
}