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

class ProcesarPago extends StatefulWidget {
  const ProcesarPago({
    super.key, 
    required this.venta
  });

  final Ventas venta;

  @override
  State<ProcesarPago> createState() => _ProcesarPagoState();
}

class _ProcesarPagoState extends State<ProcesarPago> with TickerProviderStateMixin {
  bool tipoEmpty = false;
  String? tipoTarjetaSeleccionado;
  late final List<DropdownMenuItem<String>> dropdownItemsTipo;
  bool efectivo = true;
  bool tarjeta = false;
  bool transferencia = false;
  double efectivoImporte = 0;
  double dolarImporte = 0;
  double tarjetaImporte = 0;
  double transferenciaImporte = 0;
  bool dropMenuFocusTarjeta = false;
  bool dolares = false; 
  //Focus
  final FocusNode focusEfectivo = FocusNode(); 
  final FocusNode focusDolar = FocusNode();
  final FocusNode focusTarjetaImporte = FocusNode();
  final FocusNode focusReferenciaTarjeta = FocusNode();
  final FocusNode focusDropDownMenuTarjeta = FocusNode();
  final FocusNode focusDropDownMenuEfectivo = FocusNode();
  final FocusNode focusTransferenciaImporte = FocusNode();
  final FocusNode focusReferenciaTransferencia = FocusNode();
  final FocusNode focusAbono = FocusNode();
  final FocusNode focusCambio = FocusNode();
  final FocusNode focusRealizarPago = FocusNode();
  //Controllers
  final TextEditingController efectivoCtrl = TextEditingController();
  final TextEditingController dolarCtrl = TextEditingController();
  final TextEditingController tarjetaImpCtrl = TextEditingController();
  final TextEditingController tarjetaRefCtrl = TextEditingController();
  final TextEditingController transImpCtrl = TextEditingController();
  final TextEditingController transRefCtrl = TextEditingController();
  final TextEditingController abonarCtrl = TextEditingController();
  final TextEditingController cambioCtrl = TextEditingController();
  final TextEditingController adeudoCtrl = TextEditingController(); //Total
  final TextEditingController saldoCtrl = TextEditingController(); //PorPagar

  bool porPagar = true;
  bool hayCambio = false;

  static const int milliseconds = 300;

  double formatearEntrada(String entrada){
    return double.tryParse(entrada.replaceAll('MX\$', '').replaceAll('US\$', '').replaceAll('\$', '').replaceAll(',', '')) ?? 0;
  }

  double calcularImporte(){
    double entrada = 0;
    if (efectivo){
      entrada += efectivoImporte;
      entrada += CalculosDinero().conversionADolar(dolarImporte);
    }
    if (tarjeta){
      entrada += tarjetaImporte;
    }
    if (transferencia){
      entrada += transferenciaImporte;
    }
    return entrada;
  }

  void calcularAbono(){
    double total = widget.venta.total.toDouble();
    
    double entrada =  calcularImporte();

    if (entrada > total) { 
      abonarCtrl.text = Formatos.pesos.format(total);
    } else {
      abonarCtrl.text = Formatos.pesos.format(entrada);
    }   

    calcularCambio(entrada);
  }

  void calcularCambio(double entrada){
    Decimal entradaFormat = Decimal.parse(entrada.toString());
    Decimal total = Decimal.parse(widget.venta.total.toString());

    //Si lo abonado supera el total
    if (entradaFormat >= total){
      setState(() { hayCambio = true; });
      cambioCtrl.text = Formatos.pesos.format((entradaFormat - total).toDouble());
    } else {
      setState(() { hayCambio = false; });
      cambioCtrl.text = Formatos.pesos.format(0);
    }

    calcularTotal();
  }

  void desdeAbonarCalcular(double entrada){
    Decimal total = Decimal.parse(widget.venta.total.toString());
    double totalImportes =  calcularImporte();

    //Si se supera el importe limitar a total
    if (entrada > total.toDouble()){
      abonarCtrl.text = Formatos.pesos.format(total.toDouble());
      entrada = total.toDouble();
    }

    if (totalImportes-entrada != 0){
      setState(() { hayCambio = true; });
    } else { setState(() { hayCambio = false; }); }

    cambioCtrl.text = Formatos.pesos.format(totalImportes - entrada);

    calcularTotal();
  }
  
