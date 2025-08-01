/*
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
  String? tipoEfectivo = 'pesos';
  late final List<DropdownMenuItem<String>> dropdownItemsTipo;
  late final List<DropdownMenuItem<String>> dropdownItemsEfectivo;
  bool efectivo = true;
  bool tarjeta = false;
  bool transferencia = false;
  double efectivoImporte = 0;
  double tarjetaImporte = 0;
  double transferenciaImporte = 0;
  bool dropMenuFocusTarjeta = false;
  bool dropMenuFocusEfectivo = false;
  bool dolares = false; 
  //Focus
  final FocusNode focusEfectivo = FocusNode();
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
  final TextEditingController tarjetaImpCtrl = TextEditingController();
  final TextEditingController tarjetaRefCtrl = TextEditingController();
  final TextEditingController transImpCtrl = TextEditingController();
  final TextEditingController transRefCtrl = TextEditingController();
  final TextEditingController abonarCtrl = TextEditingController();
  final TextEditingController cambioCtrl = TextEditingController();
  final TextEditingController adeudoCtrl = TextEditingController(); //Total
  final TextEditingController saldoCtrl = TextEditingController(); //PorPagar

  double formatearEntrada(String entrada){
    return double.tryParse(entrada.replaceAll('MX\$', '').replaceAll('US\$', '').replaceAll('\$', '').replaceAll(',', '')) ?? 0;
  }


  void calcularAbono(){
    double total = widget.venta.total;
    double entrada = 0;

    if (efectivo){
      if (!dolares){
        entrada += efectivoImporte;
      } else {
        entrada += CalculosDinero().conversionADolar(efectivoImporte);
      }
    }
    if (tarjeta){
      entrada += tarjetaImporte;
    }
    if (transferencia){
      entrada += transferenciaImporte;
    }

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
      cambioCtrl.text = Formatos.pesos.format((entradaFormat - total).toDouble());
    } else {
      cambioCtrl.text = Formatos.pesos.format(0);
    }

    calcularTotal();
  }

  void desdeAbonarCalcular(double entrada){
    Decimal total = Decimal.parse(widget.venta.total.toString());
    double totalImportes = 0;
    if (efectivo){
      if (!dolares){
        totalImportes += efectivoImporte;
      } else {
        totalImportes += CalculosDinero().conversionADolar(efectivoImporte);
      }
    } if (tarjeta){
      totalImportes += tarjetaImporte;
    } if (transferencia){
      totalImportes += transferenciaImporte;
    }

    //Si se supera el importe limitar a total
    if (entrada > total.toDouble()){
      abonarCtrl.text = Formatos.pesos.format(total.toDouble());
      entrada = total.toDouble();
    }

    cambioCtrl.text = Formatos.pesos.format(totalImportes - entrada);

    calcularTotal();
  }
  
  void calcularTotal(){
    double abonado = formatearEntrada(abonarCtrl.text);
    double total = widget.venta.total;

    saldoCtrl.text = Formatos.pesos.format(total - abonado);
  }

  @override
  void initState() {
    super.initState();
    dropdownItemsTipo = Constantes.tarjeta.entries
        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
        .toList();
    dropdownItemsEfectivo = Constantes.efectivo.entries
        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
        .toList();

    abonarCtrl.text = 'MX\$0.00';
    cambioCtrl.text = Formatos.pesos.format(0);
    adeudoCtrl.text = Formatos.pesos.format(widget.venta.total);
    saldoCtrl.text = Formatos.pesos.format(widget.venta.total);
  }

  @override
  Widget build(BuildContext context) {
    const int milliseconds = 300;

    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
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
                            } else {
                              calcularAbono();
                              dropMenuFocusEfectivo = false;
                            }
                          },
                          title: 'Efectivo',
                          initiallyExpanded: true,
                          expandedContent: Padding(
                            padding: const EdgeInsets.only(
                              top:0, bottom: 15, left: 12, right: 12
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: efectivoCtrl,
                                    inputFormatters: [ dolares ? DolaresInputFormatter() : PesosInputFormatter() ],
                                    buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                                    maxLength: 10,
                                    autofocus: true,
                                    focusNode: focusEfectivo,
                                    canRequestFocus: efectivo,
                                    decoration: InputDecoration(
                                      labelText: 'Importe',
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
                                  ),
                                ), const SizedBox(width: 8),

                                Focus(
                                  focusNode: focusDropDownMenuEfectivo, //focusDropDownMenu,
                                  canRequestFocus: false,
                                  onFocusChange: (value) {
                                    setState(() {
                                      dropMenuFocusEfectivo = value;
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 50, width: 102.5,
                                        decoration: BoxDecoration(
                                          color: efectivo ? Colors.transparent : Colors.white10,
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(color: Colors.white, width: dropMenuFocusEfectivo ? 2 : 1)
                                        ),
                                      ),
                                      efectivo ? CustomDropDown<String>(
                                        isReadOnly: !efectivo,
                                        value: tipoEfectivo,//tipoTarjetaSeleccionado,
                                        hintText: 'Moneda',
                                        empty: tipoEmpty,
                                        items: dropdownItemsEfectivo,
                                        onChanged: (val) => setState(() {
                                          tipoEmpty = false;
                                          tipoEfectivo = val!;
                                          if (val=='pesos'){
                                            dolares=false;
                                          } else { dolares=true; }
                                          efectivoCtrl.text = '';
                                          efectivoImporte = 0;
                                          calcularAbono();
                                          focusEfectivo.requestFocus();
                                        }),
                                      ) : const SizedBox(),
                                    ],
                                  ),
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
                                    decoration: AppTheme.inputDecorationCustom,
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
                                    decoration: AppTheme.inputDecorationCustom,
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
                            /*final ventasServices = Provider.of<VentasServices>(context, listen: false);
                            Ventas nuevaVenta = Ventas(
                            )
                            await ventasServices.createVenta(widget.venta);*/                        
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
*/