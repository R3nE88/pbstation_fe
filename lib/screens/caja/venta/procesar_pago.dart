import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/ticket.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';


class ProcesarPago extends StatefulWidget {
  const ProcesarPago({
    super.key, 
    required this.venta,
    required this.rebuild, 
    this.index = 0,
    this.isDeuda = false,
    this.deudaMonto = 0
  });

  final Ventas venta;
  final Function rebuild;
  final int index;
  final bool isDeuda;
  final double deudaMonto;

  @override
  State<ProcesarPago> createState() => _ProcesarPagoState();
}

class _ProcesarPagoState extends State<ProcesarPago> with TickerProviderStateMixin {
  bool _tipoEmpty = false;
  String? _tipoTarjetaSeleccionado;
  late final List<DropdownMenuItem<String>> _dropdownItemsTipo;
  bool _efectivo = true;
  bool _tarjeta = false;
  bool _transferencia = false;
  double _efectivoImporte = 0;
  double _dolarImporte = 0;
  double _tarjetaImporte = 0;
  double _transferenciaImporte = 0;
  bool _dropMenuFocusTarjeta = false;
  bool _porPagar = true;
  bool _hayCambio = false;
  //para actualizar contador
  final List<Map<String, dynamic>> _articuloImprimible = [];
  final List<Map<String, dynamic>> _notificarContadores = [];
  Impresoras? _opcionSeleccionada;
  final List<Impresoras> _opciones = [];
  bool _opcionesInited=false;
  //Focus
  bool _isFocused = false;
  final _focusNode = FocusNode();
  final _focusEfectivo = FocusNode(); 
  final _focusDolar = FocusNode();
  final _focusTarjetaImporte = FocusNode();
  final _focusReferenciaTarjeta = FocusNode();
  final _focusDropDownMenuTarjeta = FocusNode();
  //final _focusDropDownMenuEfectivo = FocusNode();
  final _focusTransferenciaImporte = FocusNode();
  final _focusReferenciaTransferencia = FocusNode();
  final _focusAbono = FocusNode();
  final _focusCambio = FocusNode();
  final _focusRealizarPago = FocusNode();
  //Controllers
  final _formKey = GlobalKey<FormState>();
  final _efectivoCtrl = TextEditingController();
  final _dolarCtrl = TextEditingController();
  final _tarjetaImpCtrl = TextEditingController();
  final _tarjetaRefCtrl = TextEditingController();
  final _transImpCtrl = TextEditingController();
  final _transRefCtrl = TextEditingController();
  final _abonarCtrl = TextEditingController();
  final _cambioCtrl = TextEditingController();
  final _adeudoCtrl = TextEditingController(); //Total
  final _saldoCtrl = TextEditingController(); //PorPagar
  bool _endeudar = false;