  void calcularTotal(){
    double abonado = formatearEntrada(abonarCtrl.text);
    double total = widget.venta.total.toDouble();

    if (total - abonado == 0){
      setState(() { porPagar = false; });
    } else { setState(() { porPagar = true; });}

    saldoCtrl.text = Formatos.pesos.format(total - abonado);
  }

  @override
  void initState() {
    super.initState();
    dropdownItemsTipo = Constantes.tarjeta.entries
        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
        .toList();

    abonarCtrl.text = 'MX\$0.00';
    cambioCtrl.text = Formatos.pesos.format(0);
    adeudoCtrl.text = Formatos.pesos.format(widget.venta.total.toDouble());
    saldoCtrl.text = Formatos.pesos.format(widget.venta.total.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    

    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Text('Procesar Pago'),
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
                    child: Column( 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 350),
            
                        ExpandableCard(
                          onChanged: (value) async{
                            setState(() {efectivo = value;});
                            if (value) { 
                              await Future.delayed(const Duration(milliseconds: milliseconds));
                              focusEfectivo.requestFocus(); 
                              if ( efectivoCtrl.text.isNotEmpty ){ calcularAbono(); }
                              if ( dolarCtrl.text.isNotEmpty ){ calcularAbono(); }
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
                                  controller: efectivoCtrl,
                                  inputFormatters: [ PesosInputFormatter() ],
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 10,
                                  autofocus: true,
                                  focusNode: focusEfectivo,
                                  canRequestFocus: efectivo,
                                  decoration: InputDecoration(
                                    labelText: 'Importe (MXN)',
                                    labelStyle: AppTheme.labelStyle,
                                  ),
                                  onChanged: (value) {
                                    efectivoImporte = formatearEntrada(value);
                                    calcularAbono();
                                  },
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      efectivoCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: efectivoCtrl.text.length,
                                      );
                                    });
                                  },
                                ), const SizedBox(height: 10),

