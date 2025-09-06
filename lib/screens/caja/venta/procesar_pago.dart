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
    required this.rebuild, required this.index
  });

  final Ventas venta;
  final Function rebuild;
  final int index;

  @override
  State<ProcesarPago> createState() => _ProcesarPagoState();
}

class _ProcesarPagoState extends State<ProcesarPago> with TickerProviderStateMixin {
  //para actualizar contador
  List<Map<String, dynamic>> notificarContadoresTmp = [];
  List<Map<String, dynamic>> notificarContadores = [];
  Impresoras? _opcionSeleccionada;
  final List<Impresoras> _opciones = [];
  bool _opcionesInited=false;

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
  bool porPagar = true;
  bool hayCambio = false;
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
  final formKey = GlobalKey<FormState>();
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

  //Metodos
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

  /*double calcularImporteEfectivo(){
    return efectivoImporte + CalculosDinero().conversionADolar(dolarImporte);
  }*/

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

    //Si se supera la entrada al total limitar a total
    if (entrada > total.toDouble()){
      abonarCtrl.text = Formatos.pesos.format(total.toDouble());
      entrada = total.toDouble();
    }

    //Si se supera la entrada al importe limitar a importe
    if (entrada > totalImportes){
      abonarCtrl.text = Formatos.pesos.format(totalImportes.toDouble());
      entrada = totalImportes.toDouble();
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
    for (var detalle in widget.venta.detalles) {
      Productos producto = Provider.of<ProductosServices>(context, listen: false).productos.firstWhere((element) => element.id == detalle.productoId);
      if (producto.imprimible){
        notificarContadoresTmp.add({"valor_impresion":producto.valorImpresion, "cantidad":detalle.cantidad, "producto": producto.descripcion});
      }
    }

    if (notificarContadoresTmp.isNotEmpty){
      Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras();
    }

    dropdownItemsTipo = Constantes.tarjeta.entries
        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
        .toList();
    tipoTarjetaSeleccionado = dropdownItemsTipo.first.value;

    abonarCtrl.text = 'MX\$0.00';
    cambioCtrl.text = Formatos.pesos.format(0);
    adeudoCtrl.text = Formatos.pesos.format(widget.venta.total.toDouble());
    saldoCtrl.text = Formatos.pesos.format(widget.venta.total.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    const int milliseconds = 300;

    //Para notificar contadores
    if (Provider.of<ImpresorasServices>(context).isLoading){
      return AlertDialog(content: Text('Cargando'));
    } else if (!_opcionesInited) {
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
    if (notificarContadoresTmp.isNotEmpty){
      return AlertDialog(
        backgroundColor: AppTheme.containerColor2,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Con que impresora Imprimio el siguiente Articulo?'),
            Text("${notificarContadoresTmp[0]["cantidad"]} x ${notificarContadoresTmp[0]["producto"]}"),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.tablaColorHeader,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Impresoras>(
                  value: _opcionSeleccionada, //TODO: poner impresora por defecto
                  items: _opciones.map((impresora) { //TODO Me quede agregando la actualizacion de contadores a la hora de cobrar
                    return DropdownMenuItem<Impresoras>(
                      value: impresora,
                      child: Text(impresora.modelo),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _opcionSeleccionada = val),
                  dropdownColor: AppTheme.containerColor2,
                  style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
                  iconEnabledColor: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: (){
                setState(() {
                  notificarContadores.add(notificarContadoresTmp.first);
                  notificarContadores.last.addAll({"impresora":"id_xd"});
                  notificarContadoresTmp.removeAt(0);
                });
              }, 
              child: Text('Siguiente')
            )
          ],
        ),
      );
    }

    //Procesar pago 
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
                    child: Form(
                      key: formKey,
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
                                          validator: (value) {
                                            if (tarjeta){
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
                                    validator: (value) {
                                      if (transferencia){
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
                          onPressed: () async{
                            if (!formKey.currentState!.validate()){
                              return;
                            }

                            //tipo de pago
                            /*String tipoDePago = '';
                            if (efectivo) { tipoDePago += ',efectivo'; } 
                            if (tarjeta) {  tipoDePago += ',tarjeta'; } 
                            if (transferencia) { tipoDePago += ',transferencia'; } 
                            tipoDePago = tipoDePago.replaceFirst(',', '');*/

                            bool continuar = true; //Adevertencia de adeudo
                            if (porPagar==true){
                              await showDialog(context: context, builder: (context) { 
                                continuar = false;
                                Decimal quedaPorPagar = Decimal.parse(formatearEntrada(saldoCtrl.text).toString());
                                String format = Formatos.pesos.format(quedaPorPagar.toDouble());
                                FocusNode boton = FocusNode();
                                boton.requestFocus();
                                return AlertDialog(
                                  backgroundColor: AppTheme.containerColor1,
                                  title: Center(child: Text('Queda un saldo de $format por pagar.', textScaler: TextScaler.linear(0.85))),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Si continúa, este importe se agregará al adeudo del cliente.', textAlign: TextAlign.center),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      focusNode: boton,
                                      onPressed: () {
                                        continuar = true;
                                        //TODO: agregar adeudo al cliente
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Continuar', style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700))
                                    )
                                  ],
                                );
                              });
                            } //Termina la advertencia


                            if (!continuar) return;
                            
                            if (!context.mounted) return;
                            final ventasServices = Provider.of<VentasServices>(context, listen: false);
                            
                            bool liquidado = formatearEntrada(abonarCtrl.text) - widget.venta.total.toDouble() == 0;
                            //double importeEfectivo = calcularImporteEfectivo();
                            Decimal abonadoMx = Decimal.parse("0");
                            Decimal abonadoUs = Decimal.parse("0");
                            Decimal abonadoTarj = Decimal.parse("0");
                            Decimal abonadoTrans = Decimal.parse("0");
                            if (liquidado == false){
                              abonadoMx = Decimal.parse(efectivoImporte.toString());
                              abonadoUs = Decimal.parse(dolarImporte.toString());
                              abonadoTarj = Decimal.parse(tarjetaImporte.toString());
                              abonadoTrans = Decimal.parse(transferenciaImporte.toString());
                            } else {
                              abonadoUs = Decimal.parse(dolarImporte.toString());
                              abonadoTarj = Decimal.parse(tarjetaImporte.toString());
                              abonadoTrans = Decimal.parse(transferenciaImporte.toString());
                              abonadoMx = Decimal.parse(efectivoImporte.toString());
                              abonadoMx = abonadoMx - Decimal.parse(cambioCtrl.text.replaceAll("MX\$", "").replaceAll(",", ""));
                            }


                            Ventas nuevaVenta = Ventas(
                              clienteId: widget.venta.clienteId,
                              usuarioId: widget.venta.usuarioId,
                              sucursalId: widget.venta.sucursalId,
                              //cajaId: CajasServices.cajaActualId!,
                              pedidoPendiente: widget.venta.pedidoPendiente,
                              fechaEntrega: widget.venta.fechaEntrega,
                              detalles: widget.venta.detalles,
                              fechaVenta: DateTime.now().toString(),
                              //tipoPago: tipoDePago,
                              comentariosVenta: widget.venta.comentariosVenta,
                              subTotal: widget.venta.subTotal,
                              descuento: widget.venta.descuento,
                              iva: widget.venta.iva,
                              total: widget.venta.total,
                              tipoTarjeta: tarjeta ? tipoTarjetaSeleccionado : null,
                              referenciaTarj: tarjetaRefCtrl.text,
                              referenciaTrans: transRefCtrl.text,
                              recibidoMxn:efectivoImporte!=0 ? Decimal.parse(efectivoImporte.toString()) : null,
                              recibidoUs:dolarImporte!=0 ? Decimal.parse(dolarImporte.toString()) : null,
                              recibidoTarj:tarjetaImporte!=0 ? Decimal.parse(tarjetaImporte.toString()) : null,
                              recibidoTrans:transferenciaImporte!=0 ? Decimal.parse(transferenciaImporte.toString()) : null,
                              abonadoMxn: abonadoMx,
                              abonadoUs: abonadoUs,
                              abonadoTarj: abonadoTarj,
                              abonadoTrans: abonadoTrans,
                              abonadoTotal: Decimal.parse(formatearEntrada(abonarCtrl.text).toString()),
                              cambio: Decimal.parse(formatearEntrada(cambioCtrl.text).toString()),    
                              liquidado: liquidado
                            );
                            
                            String folio = await ventasServices.createVenta(nuevaVenta);  

                            if (!context.mounted) return;
                            Navigator.pop(context, true);
                            
                            await showDialog(
                              context: context,
                              builder: (context) => VentaRealizadaDialog(venta: nuevaVenta, folio: folio, adeudo: formatearEntrada(saldoCtrl.text).toDouble())
                            ).then((value) {
                              //Resetear pantalla de venta principal
                              widget.rebuild(widget.index);
                            });

                            if (!context.mounted) return;
                            Navigator.pop(context);

                          }, child: const Text('Realizar Pago')
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


class VentaRealizadaDialog extends StatelessWidget {
  const VentaRealizadaDialog({
    super.key, required this.venta, required this.folio, required this.adeudo,
  });

  final Ventas venta;
  final String folio;
  final double adeudo;

  @override
  Widget build(BuildContext context) {
    FocusNode boton = FocusNode();

    //imprimir ticket, abrir caja
    Ticket.imprimirTicket(context, venta, folio);
    
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
    
    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: Center(child: Text('Gracias por La Compra!', textScaler: TextScaler.linear(0.85))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          formField('Recibido:', venta.abonadoTotal!.toDouble(), AppTheme.inputDecorationSeccess),
          const SizedBox(height: 15),
          formField('Total:', venta.total.toDouble(), AppTheme.inputDecorationCustom), 
          const SizedBox(height: 15),
          venta.cambio!.toDouble() == 0 
          ? formField('Adeudo:',  adeudo, AppTheme.inputDecorationWaringGrave)
          : formField('Cambio:', venta.cambio!.toDouble(), AppTheme.inputDecorationWaring),           
        ],
      ),
      actions: [
        ElevatedButton(
          autofocus: true,
          style: AppTheme.botonSecundarioStyle,
          focusNode: boton,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continuar', style: TextStyle(    fontWeight: FontWeight.w700))
        )
      ],
    );
  }
}