  @override
  void initState() {
    super.initState();

    //para lo de las impresoras
    if (widget.isDeuda==false){
      for (var detalle in widget.venta.detalles) {
        Productos producto = Provider.of<ProductosServices>(context, listen: false).productos.firstWhere((element) => element.id == detalle.productoId);
        if (producto.imprimible){
          _articuloImprimible.add({'valor_impresion':producto.valorImpresion, 'cantidad':detalle.cantidad, 'producto': producto.descripcion});
        }
      }
      final impSvc = Provider.of<ImpresorasServices>(context, listen: false);
      if (_articuloImprimible.isNotEmpty){
        impSvc.loadImpresoras(false);
      }
    }

    //constantes de dropDown
    _dropdownItemsTipo = Constantes.tarjeta.entries
        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
        .toList();
    _tipoTarjetaSeleccionado = _dropdownItemsTipo.first.value;

    //Inicializaciones
    _abonarCtrl.text = 'MX\$0.00';
    _cambioCtrl.text = Formatos.pesos.format(0);
    _adeudoCtrl.text = widget.isDeuda ? Formatos.pesos.format(widget.deudaMonto) : Formatos.pesos.format(widget.venta.total.toDouble());
    _saldoCtrl.text = widget.isDeuda ? Formatos.pesos.format(widget.deudaMonto) : Formatos.pesos.format(widget.venta.total.toDouble());

    //Focus
     _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusEfectivo.dispose();
    _focusDolar.dispose();
    _focusTarjetaImporte.dispose();
    _focusReferenciaTarjeta.dispose();
    _focusDropDownMenuTarjeta.dispose();
    _focusTransferenciaImporte.dispose();
    _focusReferenciaTransferencia.dispose();
    _focusAbono.dispose();
    _focusCambio.dispose();
    _focusRealizarPago.dispose();
    _efectivoCtrl.dispose();
    _dolarCtrl.dispose();
    _tarjetaImpCtrl.dispose(); 
    _tarjetaRefCtrl.dispose();
    _transImpCtrl.dispose();
    _transRefCtrl.dispose();
    _abonarCtrl.dispose();
    _cambioCtrl.dispose();
    _adeudoCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  //Metodos
  double formatearEntrada(String entrada){
    return double.tryParse(entrada.replaceAll('MX\$', '').replaceAll('US\$', '').replaceAll('\$', '').replaceAll(',', '')) ?? 0;
  }

  double calcularImporte(){
    double entrada = 0;
    if (_efectivo){
      entrada += _efectivoImporte;
      entrada += CalculosDinero().dolarAPesos(_dolarImporte,  CajasServices.cajaActual!.tipoCambio);
    }
    if (_tarjeta){
      entrada += _tarjetaImporte;
    }
    if (_transferencia){
      entrada += _transferenciaImporte;
    }
    return entrada;
  }

  void calcularAbono(){
    double total = widget.isDeuda ? widget.deudaMonto : widget.venta.total.toDouble();
    
    double entrada =  calcularImporte();

    if (entrada > total) { 
      _abonarCtrl.text = Formatos.pesos.format(total);
    } else {
      _abonarCtrl.text = Formatos.pesos.format(entrada);
    }   

    calcularCambio(entrada);
  }

  void calcularCambio(double entrada){
    Decimal entradaFormat = Decimal.parse(entrada.toString());
    Decimal total = widget.isDeuda ? Decimal.parse(widget.deudaMonto.toString()) : Decimal.parse(widget.venta.total.toString());

    //Si lo abonado supera el total
    if (entradaFormat >= total){
      setState(() { _hayCambio = true; });
      _cambioCtrl.text = Formatos.pesos.format((entradaFormat - total).toDouble());
    } else {
      setState(() { _hayCambio = false; });
      _cambioCtrl.text = Formatos.pesos.format(0);
    }

    calcularTotal();
  }

  void desdeAbonarCalcular(double entrada){
    Decimal total = widget.isDeuda ? Decimal.parse(widget.deudaMonto.toString()) : Decimal.parse(widget.venta.total.toString());
    double totalImportes =  calcularImporte();

    //Si se supera la entrada al total limitar a total
    if (entrada > total.toDouble()){
      _abonarCtrl.text = Formatos.pesos.format(total.toDouble());
      entrada = total.toDouble();
    }

    //Si se supera la entrada al importe limitar a importe
    if (entrada > totalImportes){
      _abonarCtrl.text = Formatos.pesos.format(totalImportes.toDouble());
      entrada = totalImportes.toDouble();
    }

    if (totalImportes-entrada != 0){
      setState(() { _hayCambio = true; });
    } else { setState(() { _hayCambio = false; }); }

    _cambioCtrl.text = Formatos.pesos.format(totalImportes - entrada);

    calcularTotal();
  }
  
  void calcularTotal(){
    double abonado = formatearEntrada(_abonarCtrl.text);
    double total = widget.isDeuda ? widget.deudaMonto : widget.venta.total.toDouble();

    if (total - abonado == 0){
      setState(() { _porPagar = false; });
    } else { setState(() { _porPagar = true; });}

    _saldoCtrl.text = Formatos.pesos.format(total - abonado);
  }

  Future<void> procesarPago(impresoraSvc) async{
    if (!_formKey.currentState!.validate()){ return; }

    bool continuar = true; //Adevertencia de adeudo
    Decimal quedaPorPagar = Decimal.parse(formatearEntrada(_saldoCtrl.text).toString());
    if (_porPagar==true){
      await showDialog(context: context, builder: (context) { 
        continuar = false;
        String format = Formatos.pesos.format(quedaPorPagar.toDouble());
        FocusNode boton = FocusNode();
        boton.requestFocus();
        return Stack(
          alignment: Alignment.topRight,
          children: [
            AlertDialog(
              backgroundColor: AppTheme.containerColor1,
              title: Center(child: Text('Queda un saldo de $format por pagar.', textScaler: const TextScaler.linear(0.85))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Si continúa, este importe se agregará al adeudo del cliente.', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        focusNode: boton,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Regresar')
                      ),
                      ElevatedButton(
                        //focusNode: boton, 
                        onPressed: () async {
                          _endeudar = true;
                          continuar = true;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Continuar')
                      ),
                    ],
                  )
                ],
              ),
            ),
            const WindowBar(overlay: true),
          ],
        );
      });
    } //Termina la advertencia

    if (!continuar) return;
    if (!mounted) return;
    final ventasServices = Provider.of<VentasServices>(context, listen: false);

    CalculosDinero calculosDinero = CalculosDinero();
    double dolaresEnPesos = calculosDinero.dolarAPesos(_dolarImporte, CajasServices.cajaActual!.tipoCambio);
    
    Decimal? abonadoMx;
    Decimal? abonadoUs;
    Decimal? abonadoTarj;
    Decimal? abonadoTrans;
    if (_endeudar == true){
      //Si no liquido, significa que queda debiendo, asi que el importe = abonado
      abonadoMx = _efectivoImporte!=0 ? Decimal.parse(_efectivoImporte.toString()) : null;
      abonadoUs = dolaresEnPesos!= 0 ?  Decimal.parse(dolaresEnPesos.toString()) : null;
      abonadoTarj = _tarjetaImporte!= 0 ? Decimal.parse(_tarjetaImporte.toString()) : null;
      abonadoTrans = _transferenciaImporte!=0 ? Decimal.parse(_transferenciaImporte.toString()) : null;
    } else {
      //Si liquido, restar todo el sobrante a abonadoMX (si abonadoMX se vuelve negativo, significa que el empleado le dio efectivo por diferencia)
      abonadoUs = dolaresEnPesos!= 0 ? Decimal.parse(dolaresEnPesos.toString()) : null;
      abonadoTarj = _tarjetaImporte!= 0 ? Decimal.parse(_tarjetaImporte.toString()) : null;
      abonadoTrans = _transferenciaImporte!=0 ? Decimal.parse(_transferenciaImporte.toString()) : null;
      abonadoMx = _efectivoImporte!=0 ? Decimal.parse(_efectivoImporte.toString()) : null;
      abonadoMx = (abonadoMx??Decimal.zero) - Decimal.parse(_cambioCtrl.text.replaceAll('MX\$', '').replaceAll(',', ''));
      abonadoMx==Decimal.zero ? abonadoMx=null : abonadoMx;
    }

    Ventas nuevaVenta = Ventas(
      clienteId: widget.venta.clienteId,
      usuarioId: widget.venta.usuarioId,
      sucursalId: widget.venta.sucursalId,
      pedidoPendiente: widget.venta.pedidoPendiente,
      fechaEntrega: widget.venta.fechaEntrega,
      detalles: widget.venta.detalles,
      fechaVenta: DateTime.now().toIso8601String(),
      comentariosVenta: widget.venta.comentariosVenta,
      subTotal: widget.venta.subTotal,
      descuento: widget.venta.descuento,
      iva: widget.venta.iva,
      total: widget.venta.total,
      tipoTarjeta: _tarjeta ? _tipoTarjetaSeleccionado : null,
      referenciaTarj: _tarjetaRefCtrl.text,
      referenciaTrans: _transRefCtrl.text,
      recibidoMxn:_efectivoImporte!=0 ? Decimal.parse(_efectivoImporte.toString()) : null,
      recibidoUs:dolaresEnPesos!=0 ? Decimal.parse(dolaresEnPesos.toString()) : null,
      recibidoTarj:_tarjetaImporte!=0 ? Decimal.parse(_tarjetaImporte.toString()) : null,
      recibidoTrans:_transferenciaImporte!=0 ? Decimal.parse(_transferenciaImporte.toString()) : null,
      recibidoTotal: widget.venta.recibidoTotal,
      abonadoMxn: abonadoMx,
      abonadoUs: abonadoUs,
      abonadoTarj: abonadoTarj,
      abonadoTrans: abonadoTrans,
      abonadoTotal: (abonadoMx??Decimal.zero) + (abonadoUs??Decimal.zero) + (abonadoTarj??Decimal.zero) + (abonadoTrans??Decimal.zero),
      cambio: Decimal.parse(formatearEntrada(_cambioCtrl.text).toString()),    
      liquidado: !_endeudar,
      wasDeuda: _endeudar
    );
    nuevaVenta.recibidoTotal = (nuevaVenta.recibidoMxn??Decimal.zero) + (nuevaVenta.recibidoTarj??Decimal.zero) + (nuevaVenta.recibidoTrans??Decimal.zero) + (nuevaVenta.recibidoUs??Decimal.zero);

    //Realizar venta
    Ventas? venta = await ventasServices.createVenta(nuevaVenta);
    if (venta==null) return;

    //Guardar venta a corte
    if (!mounted) return;
    var corte = Provider.of<CajasServices>(context, listen: false)
    .cortesDeCaja
    .firstWhere((element) => element.id == CajasServices.corteActual!.id);
    if (!corte.ventasIds.contains(venta.id!)) { corte.ventasIds.add(venta.id!); }

    //Enduedar cliente
    if (_endeudar){
      Adeudos adeudo = Adeudos(
        ventaId: venta.id!, 
        montoPendiente: quedaPorPagar
      );
      if (!mounted) return;
      await Provider.of<ClientesServices>(context, listen: false).adeudarCliente(widget.venta.clienteId, adeudo);
    }
    
    //Sumar contadores de Impresora
    if (_notificarContadores.isNotEmpty){
      await impresoraSvc.sumarContadores(_notificarContadores);
    } 

    if (!mounted) return;
    Navigator.pop(context, true);
    
    //Ventana  de venta realizada
    String folio = venta.folio!;
    await showDialog(
      context: context,
      builder: (context) => Stack(
        alignment: Alignment.topRight,
        children: [
          VentaRealizadaDialog(venta: nuevaVenta, folio: folio, adeudo: formatearEntrada(_saldoCtrl.text).toDouble()),
          const WindowBar(overlay: true),
        ],
      )
    ).then((value) {
      //Resetear pantalla de venta principal
      widget.rebuild(widget.index);
    });
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> procesarDeuda() async{
    if (!_formKey.currentState!.validate() || _porPagar){ return; }

    if (!mounted) return;
    final ventasServices = Provider.of<VentasServices>(context, listen: false);

    CalculosDinero calculosDinero = CalculosDinero();
    double dolaresEnPesos = calculosDinero.dolarAPesos(_dolarImporte, CajasServices.cajaActual!.tipoCambio); //TODO: puedo pagar deudas si no tengo caja? si no tengo caja esto va a fallar!!
    
    Decimal? abonadoMx;
    Decimal? abonadoUs;
    Decimal? abonadoTarj;
    Decimal? abonadoTrans;

    //Si liquido, restar todo el sobrante a abonadoMX (si abonadoMX se vuelve negativo, significa que el empleado le dio efectivo por diferencia)
    abonadoUs = dolaresEnPesos!= 0 ? Decimal.parse(dolaresEnPesos.toString()) : null;
    abonadoTarj = _tarjetaImporte!= 0 ? Decimal.parse(_tarjetaImporte.toString()) : null;
    abonadoTrans = _transferenciaImporte!=0 ? Decimal.parse(_transferenciaImporte.toString()) : null;
    abonadoMx = _efectivoImporte!=0 ? Decimal.parse(_efectivoImporte.toString()) : null;
    abonadoMx = (abonadoMx??Decimal.zero) - Decimal.parse(_cambioCtrl.text.replaceAll('MX\$', '').replaceAll(',', ''));
    abonadoMx==Decimal.zero ? abonadoMx=null : abonadoMx;
    
    Ventas deudaPagada = Ventas(
      clienteId: widget.venta.clienteId,
      usuarioId: widget.venta.usuarioId,
      sucursalId: widget.venta.sucursalId,
      folio: widget.venta.folio,
      pedidoPendiente: widget.venta.pedidoPendiente,
      fechaEntrega: widget.venta.fechaEntrega,
      detalles: widget.venta.detalles,
      fechaVenta: DateTime.now().toIso8601String(),
      comentariosVenta: widget.venta.comentariosVenta,
      subTotal: widget.venta.subTotal,
      descuento: widget.venta.descuento,
      iva: widget.venta.iva,
      total: widget.venta.total,
      tipoTarjeta: _tarjeta ? _tipoTarjetaSeleccionado : null,
      referenciaTarj: _tarjetaRefCtrl.text,
      referenciaTrans: _transRefCtrl.text,
      recibidoMxn: _efectivoImporte!=0 ? Decimal.parse(_efectivoImporte.toString()) : null,
      recibidoUs:dolaresEnPesos!=0 ? Decimal.parse(dolaresEnPesos.toString()) : null,
      recibidoTarj:_tarjetaImporte!=0 ? Decimal.parse(_tarjetaImporte.toString()) : null,
      recibidoTrans:_transferenciaImporte!=0 ? Decimal.parse(_transferenciaImporte.toString()) : null,
      recibidoTotal: widget.venta.recibidoTotal,
      abonadoMxn: abonadoMx,
      abonadoUs: abonadoUs,
      abonadoTarj: abonadoTarj,
      abonadoTrans: abonadoTrans,
      abonadoTotal: widget.venta.abonadoTotal,
      cambio: Decimal.parse(formatearEntrada(_cambioCtrl.text).toString()),    
      liquidado: true,
      wasDeuda: true
    );
    deudaPagada.recibidoTotal = (deudaPagada.recibidoMxn??Decimal.zero) + (deudaPagada.recibidoUs??Decimal.zero) + (deudaPagada.recibidoTarj??Decimal.zero) + (deudaPagada.recibidoTrans??Decimal.zero);
    deudaPagada.abonadoTotal = (deudaPagada.abonadoMxn??Decimal.zero) + (deudaPagada.abonadoUs??Decimal.zero) + (deudaPagada.abonadoTarj??Decimal.zero) + (deudaPagada.abonadoTrans??Decimal.zero);
    
    Map<String, double> datosDeuda = {
      'deuda_recibido': deudaPagada.recibidoTotal.toDouble(),
      'deuda_total': widget.deudaMonto,
      'deuda_cambio': formatearEntrada(_cambioCtrl.text),
      'anterior_recibido': widget.venta.recibidoTotal.toDouble()
    };
    
    //Realizar venta
    Ventas? venta = await ventasServices.pagarDeuda(deudaPagada, widget.venta.id!);
    if (venta==null) return;

    //Guardar venta en corte
    if (!mounted) return;
    var corte = Provider.of<CajasServices>(context, listen: false)
    .cortesDeCaja
    .firstWhere((element) => element.id == CajasServices.corteActual!.id);
    if (!corte.ventasIds.contains(venta.id!)) { corte.ventasIds.add(venta.id!); }
    
    await Provider.of<ClientesServices>(context, listen: false).quitarDeuda(widget.venta.id!, widget.venta.clienteId);

    if (!mounted) return;
    Navigator.pop(context, true);
    
    String folio = venta.folio!;
    await showDialog(
      context: context,
      builder: (context) => Stack(
        alignment: Alignment.topRight,
        children: [
          VentaRealizadaDialog(venta: deudaPagada, folio: folio, adeudo: formatearEntrada(_saldoCtrl.text).toDouble(), isDeuda:true, datosDeuda: datosDeuda),
          const WindowBar(overlay: true),
        ],
      )
    );

   if (!mounted) return;
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    const int milliseconds = 300;
    final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: !widget.isDeuda);

    //Para notificar contadores
    if (!widget.isDeuda){
      if (impresoraSvc.isLoading){
        return const SimpleLoading();
      } else if (!_opcionesInited && impresoraSvc.impresoras.isNotEmpty) {
        _opciones
          ..clear()
          //..add('Seleccionar impresora')
          ..addAll(Provider.of<ImpresorasServices>(context, listen: false)
            .impresoras
            .map((impresora) => impresora) 
          );
          _opcionSeleccionada = _opciones.first;
          _opcionesInited=true;
        setState(() {});
      }
      if (_articuloImprimible.isNotEmpty && impresoraSvc.impresoras.isNotEmpty){
        return AlertDialog(
          backgroundColor: AppTheme.containerColor2,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Con qué impresora se imprimió el siguiente articulo?', style: AppTheme.tituloPrimario),
              const SizedBox(height: 10),
              Text("${_articuloImprimible[0]["cantidad"]} x ${_articuloImprimible[0]["producto"]}"),
              const SizedBox(height: 10),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _isFocused ? AppTheme.containerColor1 : AppTheme.tablaColorHeader,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Impresoras>(
                    autofocus: true,
                    focusNode: _focusNode,
                    value: _opcionSeleccionada,
                    items: _opciones.map((impresora) {
                      return DropdownMenuItem<Impresoras>(
                        value: impresora,
                        child: Text('#${impresora.numero} ${impresora.modelo}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _opcionSeleccionada = val),
                    dropdownColor: AppTheme.containerColor1,
                    style: const TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
                    iconEnabledColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: (){
                  if (_opcionSeleccionada==null) return;
                  int cantidad = _articuloImprimible[0]['cantidad'] * _articuloImprimible[0]['valor_impresion'];
                  setState(() {
                    _notificarContadores.add(_articuloImprimible.first);
                    _notificarContadores.last.addAll({'impresora':_opcionSeleccionada!.id, 'cantidad': cantidad});
                    _articuloImprimible.removeAt(0);
                  });
                }, 
                child: const Text('Siguiente')
              )
            ],
          ),
        );
      }
    }

    //Procesar pago 
    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: Text(!widget.isDeuda ? 'Procesar Pago' : 'Pagar Deuda'),
      content: AnimatedSize(
        duration: const Duration(milliseconds: milliseconds),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 6,
                    child: Form(
                      key: _formKey,
                      child: Column( 
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 350),
                                  
                          ExpandableCard(
                            onChanged: (value) async{
                              setState(() {_efectivo = value;});
                              if (value) { 
                                await Future.delayed(const Duration(milliseconds: milliseconds));
                                _focusEfectivo.requestFocus(); 
                                if ( _efectivoCtrl.text.isNotEmpty ){ calcularAbono(); }
                                if ( _dolarCtrl.text.isNotEmpty ){ calcularAbono(); }
                              } else {
                                calcularAbono();
                              }
                            },
                            title: 'Efectivo',
                            initiallyExpanded: true,
                            expandedContent: Padding(
                              padding: const EdgeInsets.only(
                                top: 3, bottom: 15, left: 12, right: 12
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextFormField(
                                    controller: _efectivoCtrl,
                                    inputFormatters: [ PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    autofocus: true,
                                    focusNode: _focusEfectivo,
                                    canRequestFocus: _efectivo,
                                    decoration: const InputDecoration(
                                      labelText: 'Importe (MXN)',
                                      labelStyle: AppTheme.labelStyle,
                                    ),
                                    onChanged: (value) {
                                      _efectivoImporte = formatearEntrada(value);
                                      calcularAbono();
                                    },
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _efectivoCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _efectivoCtrl.text.length,
                                        );
                                      });
                                    },
                                  ), const SizedBox(height: 10),
                      
                                  TextFormField(
                                    controller: _dolarCtrl,
                                    inputFormatters: [ DolaresInputFormatter()],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    autofocus: true,
                                    focusNode: _focusDolar,
                                    canRequestFocus: _efectivo,
                                    decoration: const InputDecoration(
                                      labelText: 'Importe (US)',
                                      labelStyle: AppTheme.labelStyle,
                                    ),
                                    onChanged: (value) {
                                      _dolarImporte = formatearEntrada(value);
                                      calcularAbono();
                                    },
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _dolarCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _dolarCtrl.text.length,
                                        );
                                      });
                                    },
                                  ),
                      
                                  
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                      
                          ExpandableCard(
                            onChanged: (value) async{
                              setState(() {_tarjeta = value;});
                              if (value) { 
                                await Future.delayed(const Duration(milliseconds: milliseconds));
                                _focusTarjetaImporte.requestFocus(); 
                                if ( _tarjetaImpCtrl.text.isNotEmpty ){ calcularAbono(); }
                              } else {
                                calcularAbono();
                                _dropMenuFocusTarjeta = false;
                              }
                            },
                            title: 'Tarjeta',
                            expandedContent: Padding(
                              padding: const EdgeInsets.only(top:3, bottom: 15, left: 12, right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _tarjetaImpCtrl,
                                    focusNode: _focusTarjetaImporte,
                                    canRequestFocus: _tarjeta,
                                    inputFormatters: [ PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    decoration: const InputDecoration(
                                      labelText: 'Importe',
                                      labelStyle: AppTheme.labelStyle,
                                    ),
                                    onChanged: (value) {
                                      _tarjetaImporte = formatearEntrada(value);
                                      calcularAbono();
                                    },
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _tarjetaImpCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _tarjetaImpCtrl.text.length,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _tarjetaRefCtrl,
                                          focusNode: _focusReferenciaTarjeta,
                                          canRequestFocus: _tarjeta,
                                          inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                                          buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                          maxLength: 30,
                                          decoration: const InputDecoration(
                                            labelText: 'Referencia',
                                            labelStyle: AppTheme.labelStyle,
                                          ),
                                          onTap: () {
                                            Future.delayed(Duration.zero, () {
                                              _tarjetaRefCtrl.selection = TextSelection(
                                                baseOffset: 0,
                                                extentOffset: _tarjetaRefCtrl.text.length,
                                              );
                                            });
                                          },
                                          validator: (value) {
                                            if (_tarjeta){
                                              if (value == null || value.isEmpty) {
                                                return 'Por favor ingrese la referencia';
                                              }
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      
                                      Focus(
                                        focusNode: _focusDropDownMenuTarjeta,
                                        canRequestFocus: false,
                                        onFocusChange: (value) {
                                          setState(() {
                                            _dropMenuFocusTarjeta = value;
                                          });
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 50, width: 160,
                                              decoration: BoxDecoration(
                                                color: _tarjeta ? Colors.transparent : Colors.white10,
                                                borderRadius: BorderRadius.circular(30),
                                                border: Border.all(color: Colors.white, width: _dropMenuFocusTarjeta ? 2 : 1)
                                              ),
                                            ),
                                            _tarjeta ? CustomDropDown<String>(
                                              isReadOnly: !_tarjeta,
                                              value: _tipoTarjetaSeleccionado,
                                              hintText: 'Tipo de Tarjeta',
                                              empty: _tipoEmpty,
                                              items: _dropdownItemsTipo,
                                              onChanged: (val) => setState(() {
                                                _tipoEmpty = false;
                                                _tipoTarjetaSeleccionado = val!;
                                              }),
                                            ) : const SizedBox(),
                                          ],
                                        ),
                                      ),
                                  
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                      
                          ExpandableCard(
                            onChanged: (value) async {
                              setState(() {_transferencia = value;});
                              if (value) { 
                                await Future.delayed(const Duration(milliseconds: milliseconds));
                                _focusTransferenciaImporte.requestFocus(); 
                                if ( _transImpCtrl.text.isNotEmpty ){ calcularAbono(); }
                              } else {
                                calcularAbono();
                              }
                            },
                            title: 'Transferencia',
                            expandedContent: Padding(
                              padding: const EdgeInsets.only(top:3, bottom: 15, left: 12, right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _transImpCtrl,
                                    focusNode: _focusTransferenciaImporte,
                                    canRequestFocus: _transferencia,
                                    inputFormatters: [ PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 30,
                                    decoration: const InputDecoration(
                                      labelText: 'Importe',
                                      labelStyle: AppTheme.labelStyle,
                                    ),
                                    onChanged: (value) {
                                      _transferenciaImporte = formatearEntrada(value);
                                      calcularAbono();
                                    },
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _transImpCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _transImpCtrl.text.length,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _transRefCtrl,
                                    focusNode: _focusReferenciaTransferencia,
                                    canRequestFocus: _transferencia,
                                    inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    //maxLength: 10,
                                    decoration: const InputDecoration(
                                      labelText: 'Referencia',
                                      labelStyle: AppTheme.labelStyle,
                                    ),
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _transRefCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _transRefCtrl.text.length,
                                        );
                                      });
                                    },
                                    validator: (value) {
                                      if (_transferencia){
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingrese la referencia';
                                        }
                                      }
                                      return null;
                                    },
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                  ),
                                ],
                              ),
                            ),
                          ),
                                  
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  ), 
            
                  const SizedBox(width: 10),
            
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Abonar:  ', style: AppTheme.subtituloPrimario),
                                SizedBox(
                                  height: 30,
                                  width: 150,
                                  child: TextFormField(
                                    controller: _abonarCtrl,
                                    inputFormatters: [ PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    focusNode: _focusAbono,
                                    decoration: AppTheme.inputDecorationCustom,
                                    onChanged: (value) {
                                      desdeAbonarCalcular(formatearEntrada(value));
                                    },
                                    onTap: () {
                                       Future.delayed(Duration.zero, () {
                                        _abonarCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: _abonarCtrl.text.length,
                                        );
                                      });
                                    },
                                  )
                                )
                              ],
                            ), 
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Cambio:  ', style: AppTheme.subtituloPrimario),
                                SizedBox(
                                  height: 30,
                                  width: 150,
                                  child: TextFormField(
                                    controller: _cambioCtrl,
                                    canRequestFocus: false,
                                    inputFormatters: [ MoneyInputFormatter() ],
                                    readOnly: true,
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    focusNode: _focusCambio,
                                    decoration: _hayCambio
                                    ? AppTheme.inputDecorationWaring
                                    : AppTheme.inputDecorationCustom
                                  )
                                )
                              ],
                            ), 
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Por pagar: ', style: AppTheme.tituloPrimario),
                                SizedBox(
                                  height: 30,
                                  width: 140,
                                  child: TextFormField(
                                    controller: _saldoCtrl,
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: _porPagar 
                                    ? AppTheme.inputDecorationWaringGrave
                                    : AppTheme.inputDecorationSeccess,
                                    style: const TextStyle(fontSize: 17),
                                  )
                                )
                              ],
                            ), 
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Total: ', style: AppTheme.tituloPrimario),
                                SizedBox(
                                  height: 30,
                                  width: 140,
                                  child: TextFormField(
                                    controller: _adeudoCtrl,
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: AppTheme.inputDecorationCustom,
                                    style: const TextStyle(fontSize: 17),
                                  )
                                )
                              ],
                            ), 
                            const SizedBox(height: 26),
                          ],
                        ),
                        
                        ElevatedButton(
                          focusNode: _focusRealizarPago,
                          onPressed: () {
                            if (!widget.isDeuda){
                              procesarPago(impresoraSvc);
                            } else {
                              procesarDeuda();
                            }
                          }, 
                          child: const Text('Realizar Pago')
                        )
                      ],
                    ),
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

