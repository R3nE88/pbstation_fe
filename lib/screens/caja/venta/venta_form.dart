import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mostrar_dialog_permiso.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/venta/procesar_pago.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/busqueda_field.dart';
import 'package:pbstation_frontend/widgets/seleccionador_hora.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class VentaForm extends StatefulWidget {
  const VentaForm({super.key, required this.index, required this.rebuild});

  final int index;
  final Function rebuild;

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  //Variables
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  FocusNode checkboxFocus1 = FocusNode();
  FocusNode checkboxFocus2 = FocusNode();

  late Clientes? clienteSelected;
  late bool entregaInmediata;
  late DateTime? fechaEntrega;
  late List<Productos> productos;
  late List<DetallesVenta> detallesVenta;
  late final TextEditingController comentariosController;

  //Todos estos son para agregar al DetallesVentaelected
  late Productos? productoSelected;
  late final TextEditingController precioController;
  late final TextEditingController cantidadController;
  late final TextEditingController anchoController;
  late final TextEditingController altoController;
  late final TextEditingController comentarioController;
  late final TextEditingController descuentoController;
  late Decimal descuentoAplicado;
  late final TextEditingController ivaController;
  late final TextEditingController productoTotalController;

  late final TextEditingController subtotalController;
  late final TextEditingController totalDescuentoController;
  late final TextEditingController totalIvaController;
  late final TextEditingController totalController;

  bool anchoError = false;
  bool altoError = false;
  bool clienteError = false;
  bool detallesError = false;

  FocusNode f8FocusNode = FocusNode();
  late final bool Function(KeyEvent event) _keyHandler;
  bool canFocus = true;

  late bool permisoDeAdmin;

  //Metodos
  Decimal formatearEntrada(String entrada){
    return Decimal.parse(entrada.replaceAll("MX\$", "").replaceAll(",", "")); 
  }

  void calcularSubtotal(){
    if (productoSelected== null) { return; }

    Decimal precio = productoSelected!.precio;
    precioController.text = Formatos.pesos.format(precio.toDouble());
    int descuento = int.tryParse(descuentoController.text.replaceAll('%', '')) ?? 0;
    int cantidad = 0;
    if (cantidadController.text.isNotEmpty){
      cantidad = int.tryParse(cantidadController.text.replaceAll(',', '')) ?? 0;
    } else { cantidad = 0; }

    CalculosDinero calcular = CalculosDinero();
    late final Map<String, dynamic> resultado;
    if (productoSelected?.requiereMedida == true && anchoController.text.isNotEmpty && altoController.text.isNotEmpty) {
       resultado = calcular.calcularSubtotalConMedida(precio, cantidad, Decimal.parse(anchoController.text), Decimal.parse(altoController.text), descuento);
    } else {
      resultado = calcular.calcularSubtotal(precio, cantidad, descuento);
    }
      ivaController.text = Formatos.pesos.format(resultado['iva']);
      productoTotalController.text = Formatos.pesos.format(resultado['total']);
      descuentoAplicado = resultado['descuento'];
      VentasStates.tabs[widget.index].descuentoAplicado = descuentoAplicado;
  }

  void calcularTotal(){
    CalculosDinero calcular = CalculosDinero();
    final Map<String, dynamic> resultado = calcular.calcularTotal(detallesVenta);

    subtotalController.text = Formatos.pesos.format(resultado['subtotal']);
    totalDescuentoController.text = Formatos.pesos.format(resultado['descuento']);
    totalIvaController.text = Formatos.pesos.format(resultado['iva']);
    totalController.text = Formatos.pesos.format(resultado['total']);
  }

  void limpiarCamposProducto() {
    productoSelected = null;
    VentasStates.tabs[widget.index].productoSelected = productoSelected;
    precioController.text = Formatos.pesos.format(0);
    cantidadController.text = '1';
    anchoController.text = '1';
    altoController.text = '1';
    comentarioController.clear();
    descuentoController.text = '0%';
    ivaController.text = Formatos.pesos.format(0);
    productoTotalController.text = Formatos.pesos.format(0);
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

    if (!mounted) return;
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
        VentasStates.tabs[widget.index].fechaEntrega = null;
        checkboxFocus1.requestFocus();
      });
      return; // Si no se seleccionó fecha o hora, no hacer nada
    }

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
      VentasStates.tabs[widget.index].entregaInmediata = false;    
      fechaEntrega = fechaSeleccionada;
      VentasStates.tabs[widget.index].fechaEntrega = fechaSeleccionada;                                    
    });

    if (!mounted) return;
    FocusScope.of(context).nextFocus();
  }

  void retrocederFocus(int veces, c) {
    for (int i = 0; i < veces; i++) {
      FocusScope.of(c).previousFocus();
    }
  }

  void procesarPago() async{
    if(!Configuracion.esCaja) return;
    
    if (detallesVenta.isEmpty || clienteSelected==null){
      if (clienteSelected==null){setState((){clienteError = true;});}
      if (detallesVenta.isEmpty){setState(() {detallesError = true;});}
      return;
    }

    canFocus = false;
    await showDialog(
      context: context,
      builder: (_) {
        
        return ProcesarPago(
          venta: Ventas(
            clienteId: clienteSelected!.id!,
            usuarioId: Login.usuarioLogeado.id!,
            sucursalId: SucursalesServices.sucursalActualID!,
            pedidoPendiente: !entregaInmediata, 
            fechaEntrega: entregaInmediata ? null : fechaEntrega?.toString(), 
            detalles: detallesVenta,
            comentariosVenta: comentarioController.text, 
            subTotal: formatearEntrada(subtotalController.text),
            descuento: formatearEntrada(totalDescuentoController.text),
            iva: formatearEntrada(totalIvaController.text),
            total: formatearEntrada(totalController.text), 
            //abonadoTotal: Decimal.parse("0"),
            //cambio: Decimal.parse("0"),
            liquidado: false, 
          ),
          rebuild: widget.rebuild, 
          index: widget.index,
        );
        
      } 
    ).then((value) {
      setState(() {
        canFocus = true;
      });
    },);
  }

  void procesarEnvio()async{
    if(Configuracion.esCaja) return;

    if (detallesVenta.isEmpty || clienteSelected==null){
      if (clienteSelected==null){setState((){clienteError = true;});}
      if (detallesVenta.isEmpty){setState(() {detallesError = true;});}
      return;
    }

    Loading.displaySpinLoading(context);

    VentasEnviadas venta = VentasEnviadas(
      clienteId: clienteSelected!.id!, 
      usuarioId: Login.usuarioLogeado.id!,
      usuario: Login.usuarioLogeado.nombre, 
      sucursalId: SucursalesServices.sucursalActualID!,
      pedidoPendiente: !entregaInmediata, 
      fechaEntrega: entregaInmediata ? null : fechaEntrega?.toString(),
      detalles: detallesVenta,
      comentariosVenta: comentarioController.text, 
      subTotal: formatearEntrada(subtotalController.text), 
      descuento: formatearEntrada(totalDescuentoController.text), 
      iva: formatearEntrada(ivaController.text), 
      total: formatearEntrada(totalController.text),
      fechaEnvio: DateTime.now().toString(),
      compu: Configuracion.nombrePC
    );

    final ventaEnviada = Provider.of<VentasEnviadasServices>(context, listen: false);
    await ventaEnviada.enviarVenta(venta);

    if(!mounted) return;
    Navigator.pop(context);

    Loading.mostrarMensaje(context, '¡Enviado a Caja!');

    widget.rebuild(widget.index);

  }

  void procesarCotizacion() async{
    if (detallesVenta.isEmpty || clienteSelected==null){
      if (clienteSelected==null){setState((){clienteError = true;});}
      if (detallesVenta.isEmpty){setState(() {detallesError = true;});}
      return;
    }
    canFocus = false;

    //Realizar cotizacion///////////////////
    Loading.displaySpinLoading(context);

    final cotizacionSvc = Provider.of<CotizacionesServices>(context, listen: false);
    final productoSvc = Provider.of<ProductosServices>(context, listen: false);
    final DateTime now = DateTime.now();
    
    for (var detalle in detallesVenta) { //Agregar precio actual a la cotizacion
      detalle.cotizacionPrecio = productoSvc.productos.firstWhere((element) => element.id == detalle.productoId).precio;
    } 

    final cotizacion = Cotizaciones(
      clienteId: clienteSelected!.id!, 
      usuarioId: Login.usuarioLogeado.id!,
      sucursalId: SucursalesServices.sucursalActualID!,
      detalles: detallesVenta, 
      fechaCotizacion: now.toString(), 
      comentariosVenta: comentariosController.text,
      subTotal: formatearEntrada(subtotalController.text),
      descuento: formatearEntrada(totalDescuentoController.text),
      iva: formatearEntrada(ivaController.text),
      total: formatearEntrada(totalController.text), 
      vigente: true
    );

    String folio = await cotizacionSvc.createCotizacion(cotizacion);
    
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    String vigencia = '${lastDayOfMonth.day}/${lastDayOfMonth.month}/${lastDayOfMonth.year}';
    //Realizar cotizacion finalizado ///////////////

    if (!mounted) return;
    Navigator.pop(context);
    
    await showDialog(
      context: context,
      builder: (_) {
        
        return AlertDialog(
          backgroundColor: AppTheme.containerColor2,
          title: Center(child: const Text('  ¡Cotizacion guardada!  ')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "La cotización será válida hasta el último\ndía del mes en curso.", 
                style: TextStyle(color: Colors.white38),
                textAlign: TextAlign.center,
              ), const SizedBox(height: 10),
              const Text('Vigencia:', textScaler: TextScaler.linear(1.1)),
              Text(vigencia, style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.25)),
              const SizedBox(height: 10),
              SelectableText('Folio: $folio', textScaler: TextScaler.linear(1.1)),
              
              const SizedBox(height: 25),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: (){}, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.print, color: Colors.transparent),
                        Transform.translate(
                          offset: Offset(0, -1.5),
                          child: const Text('  Imprimir')
                        ),
                        const Icon(Icons.print),
                      ],
                    )
                  ), const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: (){}, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.send, color: Colors.transparent),
                        Transform.translate(
                          offset: Offset(0, -1.5),
                          child:  const Text('  Enviar por WhatsApp'),
                        ),
                        const Icon(Icons.send),
                      ],
                    )
                  ), const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: (){}, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.email, color: Colors.transparent),
                        Transform.translate(
                          offset: Offset(0, -1.5),
                          child: const Text('  Enviar por Correo'),
                        ),
                        const Icon(Icons.email),
                      ],
                    )
                  )
                ],
              )
            ],
          ),
        );
        
      } 
    ).then((value) {
      setState(() {
        canFocus = true;
      });
      //limpiar screen
      widget.rebuild(widget.index);
    });

  }

  @override
  void initState() {
    super.initState();
    permisoDeAdmin = VentasStates.tabs[widget.index].permisoDeAdmin;

    clienteSelected = VentasStates.tabs[widget.index].clienteSelected;
    entregaInmediata = VentasStates.tabs[widget.index].entregaInmediata;
    fechaEntrega = VentasStates.tabs[widget.index].fechaEntrega;
    productos = VentasStates.tabs[widget.index].productos;
    detallesVenta = VentasStates.tabs[widget.index].detallesVenta;
    comentariosController = VentasStates.tabs[widget.index].comentariosController;

    //Todos estos son para agregar al productoSelected
    productoSelected = VentasStates.tabs[widget.index].productoSelected;
    precioController = VentasStates.tabs[widget.index].precioController;
    cantidadController = VentasStates.tabs[widget.index].cantidadController;
    anchoController = VentasStates.tabs[widget.index].anchoController;
    altoController = VentasStates.tabs[widget.index].altoController;
    comentarioController = VentasStates.tabs[widget.index].comentarioController;
    descuentoController = VentasStates.tabs[widget.index].descuentoController;
    descuentoAplicado = VentasStates.tabs[widget.index].descuentoAplicado;
    ivaController = VentasStates.tabs[widget.index].ivaController;
    productoTotalController = VentasStates.tabs[widget.index].productoTotalController;

    subtotalController = VentasStates.tabs[widget.index].subtotalController;
    totalDescuentoController = VentasStates.tabs[widget.index].totalDescuentoController;
    totalIvaController = VentasStates.tabs[widget.index].totalIvaController;
    totalController = VentasStates.tabs[widget.index].totalController;

    _keyHandler = (KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f8) {
          if (mounted && canFocus) {
            f8FocusNode.requestFocus(); // Usar el FocusNode proporcionado
            procesarPago();
          }
        }
      }
      return false; // false para no consumir el evento
    };
    HardwareKeyboard.instance.addHandler(_keyHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    
    final productosServices = Provider.of<ProductosServices>(context);
    final clientesServices = Provider.of<ClientesServices>(context);
    
    InputDecoration totalDecoration = AppTheme.inputDecorationCustom.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: detallesError ? Colors.red : AppTheme.letraClara)
      )
    );

    return Flexible( //Contenido (Body)
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: FocusScope(
            canRequestFocus: canFocus,
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
                            const Text('   Cliente *', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: BusquedaField<Clientes>(
                                    items: clientesServices.clientes,
                                    selectedItem: clienteSelected,
                                    onItemSelected: (Clientes? selected) {
                                      setState(() {
                                        clienteSelected = selected;
                                        VentasStates.tabs[widget.index].clienteSelected = selected; // Actualizar el estado global
                                        if (clienteSelected!=null){ clienteError = false; }
                                      });
                                    },
                                    displayStringForOption: (cliente) => cliente.nombre, 
                                    normalBorder: false, 
                                    icono: Icons.perm_contact_cal_sharp, 
                                    defaultFirst: false, 
                                    hintText: 'Buscar Cliente', 
                                    error: clienteError, 
                                  ),
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
                                        //TODO: agregar cliente
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
                      
                      const SizedBox(width: 15),
                      
                      Column( //Fecha de Entrega
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(' Fecha de Entrega:', style: AppTheme.subtituloPrimario),
                          const SizedBox(height: 2),
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
                                        VentasStates.tabs[widget.index].fechaEntrega = null;
                                        checkboxFocus1.requestFocus();
                                        entregaInmediata = value!;
                                        VentasStates.tabs[widget.index].entregaInmediata = value;
                                      });
                                    } 
                                  ),
                                  const Text('Se entrega en este momento  ')
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      
                      Column( 
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(''),
                          const SizedBox(height: 2),
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
                                        child: fechaEntrega==null ? Text(
                                          'Entregar en otro día  '
                                        ) :
                                        Center(
                                          child: Text(
                                          '${fechaEntrega!.day}/${fechaEntrega!.month}/${fechaEntrega!.year}',
                                          style: AppTheme.tituloClaro,
                                          )
                                        )
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
                                    const SizedBox(width: 10)
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                      
                  const SizedBox(height: 10),
                      
                  Row(
                    children: [
                      
                      Expanded(
                        child: Column( //Formulario de Producto
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   Producto *', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            BusquedaField<Productos>(
                              items: productosServices.productos,
                              selectedItem: productoSelected,
                              onItemSelected: (Productos? selected) {
                                setState(() {
                                  productoSelected = selected;
                                  VentasStates.tabs[widget.index].productoSelected = selected; // Actualizar el estado global
                                  calcularSubtotal();
                                });
                              },
                              //TODO: onItemUnselected clacularSubTotal
                              displayStringForOption: (producto) => producto.descripcion, 
                              normalBorder: true, 
                              icono: Icons.copy, 
                              defaultFirst: false, 
                              secondaryDisplayStringForOption: (producto) => producto.codigo.toString(), 
                              hintText: 'F2', 
                              teclaFocus: LogicalKeyboardKey.f2, 
                              error: false,
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      Column( //Precio por unidad
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(' Precio/Unidad', style: AppTheme.subtituloPrimario),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 40,
                            width: 100,
                            child: TextFormField(
                              controller: precioController,
                              canRequestFocus: false,
                              readOnly: true,
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(width: 15),
                      
                      Column( //Precio por unidad
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('   Cantidad', style: AppTheme.subtituloPrimario),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 40,
                            width: 100,
                            child: Focus(
                              canRequestFocus: false,
                              onFocusChange: (value) {
                                if (value==false && cantidadController.text == ''){
                                  cantidadController.text = '1';
                                  setState(() {
                                    calcularSubtotal();
                                  });
                                }
                              },
                              child: TextFormField(
                                controller: cantidadController,
                                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                maxLength: 6,
                                inputFormatters: [ NumericFormatter() ],
                                onChanged: (value) {
                                  setState(() {
                                    calcularSubtotal();
                                  });
                                },
                                onTap: () {
                                  cantidadController.text = '';
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(width: 15),
                      
                      productoSelected?.requiereMedida==true ? Row(
                        children: [
                          Column( //Precio por unidad
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('   Ancho', style: AppTheme.subtituloPrimario),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 40,
                                width: 100,
                                child: TextFormField(
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 4,
                                  controller: anchoController,
                                  inputFormatters: [ DecimalInputFormatter() ],
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: anchoError ? AppTheme.inputError : AppTheme.inputNormal,
                                  onTap: () {
                                    anchoController.text = '';
                                  },
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
                                    
                                    //No exeder el limite de anchura
                                    if (value.isNotEmpty){
                                      if (value=="."){
                                        value="";
                                        return;
                                      }
                                      if (double.parse(value.replaceAll(",", "")) > Constantes.anchoMaximo ){
                                        anchoController.text = Constantes.anchoMaximo.toString();
                                      }
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
                
                          const SizedBox(width: 15),
                
                          Column( //Precio por unidad
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('   Alto', style: AppTheme.subtituloPrimario),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 40,
                                width: 100,
                                child: TextFormField(
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 4,
                                  controller: altoController,
                                  inputFormatters: [ DecimalInputFormatter() ],
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: altoError ? AppTheme.inputError : AppTheme.inputNormal,
                                  onTap: () {
                                    altoController.text = '';
                                  },
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

                                    //No exeder el limite de altura
                                    if (value.isNotEmpty){
                                      if (value=="."){
                                        value="";
                                        return;
                                      }
                                      if (double.parse(value.replaceAll(",", "")) > Constantes.altoMaximo ){
                                        altoController.text = Constantes.altoMaximo.toString();
                                      }
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
                      ) : const SizedBox(),
                    ],
                  ),
                      
                  const SizedBox(height: 10),
                      
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
                            const Text('   Comentario', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
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
                      
                      const SizedBox(width: 15),
                      
                      Expanded(
                        child: Column( //Formulario de Producto
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   % Descuento', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Focus(
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
                                      canRequestFocus: permisoDeAdmin,
                                      readOnly: !permisoDeAdmin,
                                      maxLength: 4,
                                      controller: descuentoController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: permisoDeAdmin 
                                      ? InputDecoration(
                                        isDense: true,
                                        prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
                                      )
                                      : InputDecoration(
                                        isDense: true,
                                        prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppTheme.letraClara
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(30),
                                            bottomLeft: Radius.circular(30),
                                          )
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppTheme.letraClara,
                                            width: 2
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(30),
                                            bottomLeft: Radius.circular(30),
                                          )
                                        )
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
                                ),
                                permisoDeAdmin
                                ? const SizedBox()
                                : Container(
                                  height: 40,
                                  width: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(30),
                                      bottomRight: Radius.circular(30),
                                    )
                                  ),
                                  child: FocusScope(
                                    canRequestFocus: false,
                                    child: IconButton(
                                      onPressed: () async{
                                        bool? permiso = await mostrarDialogoPermiso(context);
                                        if (permiso == true) {
                                          setState(() {
                                            permisoDeAdmin=true;
                                            VentasStates.tabs[widget.index].permisoDeAdmin=true;
                                          });
                                        }
                                      }, 
                                      icon: Transform.translate(
                                        offset: Offset(-2.5, 0),
                                        child: Icon(
                                          Icons.lock, 
                                          color: AppTheme.containerColor2, 
                                          size: 24
                                        ),
                                      )
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      Expanded(
                        child: Column( //Formulario de Producto
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('   IVA (${Configuracion.iva}%)', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              child: TextFormField(
                                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                maxLength: 3,
                                controller: ivaController,
                                canRequestFocus: false,
                                readOnly: true,
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      Expanded(
                        child: Column( //Formulario de Producto
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   Total', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
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
                      
                      const SizedBox(width: 15),
                      
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
                            ancho: Decimal.parse(anchoController.text), 
                            alto: Decimal.parse(altoController.text), 
                            comentarios: comentarioController.text,
                            descuento: int.tryParse(descuentoController.text.replaceAll('%', '').replaceAll(',', '')) ?? 0,
                            descuentoAplicado: descuentoAplicado,
                            iva: Decimal.parse(ivaController.text.replaceAll('MX\$', '').replaceAll(',', '')),
                            subtotal: Decimal.parse(productoTotalController.text.replaceAll('MX\$', '').replaceAll(',', ''))
                          );
              
                          productos.add(productoSelected!);
            
                          //FocusScope.of(context).previousFocus();
                          /*FocusScope.of(context).previousFocus();
                          FocusScope.of(context).previousFocus();
                          FocusScope.of(context).previousFocus();
                          
                          if (productoSelected!.requiereMedida){
                            FocusScope.of(context).previousFocus();
                            FocusScope.of(context).previousFocus();
                          }*/
            
                          setState(() {
                            detallesError = false;
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
                        style: AppTheme.botonSecundarioStyle,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Agregar Producto', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                        ),
                      )
                      
                    ],
                  ),
                      
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2, right: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Precio del dolar: ${Formatos.pesos.format(Configuracion.dolar.toDouble())}'),
                      ],
                    ),
                  ),
                      
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
                              Expanded(flex: 4, child: Text('Producto', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Descuento', textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('IVA', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.center)),
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
                                return FilaDetalles(
                                  index: index, 
                                  detalle: detallesVenta[index], 
                                  producto: productos[index],
                                  onDelete: () {
                                    detallesVenta.removeAt(index);
                                    productos.removeAt(index);
                                    calcularTotal();
                                    setState(() {});
                                  },
                                  onModificate: () {
                                    try {
                                      productoSelected = productosServices.productos.firstWhere((p) => p.id == detallesVenta[index].productoId);
                                    } catch (e) {
                                      return;
                                    }
                                    VentasStates.tabs[widget.index].productoSelected = productoSelected;
                                    precioController.text = productoSelected!.precio.toString();
                                    cantidadController.text = detallesVenta[index].cantidad.toString();
                                    anchoController.text = detallesVenta[index].ancho.toString();
                                    altoController.text = detallesVenta[index].alto.toString();
                                    comentarioController.text = detallesVenta[index].comentarios.toString();
                                    descuentoController.text = '${detallesVenta[index].descuento.toString()}%';
                                    ivaController.text = detallesVenta[index].iva.toString();
                                    productoTotalController.text = detallesVenta[index].subtotal.toString();
                                    calcularSubtotal();
            
                                    detallesVenta.removeAt(index);
                                    productos.removeAt(index);
                                    calcularTotal();
                                    setState(() {});
                                  },
                                );
                              },
                            ) : FilaDetalles(index: -1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                      
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
                                  Configuracion.esCaja ? ElevatedButton(
                                    focusNode: f8FocusNode,
                                    onPressed: (){
                                      procesarPago();
                                    },
                                    style: AppTheme.botonPrincipalStyle,
                                    child: Text('      Procesar Pago  (F8)     ', 
                                      style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                    ),
                                  ) : ElevatedButton(
                                    focusNode: f8FocusNode,
                                    onPressed: (){
                                      procesarEnvio();
                                    },
                                    style: AppTheme.botonPrincipalStyle,
                                    child: Text('      Enviar a Caja  (F8)     ', 
                                      style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: (){
                                      procesarCotizacion();
                                    },
                                    style: AppTheme.botonSecundarioStyle,
                                    child: Text('Guardar como cotizacion', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700)),
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
                                    const Text('Subtotal:  ', style: AppTheme.subtituloPrimario),
                                    SizedBox(
                                      height: 32,
                                      width: 150,
                                      child: TextFormField(
                                        controller: subtotalController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                        decoration: totalDecoration,
                                      )
                                    )
                                  ],
                                ), 
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('- Descuento:  ', style: AppTheme.subtituloPrimario),
                                    SizedBox(
                                      height: 32,
                                      width: 150,
                                      child: TextFormField(
                                        controller: totalDescuentoController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                        decoration: totalDecoration,
                                      )
                                    )
                                  ],
                                ), 
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('+ IVA:  ', style: AppTheme.subtituloPrimario),
                                    SizedBox(
                                      height: 32,
                                      width: 150,
                                      child: TextFormField(
                                        controller: totalIvaController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                        decoration: totalDecoration,
                                      )
                                    )
                                  ],
                                ), 
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('Total:  ', style: AppTheme.tituloPrimario),
                                    SizedBox(
                                      height: 36,
                                      width: 150,
                                      child: TextFormField(
                                        controller: totalController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                        decoration: totalDecoration,
                                        style: TextStyle(fontSize: 22),
                                      )
                                    )
                                  ],
                                ), 
                                const SizedBox(height: 8),
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
      ),
    );
  }
}

class FilaDetalles extends StatelessWidget {
  const FilaDetalles({
    super.key, required this.index, this.detalle, this.producto, this.onDelete, this.onModificate
  });

  final int index;
  final DetallesVenta? detalle;
  final Productos? producto;
  final VoidCallback? onDelete;
  final VoidCallback? onModificate;

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
              color: AppTheme.tablaColor1
            ),
            child: Center(child: Text('No hay productos agregados', style: TextStyle(color: Colors.transparent)))
          ),
        ],
      );
    } 

    String descripcionProducto = producto!.descripcion;
    if(producto!.requiereMedida){
      descripcionProducto += ' (${detalle!.ancho} x ${detalle!.alto})';
    }

    void mostrarMenu(BuildContext context, Offset offset) async {
      final seleccion = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy,
          offset.dx,
          offset.dy,
        ),
        color: AppTheme.dropDownColor,
        elevation: 2,
        items: [
          PopupMenuItem(
            value: 'modificar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Modificar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'eliminar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: AppTheme.letraClara, size: 17),
                Text('  Eliminar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        ],
      );

      if (seleccion == 'modificar') {
        // Lógica para modificar
        onModificate!();
      } else if (seleccion == 'eliminar') {
        // Lógica para eliminar
        onDelete!();
      }
    }
    

    return GestureDetector(
      onSecondaryTapDown: (details) {
        mostrarMenu(context, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: index % 2 == 0
            ? AppTheme.tablaColor1
            : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(child: Text(Formatos.numero.format(detalle!.cantidad.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 4, child: Text(descripcionProducto, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format(producto!.precio.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format((detalle!.subtotal + detalle!.descuentoAplicado - detalle!.iva).toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format(detalle!.descuentoAplicado.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 1, child: Text(Formatos.pesos.format(detalle!.iva.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format(detalle!.subtotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}