                                TextFormField(
                                  controller: dolarCtrl,
                                  inputFormatters: [ DolaresInputFormatter()],
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 10,
                                  autofocus: true,
                                  focusNode: focusDolar,
                                  canRequestFocus: efectivo,
                                  decoration: InputDecoration(
                                    labelText: 'Importe (US)',
                                    labelStyle: AppTheme.labelStyle,
                                  ),
                                  onChanged: (value) {
                                    dolarImporte = formatearEntrada(value);
                                    calcularAbono();
                                  },
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      dolarCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: dolarCtrl.text.length,
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
                            setState(() {tarjeta = value;});
                            if (value) { 
                              await Future.delayed(const Duration(milliseconds: milliseconds));
                              focusTarjetaImporte.requestFocus(); 
                              if ( tarjetaImpCtrl.text.isNotEmpty ){ calcularAbono(); }
                            } else {
                              calcularAbono();
                              dropMenuFocusTarjeta = false;
                            }
                          },
                          title: 'Tarjeta',
                          initiallyExpanded: false,
                          expandedContent: Padding(
                            padding: const EdgeInsets.only(top:3, bottom: 15, left: 12, right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: tarjetaImpCtrl,
                                  focusNode: focusTarjetaImporte,
                                  canRequestFocus: tarjeta,
                                  inputFormatters: [ PesosInputFormatter() ],
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    labelText: 'Importe',
                                    labelStyle: AppTheme.labelStyle,
                                  ),
                                  onChanged: (value) {
                                    tarjetaImporte = formatearEntrada(value);
                                    calcularAbono();
                                  },
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      tarjetaImpCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: tarjetaImpCtrl.text.length,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: tarjetaRefCtrl,
                                        focusNode: focusReferenciaTarjeta,
                                        canRequestFocus: tarjeta,
                                        inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                        maxLength: 30,
                                        decoration: InputDecoration(
                                          labelText: 'Referencia',
                                          labelStyle: AppTheme.labelStyle,
                                        ),
                                        onTap: () {
                                          Future.delayed(Duration.zero, () {
                                            tarjetaRefCtrl.selection = TextSelection(
                                              baseOffset: 0,
                                              extentOffset: tarjetaRefCtrl.text.length,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    Focus(
                                      focusNode: focusDropDownMenuTarjeta,
                                      canRequestFocus: false,
                                      onFocusChange: (value) {
                                        setState(() {
                                          dropMenuFocusTarjeta = value;
                                        });
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 50, width: 160,
                                            decoration: BoxDecoration(
                                              color: tarjeta ? Colors.transparent : Colors.white10,
                                              borderRadius: BorderRadius.circular(30),
                                              border: Border.all(color: Colors.white, width: dropMenuFocusTarjeta ? 2 : 1)
                                            ),
                                          ),
                                          tarjeta ? CustomDropDown<String>(
                                            isReadOnly: !tarjeta,
                                            value: tipoTarjetaSeleccionado,
                                            hintText: 'Tipo de Tarjeta',
                                            empty: tipoEmpty,
                                            items: dropdownItemsTipo,
                                            onChanged: (val) => setState(() {
                                              tipoEmpty = false;
                                              tipoTarjetaSeleccionado = val!;
                                            }),
                                          ) : SizedBox(),
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
                            setState(() {transferencia = value;});
                            if (value) { 
                              await Future.delayed(const Duration(milliseconds: milliseconds));
                              focusTransferenciaImporte.requestFocus(); 
                              if ( transImpCtrl.text.isNotEmpty ){ calcularAbono(); }
                            } else {
                              calcularAbono();
                            }
                          },
                          title: 'Transferencia',
                          initiallyExpanded: false,
                          expandedContent: Padding(
                            padding: const EdgeInsets.only(top:3, bottom: 15, left: 12, right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: transImpCtrl,
                                  focusNode: focusTransferenciaImporte,
                                  canRequestFocus: transferencia,
                                  inputFormatters: [ PesosInputFormatter() ],
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 30,
                                  decoration: InputDecoration(
                                    labelText: 'Importe',
                                    labelStyle: AppTheme.labelStyle,
                                  ),
                                  onChanged: (value) {
                                    transferenciaImporte = formatearEntrada(value);
                                    calcularAbono();
                                  },
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      transImpCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: transImpCtrl.text.length,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: transRefCtrl,
                                  focusNode: focusReferenciaTransferencia,
                                  canRequestFocus: transferencia,
                                  inputFormatters: [ DecimalInputFormatter() ],
                                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    labelText: 'Referencia',
                                    labelStyle: AppTheme.labelStyle,
                                  ),
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      transRefCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: transRefCtrl.text.length,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
            
                        const SizedBox(height: 56),
                      ],
                    ),
                  ), 
            
                  SizedBox(width: 10),
            
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
                                    controller: abonarCtrl,
                                    inputFormatters: [ PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    focusNode: focusAbono,
                                    decoration: AppTheme.inputDecorationCustom,
                                    onChanged: (value) {
                                      desdeAbonarCalcular(formatearEntrada(value));
                                    },
                                    onTap: () {
                                       Future.delayed(Duration.zero, () {
                                        abonarCtrl.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: abonarCtrl.text.length,
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
                                    controller: cambioCtrl,
                                    canRequestFocus: false,
                                    inputFormatters: [ MoneyInputFormatter() ],
                                    readOnly: true,
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    focusNode: focusCambio,
                                    decoration: hayCambio
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
                                    controller: saldoCtrl,
                                    canRequestFocus: false,
                                    readOnly: true,
                                    decoration: porPagar 
                                    ? AppTheme.inputDecorationWaring
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
                                    controller: adeudoCtrl,
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
                          focusNode: focusRealizarPago,
                          onPressed: ()async{
                            final ventasServices = Provider.of<VentasServices>(context, listen: false);
                            Ventas nuevaVenta = Ventas(
                              folio: 'TODO:', //TODO: Crear folio
                              clienteId: widget.venta.clienteId,
                              usuarioId: widget.venta.usuarioId,
                              sucursalId: widget.venta.sucursalId,
                              pedidoPendiente: widget.venta.pedidoPendiente,
                              fechaEntrega: widget.venta.fechaEntrega,
                              detalles: widget.venta.detalles,
                              fechaVenta: DateTime.now().toString(),
                              tipoPago: 'TODO:', //TODO: tipo de pago
                              comentariosVenta: widget.venta.comentariosVenta,
                              subTotal: widget.venta.subTotal,
                              descuento: widget.venta.descuento,
                              iva: widget.venta.iva,
                              total: widget.venta.total,
                              recibido: Decimal.parse(calcularImporte().toString()),
                              abonado: Decimal.parse(formatearEntrada(abonarCtrl.text).toString()),
                              cambio: Decimal.parse(formatearEntrada(cambioCtrl.text).toString()),    
                              liquidado: formatearEntrada(abonarCtrl.text) - widget.venta.total.toDouble() == 0
                            );
                            await ventasServices.createVenta(nuevaVenta);                    
                          }, child: Text('Realizar Pago')
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