class VentaRealizadaDialog extends StatefulWidget {
  const VentaRealizadaDialog({
    super.key, required this.venta, required this.folio, required this.adeudo, this.isDeuda = false, this.datosDeuda
  });

  final Ventas venta;
  final String folio;
  final double adeudo;
  final bool isDeuda;
  final Map<String, double>? datosDeuda;

  @override
  State<VentaRealizadaDialog> createState() => _VentaRealizadaDialogState();
}

class _VentaRealizadaDialogState extends State<VentaRealizadaDialog> {
  FocusNode boton = FocusNode();
  bool finish = false;

  Row formField(String mensaje, double value, InputDecoration decoration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$mensaje  ', style: AppTheme.subtituloPrimario),
        SizedBox(
          height: 30,
          width: 150,
          child: TextFormField(
            controller: TextEditingController(text: Formatos.pesos.format(value)),
            canRequestFocus: false,
            inputFormatters: [ MoneyInputFormatter() ],
            readOnly: true,
            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
            maxLength: 10,
            decoration: decoration
          )
        )
      ],
    );
  }

  void submited(){
    setState(() {finish;});
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    
    //imprimir ticket, abrir caja
    !widget.isDeuda ?
    Ticket.imprimirTicketVenta(context, widget.venta, widget.folio)
    : 
    Ticket.imprimirTicketDeudaPagada(context, widget.venta, widget.folio, widget.datosDeuda);
  }

  @override
  void dispose() {
    boton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (finish){
      return const SimpleLoading();
    }
        
    //si no es deuda
    return !widget.isDeuda ? AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Center(child: Text('¡Venta Realizada!', textScaler: TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          formField('Recibido:', widget.venta.recibidoTotal.toDouble(), AppTheme.inputDecorationSeccess),
          const SizedBox(height: 15),
          formField('Total:', widget.venta.total.toDouble(), AppTheme.inputDecorationCustom), 
          const SizedBox(height: 15),
          widget.venta.cambio.toDouble() == 0 
          ? formField('Adeudo:',  widget.adeudo, AppTheme.inputDecorationWaringGrave)
          : formField('Cambio:', widget.venta.cambio.toDouble(), AppTheme.inputDecorationWaring),           
        ],
      ),
      actions: [
        ElevatedButton(
          autofocus: true,
          focusNode: boton,
          onPressed: () => submited(),
          child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700))
        )
      ],
    ) 
    : //Si si es deuda
    AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Center(child: Text('¡Deuda Pagada!', textScaler: TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          formField('Recibido:', widget.datosDeuda!['deuda_recibido']!, AppTheme.inputDecorationSeccess),
          const SizedBox(height: 15),
          formField('Total:', widget.datosDeuda!['deuda_total']!, AppTheme.inputDecorationCustom), 
          const SizedBox(height: 15),
          formField('Cambio:', widget.datosDeuda!['deuda_cambio']!, AppTheme.inputDecorationWaring),           
        ],
      ),
      actions: [
        ElevatedButton(
          autofocus: true,
          focusNode: boton,
          onPressed: () => submited(),
          child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700))
        )
      ],
    );
  }
}