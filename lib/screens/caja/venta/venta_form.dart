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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _checkboxFocus1 = FocusNode();
  final _checkboxFocus2 = FocusNode();

  late Clientes? _clienteSelected;
  late bool _entregaInmediata;
  late DateTime? _fechaEntrega;
  late List<Productos> _productos;
  late List<DetallesVenta> _detallesVenta;
  late final TextEditingController _comentariosController;

  //Todos estos son para agregar al DetallesVentaelected
  late Productos? _productoSelected;
  late final TextEditingController _precioController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _anchoController;
  late final TextEditingController _altoController;
  late final TextEditingController _comentarioController;
  late final TextEditingController _descuentoController;
  late Decimal _descuentoAplicado;
  late final TextEditingController _ivaController;
  late final TextEditingController _productoTotalController;

  late final TextEditingController _subtotalController;
  late final TextEditingController _totalDescuentoController;
  late final TextEditingController _totalIvaController;
  late final TextEditingController _totalController;

  bool _anchoError = false;
  bool _altoError = false;
  bool _clienteError = false;
  bool _detallesError = false;

  final _f8FocusNode = FocusNode();
  late final bool Function(KeyEvent event) _keyHandler;
  bool _canFocus = true;

  late bool _permisoDeAdmin;

  @override
  void initState() {
    super.initState();
    _permisoDeAdmin = VentasStates.tabs[widget.index].permisoDeAdmin;

    _clienteSelected = VentasStates.tabs[widget.index].clienteSelected;
    _entregaInmediata = VentasStates.tabs[widget.index].entregaInmediata;
    _fechaEntrega = VentasStates.tabs[widget.index].fechaEntrega;
    _productos = VentasStates.tabs[widget.index].productos;
    _detallesVenta = VentasStates.tabs[widget.index].detallesVenta;
    _comentariosController = VentasStates.tabs[widget.index].comentariosController;

    //Todos estos son para agregar al productoSelected
    _productoSelected = VentasStates.tabs[widget.index].productoSelected;
    _precioController = VentasStates.tabs[widget.index].precioController;
    _cantidadController = VentasStates.tabs[widget.index].cantidadController;
    _anchoController = VentasStates.tabs[widget.index].anchoController;
    _altoController = VentasStates.tabs[widget.index].altoController;
    _comentarioController = VentasStates.tabs[widget.index].comentarioController;
    _descuentoController = VentasStates.tabs[widget.index].descuentoController;
    _descuentoAplicado = VentasStates.tabs[widget.index].descuentoAplicado;
    _ivaController = VentasStates.tabs[widget.index].ivaController;
    _productoTotalController = VentasStates.tabs[widget.index].productoTotalController;

    _subtotalController = VentasStates.tabs[widget.index].subtotalController;
    _totalDescuentoController = VentasStates.tabs[widget.index].totalDescuentoController;
    _totalIvaController = VentasStates.tabs[widget.index].totalIvaController;
    _totalController = VentasStates.tabs[widget.index].totalController;

    _keyHandler = (KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f8) {
          if (mounted && _canFocus) {
            _f8FocusNode.requestFocus(); // Usar el FocusNode proporcionado
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
    _scrollController.dispose();
    _checkboxFocus1.dispose();
    _checkboxFocus2.dispose();
    _f8FocusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    super.dispose();
  }
  
  //Metodos
  Decimal formatearEntrada(String entrada){
    return Decimal.parse(entrada.replaceAll('MX\$', '').replaceAll(',', '')); 
  }

  void calcularSubtotal(){
    if (_productoSelected== null) { return; }

    Decimal precio = _productoSelected!.precio;
    _precioController.text = Formatos.pesos.format(precio.toDouble());
    int descuento = int.tryParse(_descuentoController.text.replaceAll('%', '')) ?? 0;
    int cantidad = 0;
    if (_cantidadController.text.isNotEmpty){
      cantidad = int.tryParse(_cantidadController.text.replaceAll(',', '')) ?? 0;
    } else { cantidad = 0; }

    CalculosDinero calcular = CalculosDinero();
    late final Map<String, dynamic> resultado;
    if (_productoSelected?.requiereMedida == true && _anchoController.text.isNotEmpty && _altoController.text.isNotEmpty) {
       resultado = calcular.calcularSubtotalConMedida(precio, cantidad, Decimal.parse(_anchoController.text), Decimal.parse(_altoController.text), descuento);
    } else {
      resultado = calcular.calcularSubtotal(precio, cantidad, descuento);
    }
      _ivaController.text = Formatos.pesos.format(resultado['iva']);
      _productoTotalController.text = Formatos.pesos.format(resultado['total']);
      _descuentoAplicado = resultado['descuento'];
      VentasStates.tabs[widget.index].descuentoAplicado = _descuentoAplicado;
  }

  void calcularTotal(){
    CalculosDinero calcular = CalculosDinero();
    final Map<String, dynamic> resultado = calcular.calcularTotal(_detallesVenta);

    _subtotalController.text = Formatos.pesos.format(resultado['subtotal']);
    _totalDescuentoController.text = Formatos.pesos.format(resultado['descuento']);
    _totalIvaController.text = Formatos.pesos.format(resultado['iva']);
    _totalController.text = Formatos.pesos.format(resultado['total']);
  }

  void limpiarCamposProducto() {
    _productoSelected = null;
    VentasStates.tabs[widget.index].productoSelected = _productoSelected;
    _precioController.text = Formatos.pesos.format(0);
    _cantidadController.text = '1';
    _anchoController.text = '1';
    _altoController.text = '1';
    _comentarioController.clear();
    _descuentoController.text = '0%';
    _ivaController.text = Formatos.pesos.format(0);
    _productoTotalController.text = Formatos.pesos.format(0);
  }

  Future<void> elegirFecha()async{
    final DateTime? selectedDate = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            Dialog(
              backgroundColor: AppTheme.containerColor1,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.height * 0.5,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: const TextTheme(
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
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    );

    if (!mounted) return;
    final TimeOfDay? selectedTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Stack(
          alignment: Alignment.topRight,
          children: [
            SeleccionadorDeHora(),
            WindowBar(overlay: true),
          ],
        );
      },
    );

    if (selectedDate == null || selectedTime == null) {
      setState(() {
        _entregaInmediata = true;
        _fechaEntrega = null;
        VentasStates.tabs[widget.index].fechaEntrega = null;
        _checkboxFocus1.requestFocus();
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
      _checkboxFocus2.requestFocus();
      _entregaInmediata = false;
      VentasStates.tabs[widget.index].entregaInmediata = false;    
      _fechaEntrega = fechaSeleccionada;
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
    
    if (_detallesVenta.isEmpty || _clienteSelected==null){
      if (_clienteSelected==null){setState((){_clienteError = true;});}
      if (_detallesVenta.isEmpty){setState(() {_detallesError = true;});}
      return;
    }

    _canFocus = false;
    await showDialog(
      context: context,
      builder: (_) {
        
        return Stack(
          alignment: Alignment.topRight,
          children: [
            ProcesarPago(
              venta: Ventas(
                clienteId: _clienteSelected!.id!,
                usuarioId: VentasStates.tabs[widget.index].usuarioQueEnvioId != null ? VentasStates.tabs[widget.index].usuarioQueEnvioId! : Login.usuarioLogeado.id!,
                sucursalId: SucursalesServices.sucursalActualID!,
                pedidoPendiente: !_entregaInmediata, 
                fechaEntrega: _entregaInmediata ? null : _fechaEntrega?.toIso8601String(), 
                detalles: _detallesVenta,
                comentariosVenta: _comentarioController.text, 
                subTotal: formatearEntrada(_subtotalController.text),
                descuento: formatearEntrada(_totalDescuentoController.text),
                iva: formatearEntrada(_totalIvaController.text),
                total: formatearEntrada(_totalController.text), 
                recibidoTotal: Decimal.zero,
                liquidado: false, 
              ),
              rebuild: widget.rebuild, 
              index: widget.index,
            ),
            const WindowBar(overlay: true),
          ],
        );
        
      } 
    ).then((value) {
      //setState(() { //TODO: verificar si esto funciona sin el setState
        _canFocus = true;
      //});
    },);
  }

  void procesarEnvio()async{
    if(Configuracion.esCaja) return;

    if (_detallesVenta.isEmpty || _clienteSelected==null){
      if (_clienteSelected==null){setState((){_clienteError = true;});}
      if (_detallesVenta.isEmpty){setState(() {_detallesError = true;});}
      return;
    }

    Loading.displaySpinLoading(context);

    VentasEnviadas venta = VentasEnviadas(
      clienteId: _clienteSelected!.id!, 
      usuarioId: Login.usuarioLogeado.id!,
      usuarioNombre: Login.usuarioLogeado.nombre, 
      sucursalId: SucursalesServices.sucursalActualID!,
      pedidoPendiente: !_entregaInmediata, 
      fechaEntrega: _entregaInmediata ? null : _fechaEntrega?.toIso8601String(),
      detalles: _detallesVenta,
      comentariosVenta: _comentarioController.text, 
      subTotal: formatearEntrada(_subtotalController.text), 
      descuento: formatearEntrada(_totalDescuentoController.text), 
      iva: formatearEntrada(_ivaController.text), 
      total: formatearEntrada(_totalController.text),
      fechaEnvio: DateTime.now().toIso8601String(),
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
    if (_detallesVenta.isEmpty || _clienteSelected==null){
      if (_clienteSelected==null){setState((){_clienteError = true;});}
      if (_detallesVenta.isEmpty){setState(() {_detallesError = true;});}
      return;
    }
    _canFocus = false;

    final bool continuar = await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Deseas continuar y guardar estos\ndatos de venta como una cotizacion?', textAlign: TextAlign.center),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, false);
                    }, child: const Text('Regresar')
                  ),
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, true);
                    }, child: const Text('Continuar')
                  ),
                ],
              ),
            ],
          ),
        );
      } 
    ) ?? false;
    if (!continuar) return;

    //Realizar cotizacion///////////////////
    if(!mounted) return;
    Loading.displaySpinLoading(context);

    final cotizacionSvc = Provider.of<CotizacionesServices>(context, listen: false);
    final productoSvc = Provider.of<ProductosServices>(context, listen: false);
    final DateTime now = DateTime.now();
    
    for (var detalle in _detallesVenta) { //Agregar precio actual a la cotizacion
      detalle.cotizacionPrecio = productoSvc.productos.firstWhere((element) => element.id == detalle.productoId).precio;
    } 

    final cotizacion = Cotizaciones(
      clienteId: _clienteSelected!.id!, 
      usuarioId: Login.usuarioLogeado.id!,
      sucursalId: SucursalesServices.sucursalActualID!,
      detalles: _detallesVenta, 
      fechaCotizacion: now.toIso8601String(), 
      comentariosVenta: _comentariosController.text,
      subTotal: formatearEntrada(_subtotalController.text),
      descuento: formatearEntrada(_totalDescuentoController.text),
      iva: formatearEntrada(_ivaController.text),
      total: formatearEntrada(_totalController.text), 
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
        
        return Stack(
          alignment: Alignment.topRight,
          children: [
            AlertDialog(
              backgroundColor: AppTheme.containerColor2,
              title: const Center(child: Text('  ¡Cotizacion guardada!  ')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La cotización será válida hasta el último\ndía del mes en curso.', 
                    style: TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ), const SizedBox(height: 10),
                  const Text('Vigencia:', textScaler: TextScaler.linear(1.1)),
                  Text(vigencia, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.25)),
                  const SizedBox(height: 10),
                  SelectableText('Folio: $folio', textScaler: const TextScaler.linear(1.1)),
                  
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
                              offset: const Offset(0, -1.5),
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
                              offset: const Offset(0, -1.5),
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
                              offset: const Offset(0, -1.5),
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
            ),
            const WindowBar(overlay: true),
          ],
        );
        
      } 
    ).then((value) {
      setState(() {
        _canFocus = true;
      });
      //limpiar screen
      widget.rebuild(widget.index);
    });

  }

  @override
  Widget build(BuildContext context) {    
    final productosServices = Provider.of<ProductosServices>(context);
    final clientesServices = Provider.of<ClientesServices>(context);
    
    InputDecoration totalDecoration = AppTheme.inputDecorationCustom.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _detallesError ? Colors.red : AppTheme.letraClara)
      )
    );

    return Flexible( //Contenido (Body)
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: FocusScope(
            canRequestFocus: _canFocus,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( 
                    children: [
                      
                      Expanded(
                        child: Column( //Formulario de clientes
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
                                    selectedItem: _clienteSelected,
                                    onItemSelected: (Clientes? selected) {
                                      setState(() {
                                        _clienteSelected = selected;
                                        VentasStates.tabs[widget.index].clienteSelected = selected; // Actualizar el estado global
                                        if (_clienteSelected!=null){ _clienteError = false; }
                                      });
                                    },
                                    onItemUnselected: (){
                                      debugPrint('No se selecciono nada!');
                                    },
                                    displayStringForOption: (cliente) => cliente.nombre, 
                                    secondaryDisplayStringForOption: (cliente) => cliente.telefono.toString(), 
                                    showSecondaryFirst: false,
                                    normalBorder: false, 
                                    icono: Icons.perm_contact_cal_sharp, 
                                    defaultFirst: false, 
                                    hintText: 'Buscar Cliente', 
                                    error: _clienteError, 
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 42,
                                  decoration: const BoxDecoration(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(' Fecha de Entrega:', style: AppTheme.subtituloPrimario),
                          const SizedBox(height: 2),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(43, 255, 255, 255),
                              border: Border.all(color: AppTheme.letraClara),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  Checkbox(
                                    focusNode: _checkboxFocus1,
                                    value: _entregaInmediata, 
                                    focusColor: AppTheme.focusColor,
                                    onChanged: (value){
                                      if (_entregaInmediata==true){
                                        return;
                                      }
                                      setState(() {
                                        _fechaEntrega = null;
                                        VentasStates.tabs[widget.index].fechaEntrega = null;
                                        _checkboxFocus1.requestFocus();
                                        _entregaInmediata = value!;
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(''),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(43, 255, 255, 255),
                                  border: Border.all(color: AppTheme.letraClara),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        focusNode: _checkboxFocus2,
                                        focusColor: AppTheme.focusColor,
                                        value: !_entregaInmediata, 
                                        onChanged: (value)async {
                                          await elegirFecha();
                                        } 
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: _fechaEntrega==null ? const Text(
                                          'Entregar en otro día  '
                                        ) :
                                        Center(
                                          child: Text(
                                          '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}',
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
                                decoration: const BoxDecoration(
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
                                        _fechaEntrega == null ? '--:--:--   ' : DateFormat('hh:mm a', 'en_US').format(_fechaEntrega!), 
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   Producto *', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            BusquedaField<Productos>(
                              items: productosServices.productos,
                              selectedItem:   _productoSelected,
                              onItemSelected: (Productos? selected) {
                                setState(() {
                                  _productoSelected = selected;
                                  VentasStates.tabs[widget.index].productoSelected = selected; // Actualizar el estado global
                                  calcularSubtotal();
                                });
                              },
                              onItemUnselected: (){
                                limpiarCamposProducto();
                              },
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(' Precio/Unidad', style: AppTheme.subtituloPrimario),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 40,
                            width: 100,
                            child: TextFormField(
                              controller: _precioController,
                              canRequestFocus: false,
                              readOnly: true,
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(width: 15),
                      
                      Column( //Precio por unidad
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
                                if (value==false && _cantidadController.text == ''){
                                  _cantidadController.text = '1';
                                  setState(() {
                                    calcularSubtotal();
                                  });
                                }
                              },
                              child: TextFormField(
                                controller: _cantidadController,
                                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                maxLength: 6,
                                inputFormatters: [ NumericFormatter() ],
                                onChanged: (value) {
                                  setState(() {
                                    calcularSubtotal();
                                  });
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(width: 15),
                      
                      _productoSelected?.requiereMedida==true ? Row(
                        children: [
                          Column( //Precio por unidad
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
                                  controller: _anchoController,
                                  inputFormatters: [ DecimalInputFormatter() ],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _anchoError ? AppTheme.inputError : AppTheme.inputNormal,
                                  onChanged: (value) {
                                    if (value.isNotEmpty && value != '0') {
                                      setState(() {
                                        _anchoError = false;
                                      });
                                    } else {
                                      setState(() {
                                        _anchoError = true;
                                      });
                                    }
                                    
                                    //No exeder el limite de anchura
                                    if (value.isNotEmpty){
                                      if (value=='.'){
                                        value='';
                                        return;
                                      }
                                      if (double.parse(value.replaceAll(',', '')) > Constantes.anchoMaximo ){
                                        _anchoController.text = Constantes.anchoMaximo.toString();
                                      }
                                    }

                                    if (_anchoController.text.isNotEmpty && _altoController.text.isNotEmpty) {
                                      if (_anchoController.text != '0' && _altoController.text != '0') {
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
                                  controller: _altoController,
                                  inputFormatters: [ DecimalInputFormatter() ],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _altoError ? AppTheme.inputError : AppTheme.inputNormal,
                                  onChanged: (value) {
                                    if (value.isNotEmpty && value != '0') {
                                      setState(() {
                                        _altoError = false;
                                      });
                                    } else {
                                      setState(() {
                                        _altoError = true;
                                      });
                                    }

                                    //No exeder el limite de altura
                                    if (value.isNotEmpty){
                                      if (value=='.'){
                                        value='';
                                        return;
                                      }
                                      if (double.parse(value.replaceAll(',', '')) > Constantes.altoMaximo ){
                                        _altoController.text = Constantes.altoMaximo.toString();
                                      }
                                    }
                                    
                                    if (_anchoController.text.isNotEmpty && _altoController.text.isNotEmpty) {
                                      if (_anchoController.text != '0' && _altoController.text != '0') {
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   Comentario', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            TextFormField(
                              buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                              maxLength: 100,
                              controller: _comentarioController,
                              decoration: const InputDecoration(
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
                                        if (_descuentoController.text.isEmpty) {
                                          _descuentoController.text = '0';
                                          calcularSubtotal();
                                        }
                                        _descuentoController.text = '${_descuentoController.text.replaceAll('%', '')}%';
                                      } else {
                                        _descuentoController.text = '';
                                        calcularSubtotal();
                                      }
                                    },
                                    child: TextFormField(
                                      buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                      canRequestFocus: _permisoDeAdmin,
                                      readOnly: !_permisoDeAdmin,
                                      maxLength: 4,
                                      controller: _descuentoController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _permisoDeAdmin 
                                      ? const InputDecoration(
                                        isDense: true,
                                        prefixIcon: Icon(Icons.discount_outlined, size: 25, color: AppTheme.letra70),
                                      )
                                      : const InputDecoration(
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
                                        if (_descuentoController.text.isEmpty) {
                                          _descuentoController.text = '0';
                                        }
                                        if (int.parse(_descuentoController.text) > 100) {
                                          _descuentoController.text = '100';
                                        } 
                                        calcularSubtotal();
                                      },
                                    ),
                                  ),
                                ),
                                _permisoDeAdmin
                                ? const SizedBox()
                                : Container(
                                  height: 40,
                                  width: 42,
                                  decoration: const BoxDecoration(
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
                                        if (permiso!=null){
                                          if (permiso == true) {
                                            setState(() {
                                              _permisoDeAdmin=true;
                                              VentasStates.tabs[widget.index].permisoDeAdmin=true;
                                            });
                                          }
                                        }
                                      }, 
                                      icon: Transform.translate(
                                        offset: const Offset(-2.5, 0),
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
                                controller: _ivaController,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('   Total', style: AppTheme.subtituloPrimario),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              child: TextFormField(
                                controller: _productoTotalController,
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
                          if (_productoSelected == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  child: Text('Seleccione un producto antes de agregarlo.'),
                                )),
                                backgroundColor: Colors.red.withAlpha(100),
                              )
                            );
                            return;
                          }
            
                          if (_productoSelected!.requiereMedida == true){
                            bool isValid = true;
                            if (_anchoController.text.isEmpty || _anchoController.text == '0') {
                              isValid = false;
                              setState(() {
                                _anchoError = true;
                              });                            
                            }
                            if (_altoController.text.isEmpty || _altoController.text == '0') {
                              isValid = false;
                              setState(() {
                                _altoError = true;
                              });
                            }
                            if (!isValid) {
                              return;
                            }
                          }
            
                          DetallesVenta detalle = DetallesVenta(
                            productoId: _productoSelected!.id!,
                            cantidad: int.parse(_cantidadController.text.replaceAll(',', '')),
                            ancho: double.parse(_anchoController.text), 
                            alto: double.parse(_altoController.text), 
                            comentarios: _comentarioController.text,
                            descuento: int.tryParse(_descuentoController.text.replaceAll('%', '').replaceAll(',', '')) ?? 0,
                            descuentoAplicado: _descuentoAplicado,
                            iva: Decimal.parse(_ivaController.text.replaceAll('MX\$', '').replaceAll(',', '')),
                            subtotal: Decimal.parse(_productoTotalController.text.replaceAll('MX\$', '').replaceAll(',', ''))
                          );
              
                          _productos.add(_productoSelected!);
                        
                          setState(() {
                            _detallesError = false;
                            _detallesVenta.add(detalle);
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
                          child: const Row(
                            children: [
                              Expanded(child: Text('Cantidad', textAlign: TextAlign.center)),
                              Expanded(flex: 4, child: Text('Producto', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Descuento', textAlign: TextAlign.center)),
                              Expanded(child: Text('IVA', textAlign: TextAlign.center)),
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
                            child: _detallesVenta.isNotEmpty ? ListView.builder(
                              controller: _scrollController,
                              itemCount: _detallesVenta.length,
                              itemBuilder: (context, index) {
                                return FilaDetalles(
                                  index: index, 
                                  detalle: _detallesVenta[index], 
                                  producto: _productos[index],
                                  onDelete: () {
                                    _detallesVenta.removeAt(index);
                                    _productos.removeAt(index);
                                    calcularTotal();
                                    setState(() {});
                                  },
                                  onModificate: () {
                                    try {
                                      _productoSelected = productosServices.productos.firstWhere((p) => p.id == _detallesVenta[index].productoId);
                                    } catch (e) {
                                      return;
                                    }
                                    VentasStates.tabs[widget.index].productoSelected = _productoSelected;
                                    _precioController.text = _productoSelected!.precio.toString();
                                    _cantidadController.text = _detallesVenta[index].cantidad.toString();
                                    _anchoController.text = _detallesVenta[index].ancho.toString();
                                    _altoController.text = _detallesVenta[index].alto.toString();
                                    _comentarioController.text = _detallesVenta[index].comentarios.toString();
                                    _descuentoController.text = '${_detallesVenta[index].descuento.toString()}%';
                                    _ivaController.text = _detallesVenta[index].iva.toString();
                                    _productoTotalController.text = _detallesVenta[index].subtotal.toString();
                                    calcularSubtotal();
            
                                    _detallesVenta.removeAt(index);
                                    _productos.removeAt(index);
                                    calcularTotal();
                                    setState(() {});
                                  },
                                );
                              },
                            ) : const FilaDetalles(index: -1),
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
                          controller: _comentariosController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Comentarios de la venta',
                            hintStyle: TextStyle(color: AppTheme.letra70),
                            isDense: true,
                            contentPadding: EdgeInsets.only(left: 10, top: 20),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.all(Radius.circular(12))
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                              borderRadius: BorderRadius.all(Radius.circular(12))
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
                                    focusNode: _f8FocusNode,
                                    onPressed: (){
                                      procesarPago();
                                    },
                                    style: AppTheme.botonPrincipalStyle,
                                    child: const Text('      Procesar Pago  (F8)     ', 
                                      style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                    ),
                                  ) : ElevatedButton(
                                    focusNode: _f8FocusNode,
                                    onPressed: (){
                                      procesarEnvio();
                                    },
                                    style: AppTheme.botonPrincipalStyle,
                                    child: const Text('      Enviar a Caja  (F8)     ', 
                                      style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700)
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Tooltip( 
                                    message: 'Funcion en desarrollo', //TODO: quitar tooltip cuando lo habilite
                                    child: ElevatedButton(
                                      onPressed: (){
                                        //procesarCotizacion(); TODO: deshabilitado
                                      },
                                      child: Text('Guardar como cotizacion', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700)),
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
                                    const Text('Subtotal:  ', style: AppTheme.subtituloPrimario),
                                    SizedBox(
                                      height: 32,
                                      width: 150,
                                      child: TextFormField(
                                        controller: _subtotalController,
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
                                        controller: _totalDescuentoController,
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
                                        controller: _totalIvaController,
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
                                        controller: _totalController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                        decoration: totalDecoration,
                                        style: const TextStyle(fontSize: 22),
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
            child: const Center(child: Text('No hay productos agregados', style: TextStyle(color: Colors.transparent)))
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
          const PopupMenuItem(
            value: 'modificar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Modificar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          const PopupMenuItem(
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
            Expanded(child: Text(Formatos.pesos.format(detalle!.iva.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format(detalle!.subtotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}