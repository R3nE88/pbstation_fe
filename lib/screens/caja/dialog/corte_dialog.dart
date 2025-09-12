import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/widgets/caja/voucher_board.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:pbstation_frontend/widgets/separador.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'dart:async';

enum StepStage { contadores, /*fondo,*/ esperandoRetiro, conteoPesos, conteoDolares, voucher, terminado}

class CorteDialog extends StatefulWidget {
  const CorteDialog({super.key});

  @override
  State<CorteDialog> createState() => _CorteDialogState();
}

class _CorteDialogState extends State<CorteDialog> {
  StepStage stage = StepStage.contadores;

  // Impresoras controllers (uno por impresora)
  final Map<String, TextEditingController> impresoraControllers = {};

  // Controlador del fondo siguiente
  //final TextEditingController proximoFondoCtrl = TextEditingController();

  // Denominaciones: ahora con tipo ('billete' | 'moneda') y valor
  final List<Map<String, dynamic>> denominacionesMxn = [
    {'value': 1000.0, 'kind': 'billete'},
    {'value': 500.0, 'kind': 'billete'},
    {'value': 200.0, 'kind': 'billete'},
    {'value': 100.0, 'kind': 'billete'},
    {'value': 50.0, 'kind': 'billete'},
    {'value': 20.0, 'kind': 'billete'}, // billete de 20
    {'value': 20.0, 'kind': 'moneda'},   // moneda de 20 (sí existe)
    {'value': 10.0, 'kind': 'moneda'},
    {'value': 5.0, 'kind': 'moneda'},
    {'value': 2.0, 'kind': 'moneda'},
    {'value': 1.0, 'kind': 'moneda'},
    {'value': 0.5, 'kind': 'moneda'},
  ];
  final List<Map<String, dynamic>> denominacionesDlls = [
    {'value': 100.0, 'kind': 'billete'},
    {'value': 50.0, 'kind': 'billete'},
    {'value': 20.0, 'kind': 'billete'},
    {'value': 10.0, 'kind': 'billete'},
    {'value': 5.0, 'kind': 'billete'},
    {'value': 2.0, 'kind': 'billete'},
    {'value': 1.0, 'kind': 'billete'}, 
    {'value': 0.50, 'kind': 'half dollar'},
    {'value': 0.25, 'kind': 'quarter'},
    {'value': 0.10, 'kind': 'dime'},
    {'value': 0.05, 'kind': 'nickel'},
    {'value': 0.01, 'kind': 'penny'},
  ];

  //Esto es para que funcione el autoFocus del dolar
  List<FocusNode> denominacionesDolarFocus = []; 

  //Para calcular el total
  double efectivoPesos = 0;
  double efectivoDolares = 0;
  double efectivoDolaresAPeso = 0;

  // Controllers para cada denominación (lista paralela a `denominaciones`)
  final List<TextEditingController> denomControllersMxn = [];
  final List<TextEditingController> denomControllersDlls = [];

  bool loadingImpresoras = false;
  bool performingRetiro = false;
  //int segundosTotales = 20;
  late int segundosRestantes;

  FocusNode primerFocusDlls = FocusNode();

  // Voucher controllers
  List<TextEditingController> debitoControllers = [];
  List<TextEditingController> creditoControllers = [];
  List<TextEditingController> transferenciaControllers = [];

  final FocusNode _voucherButtonFocus = FocusNode();

  DateTime fechaApertura = DateTime.parse(CajasServices.corteActual!.fechaApertura);
  late String fechaAperturaFormatted;
  DateTime fechaCorte = DateTime.now();
  late String fechaCorteFormatted;

  int reporteFinalPage = 1;


  @override
  void initState() {
    super.initState();
    //formatear fecha
    fechaAperturaFormatted = DateFormat("dd-MMM-yyyy hh:mm a", "es_MX").format(fechaApertura);
    fechaCorteFormatted = DateFormat("dd-MMM-yyyy hh:mm a", "es_MX").format(fechaCorte);
  
    final ventasSvc = Provider.of<VentasServices>(context, listen: false);
    ventasSvc.loadVentasDeCortePorProducto(CajasServices.corteActualId!);
    ventasSvc.loadVentasDeCorte(CajasServices.corteActualId!);

    // inicializa controladores de denominación (debe coincidir con denominaciones.length)
    for (var _ in denominacionesMxn) {
      denomControllersMxn.add(TextEditingController());
    }
    for (var _ in denominacionesDlls) {
      denomControllersDlls.add(TextEditingController());
    }

    for (var i = 0; i < denominacionesDlls.length; i++) {
      denominacionesDolarFocus.add(FocusNode());
    }

    //Segundos para mostrar mensaje
    //segundosRestantes = segundosTotales;

    // Cargar impresoras (si tu servicio devuelve async)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);

      setState(() => loadingImpresoras = true);
      impresoraSvc.loadImpresoras(true).whenComplete(() {
        _ensureImpresoraControllers(impresoraSvc);
        setState(() => loadingImpresoras = false);
      });
    });
  }

  void _ensureImpresoraControllers(ImpresorasServices svc) {
    // solo crear si hacen falta (evita recrear en build)
    if (impresoraControllers.length != svc.impresoras.length) {
      impresoraControllers.clear();
      for (var impresora in svc.impresoras) {
        //impresoraControllers.add({"impresora_id":impresora.id!, "controller":TextEditingController()});
        impresoraControllers[impresora.id!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var c in impresoraControllers.values) {
      //c["controller"].dispose();
      c.dispose();
    }
    for (var c in denomControllersMxn) {
      c.dispose();
    }
    for (var c in denomControllersDlls) {
      c.dispose();
    }
    //proximoFondoCtrl.dispose();

    for (var i = 0; i < denominacionesDolarFocus.length; i++) {
      denominacionesDolarFocus[i].dispose();
    }

    _voucherButtonFocus.dispose();

    super.dispose();
  }

  void terminarCorte(String comentario) async{
    Loading.displaySpinLoading(context);

    //Contado
    Decimal contadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(efectivoDolares).toString());
    Decimal contadoPesos = Decimal.parse(efectivoPesos.toString());
    Decimal contadoDolares = Decimal.parse(efectivoDolares.toString());
    Decimal contadoDebito = contarVouchers(debitoControllers);
    Decimal contadoCredito = contarVouchers(creditoControllers);
    Decimal contadoTransf = contarVouchers(transferenciaControllers);
    Decimal totalContado = contadoPesos + contadoUsCnv + contadoDebito + contadoCredito + contadoTransf;

    //Venta
    final ventas = Provider.of<VentasServices>(context, listen: false);
    Decimal abonadoMxn = Decimal.parse("0");
    Decimal abonadoUs = Decimal.parse("0");
    Decimal abonadoTarjD = Decimal.parse("0");
    Decimal abonadoTarjC = Decimal.parse("0");
    Decimal abonadoTrans = Decimal.parse("0");
    for (var venta in ventas.ventasDeCaja) {
      if (venta.abonadoMxn!=null){
        abonadoMxn += venta.abonadoMxn!;
      }
      if (venta.abonadoUs!=null){
        abonadoUs += venta.abonadoUs!;
      }
      if (venta.abonadoTarj!=null){
        if (venta.tipoTarjeta == "debito"){
          abonadoTarjD += venta.abonadoTarj!;
        } else if(venta.tipoTarjeta == "credito"){
          abonadoTarjC += venta.abonadoTarj!;
        }
      }
      if (venta.abonadoTrans!=null){
        abonadoTrans += venta.abonadoTrans!;
      }
    }
    Decimal abonadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(abonadoUs.toDouble()).toString());
    Decimal ventaTotal = abonadoMxn + abonadoUsCnv + abonadoTarjD + abonadoTarjC + abonadoTrans;

    //Diferencia
    Decimal diferencia = Decimal.parse("0");
    //Decimal fondo = CajasServices.corteActual!.fondoInicial;
    Decimal entrada = Decimal.parse("0");
    Decimal salida = Decimal.parse("0");
    for (var movimiento in CajasServices.corteActual!.movimientoCaja) {
      if (movimiento.tipo=="entrada"){
        entrada += Decimal.parse(movimiento.monto.toString());
      } else if (movimiento.tipo=="retiro"){
        salida += Decimal.parse(movimiento.monto.toString());
      }
    } 
    /*Decimal proximoFondo = proximoFondoCtrl.text.isNotEmpty ? Decimal.parse(proximoFondoCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) : Decimal.zero;
    diferencia = fondo - proximoFondo + entrada - salida;*/

    Cortes corte = Cortes(
      folio: CajasServices.corteActual!.folio,
      usuarioId: CajasServices.corteActual!.usuarioId, 
      sucursalId: CajasServices.corteActual!.sucursalId, 
      fechaApertura: CajasServices.cajaActual!.fechaApertura,
      fechaCorte: DateTime.now().toString(),
      contadoresFinales: convertir(impresoraControllers),
      fondoInicial: CajasServices.corteActual!.fondoInicial, 
      //proximoFondo: proximoFondo,
      conteoPesos: contadoPesos,
      conteoDolares: contadoDolares,
      conteoDebito: contadoDebito, 
      conteoCredito: contadoCredito, 
      conteoTransf: contadoTransf, 
      conteoTotal: totalContado,
      ventaPesos: abonadoMxn,
      ventaDolares: abonadoUsCnv,
      ventaDebito: abonadoTarjD,
      ventaCredito: abonadoTarjC,
      ventaTransf: abonadoTrans,
      ventaTotal: ventaTotal,
      diferencia: (diferencia + ventaTotal) - totalContado,
      movimientoCaja: CajasServices.corteActual!.movimientoCaja,
      desglosePesos: mapearDesglose(true),
      desgloseDolares: mapearDesglose(false),
      ventasIds: CajasServices.corteActual!.ventasIds,
      comentarios: comentario,
      isCierre: false
    );

    //Cerrar Corte
    final cajasSvc = Provider.of<CajasServices>(context, listen: false);
    await cajasSvc.actualizarCorte(corte, CajasServices.corteActualId!);

    CajasServices.corteActual=null;
    CajasServices.corteActualId=null;
    
    //abrir nuevo corte y asignarlo como activo
    /*if (!mounted) return;
    final cajaSvc = Provider.of<CajasServices>(context, listen: false);
    Cortes primerCorte = Cortes(
      usuarioId: Login.usuarioLogeado.id!,
      sucursalId: SucursalesServices.sucursalActualID!,
      fechaApertura: DateTime.now().toString(),
      fondoInicial: proximoFondo,
      movimientoCaja: [],
      ventasIds: [],
    );
    await cajaSvc.createCorte(primerCorte);*/

    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Map<String, int> convertir(Map<String, TextEditingController> origen) {
    return origen.map((key, controller) {
      final valorTexto = controller.text.trim();
      final valorEntero = int.tryParse(valorTexto) ?? 0; // por si está vacío o no es número
      return MapEntry(key, valorEntero);
    });
  }

  double calculateTotalMxn() {
    double total = 0.0;
    for (var i = 0; i < denomControllersMxn.length; i++) {
      final text = denomControllersMxn[i].text.trim();
      if (text.isEmpty) continue;
      final intCount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final value = denominacionesMxn[i]['value'] as double;
      total += intCount * value;
    }
    return total;
  }

  double calculateTotalDolares(){
    double total = 0.0;
    for (var i = 0; i < denomControllersDlls.length; i++) {
      final text = denomControllersDlls[i].text.trim();
      if (text.isEmpty) continue;
      final intCount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final value = denominacionesDlls[i]['value'] as double;
      total += intCount * value;
    }
    return total;
  }

  void _nextStage() async {
    switch (stage) {
      case StepStage.contadores:
        setState(() {
          performingRetiro = true;
          stage = StepStage.esperandoRetiro;
          }
        );
        /*for (var i = 0; i < segundosTotales; i++) {
            await Future.delayed(const Duration(seconds: 1));
            if (performingRetiro==false){
              return;
            }
            setState(() {
              segundosRestantes--;
            });
          }
          if (performingRetiro==true){
            setState(() {
              performingRetiro = false;
              stage = StepStage.conteoPesos;
            });
          }*/
        break;
      /*case StepStage.fondo:
        if(proximoFondoCtrl.text.isNotEmpty){
          setState(() {
            performingRetiro = true;
            stage = StepStage.esperandoRetiro;
          });
          for (var i = 0; i < segundosTotales; i++) {
            await Future.delayed(const Duration(seconds: 1));
            if (performingRetiro==false){
              return;
            }
            setState(() {
              segundosRestantes--;
            });
          }
          if (performingRetiro==true){
            setState(() {
              performingRetiro = false;
              stage = StepStage.conteoPesos;
            });
          }
        } else {
          setState(() {
            performingRetiro = false;
            stage = StepStage.conteoPesos;
          });
        }
        break;*/
      case StepStage.esperandoRetiro:
        break;
      case StepStage.conteoPesos:
        setState(() => stage = StepStage.conteoDolares);
        denominacionesDolarFocus.first.requestFocus();
        break;
      case StepStage.conteoDolares:
      setState(() => stage = StepStage.voucher);
        break;
      case StepStage.voucher:
      setState(() => stage = StepStage.terminado);
        break;
      case StepStage.terminado:
        if(reporteFinalPage==2){
          setState(() {
            //reporteFinalPage=2;
          });
        }
        break;
    }
  }

  Widget _buildContadores(ImpresorasServices impresoraSvc) {
    if (loadingImpresoras) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(impresoraSvc.impresoras.length, (i) {
            final modelo = impresoraSvc.impresoras[i].modelo;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: KeyboardListener(
                onKeyEvent: (event) {
                  if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
                    _nextStage();
                  }
                },
                focusNode: FocusNode(
                  canRequestFocus: false
                ),
                child: TextFormField(
                  controller: impresoraControllers[impresoraSvc.impresoras[i].id],
                  autofocus: i == 0,
                  decoration: InputDecoration(labelText: modelo),
                  inputFormatters: [NumericFormatter()],
                  textInputAction: TextInputAction.done, 
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                  onFieldSubmitted: (value) => _nextStage,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
        ],
      ),
    );
  }

  /*Widget _buildFondoStep() {
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿Cuánto dinero quieres dejar en caja?', style: AppTheme.labelStyle),
          const SizedBox(height: 8),
          KeyboardListener(
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
                _nextStage();
              }
            },
            focusNode: FocusNode(
              canRequestFocus: false
            ),
            child: TextFormField(
              controller: proximoFondoCtrl,
              textAlign: TextAlign.center,
              inputFormatters: [PesosInputFormatter()],
              keyboardType: TextInputType.number,
              maxLength: 11,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Fondo (MXN)'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _nextStage, child: const Text('Siguiente')),
        ],
      ),
    );
  }*/

  Widget _buildEsperandoRetiro() {
    //final fondo = proximoFondoCtrl.text;
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              //mainAxisAlignment: MainAxisAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Text('¡Ahora retira el Fondo de  ', style: AppTheme.subtituloPrimario, textAlign: TextAlign.center),
                Text(Formatos.pesos.format(CajasServices.corteActual!.fondoInicial.toDouble()), style: AppTheme.tituloClaro.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                Text('para continuar con el conteo del corte!', style: AppTheme.subtituloPrimario, textAlign: TextAlign.center),
              ],
            ),
          ),
          if (performingRetiro) LinearProgressIndicator(color: AppTheme.containerColor1.withAlpha(150)),
          const SizedBox(height: 12),

          ElevatedButton(
            autofocus: true,
            onPressed: (){
              setState(() {
                performingRetiro = false;
                stage = StepStage.conteoPesos;
              });
            }, 
            //child: Text('Continuar ($segundosRestantes)')
            child: Text('Continuar')
          )
        ],
      ),
    );
  }

  Widget _buildConteoStep() {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(denominacionesMxn.length, (i) {
              final den = denominacionesMxn[i];
              final ctrl = denomControllersMxn[i];
              final value = den['value'] as double;
              final kind = den['kind'] as String;
              String label;
              if (kind == 'billete') {
                // billetes no tienen decimales (mostrar int)
                label = 'Billetes de \$${value.toInt()}';
              } else {
                // monedas: si es >=1 mostrar sin decimales, si es decimal mostrar el valor tal cual
                label = value >= 1 ? 'Monedas de \$${value.toInt()}' : 'Monedas de \$${value.toString()}';
              }
              return SizedBox(
                width: 240,
                child: TextFormField(
                  controller: ctrl,
                  autofocus: i==0,
                  decoration: InputDecoration(labelText: label),
                  inputFormatters: [NumericFormatter()],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if(value.isEmpty){ ctrl.text = "0"; }
                    setState(() { efectivoPesos = calculateTotalMxn(); });
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total contado: ${Formatos.pesos.format(efectivoPesos)}', style: AppTheme.subtituloPrimario),
              ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConteoDolaresStep() {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(denominacionesDlls.length, (i) {
              final den = denominacionesDlls[i];
              final ctrl = denomControllersDlls[i];
              final value = den['value'] as double;
              final kind = den['kind'] as String;
              String label;
              if (kind == 'billete') {
                // billetes no tienen decimales (mostrar int)
                label = 'Billetes de \$${value.toInt()}';
              } else {
                // monedas: si es >=1 mostrar sin decimales, si es decimal mostrar el valor tal cual
                label = '$kind \$${value.toStringAsFixed(2)}';
              }
              
              return SizedBox(
                width: 240,
                child: TextFormField(
                  controller: ctrl,
                  //focusNode:  i==0 ? primerFocusDlls : FocusNode(),
                  focusNode: denominacionesDolarFocus[i],
                  decoration: InputDecoration(labelText: label),
                  inputFormatters: [NumericFormatter()],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if(value.isEmpty){ ctrl.text = "0"; }
                    setState(() {
                      efectivoDolares = calculateTotalDolares();
                      efectivoDolaresAPeso = CalculosDinero().conversionADolar(efectivoDolares);
                    });
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total contado: ${Formatos.dolares.format(efectivoDolares)} (${Formatos.pesos.format(efectivoDolaresAPeso)})', style: AppTheme.subtituloPrimario),
              ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
            ],
          ),
        ],
      ),
    );
  }

  void _handleVoucherControllers(List<TextEditingController> debitoCtrl, List<TextEditingController> creditoCtrl, List<TextEditingController> transferenciaCtrl,) {
    setState(() {
      debitoControllers = debitoCtrl;
      creditoControllers = creditoCtrl;
      transferenciaControllers = transferenciaCtrl;
    });
  }

  Widget buildVoucherStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoucherBoard(
          onControllersChanged: _handleVoucherControllers,
          callback: () {
            print("Debito");
            for (var controller in debitoControllers) {
              print("Voucher: ${controller.text}");
            }
            print("credito");
            for (var controller in creditoControllers) {
              print("Voucher: ${controller.text}");
            }
            print("transferencias");
            for (var controller in transferenciaControllers) {
              print("Voucher: ${controller.text}");
            }
            _nextStage();
          },
          focusButton: _voucherButtonFocus,
        ),
      ],
    );
  }

  Widget buildReporteFinal(int page){
    final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
    if (CajasServices.corteActual==null) return SizedBox();
    return SizedBox(
      width: 1000,
      height: 616,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
      
          //Header de corte
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('#Corte: '),
                  Text(CajasServices.corteActual?.folio ?? 'error', style: AppTheme.tituloClaro),
                ],
              ),
              Row(
                children: [
                  Text('Tipo de cambio: '),
                  Text(Formatos.pesos.format(Configuracion.dolar), style: AppTheme.tituloClaro),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Abierta: '),
                  Text(fechaAperturaFormatted.toUpperCase(), style: AppTheme.tituloClaro),
                  Text(' por '),
                  Text(usuariosSvc.obtenerNombreUsuarioPorId(CajasServices.corteActual!.usuarioId), style: AppTheme.tituloClaro),
                ],
              ),
              Row(
                children: [
                  Text('Hora del corte: '),
                  Text(fechaCorteFormatted.toUpperCase(), style: AppTheme.tituloClaro),
                  Text(' por '),
                  Text(Login.usuarioLogeado.nombre, style: AppTheme.tituloClaro),
                ],
              ),
            ],
          ), const SizedBox(height: 15),

          page==1 ?Expanded(
            child: Row(
              children: [
                ReporteFinalVenta(),
                const SizedBox(width: 10),
                ReporteFinalDescuentosYVendedores(
                  callback: (){
                    reporteFinalPage=2;
                    _nextStage();
                  },
                ),
              ],
            )
          ) : Expanded(
            child: Row(
              children: [
                ReporteFinalMovimientos(
                  //proximoFondo: proximoFondoCtrl.text.isNotEmpty ? Decimal.parse(proximoFondoCtrl.text.replaceAll("MX\$", "").replaceAll(",", "")) : Decimal.parse("0"), 
                  contadoPesos: Decimal.parse(efectivoPesos.toString()), 
                  contadoDolares: Decimal.parse(efectivoDolares.toString()), 
                  contadoDebito: contarVouchers(debitoControllers), 
                  contadoCredito: contarVouchers(creditoControllers), 
                  contadoTransf: contarVouchers(transferenciaControllers), 
                ),
                const SizedBox(width: 10),
                ReporteFinalDesgloseDinero(
                  desglosePesos: mapearDesglose(true),
                  desgloseDolares: mapearDesglose(false),
                  impresoraControllers: impresoraControllers,
                  callback: (String comentario) {
                    terminarCorte(comentario);
                  },
                ),
              ],
            )
          ),
        ],
      )
    );
  }

  List<Desglose> mapearDesglose(bool pesos) {
    List<Desglose> lista = [];

    if (pesos) {
      for (var i = 0; i < denominacionesMxn.length; i++) {
        if (denomControllersMxn[i].text.isNotEmpty) {
          double denominacion = denominacionesMxn[i]["value"] as double;
          int cantidad = int.parse(denomControllersMxn[i].text.replaceAll(",", ""));
          lista.add(Desglose(denominacion: denominacion, cantidad: cantidad));
        }
      }
    } else {
      for (var i = 0; i < denominacionesDlls.length; i++) {
        if (denomControllersDlls[i].text.isNotEmpty) {
          double denominacion = denominacionesDlls[i]["value"] as double;
          int cantidad = int.parse(denomControllersDlls[i].text.replaceAll(",", ""));
          lista.add(Desglose(denominacion: denominacion, cantidad: cantidad));
        }
      }
    }

    return lista;
  }

  Decimal contarVouchers(List<TextEditingController> lista){
    Decimal total = Decimal.parse("0");
    for (var item in lista) {
      total += item.text.isNotEmpty ? Decimal.parse(item.text.replaceAll("MX\$", "").replaceAll(",", "")) : Decimal.parse("0");
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final impresoraSvc = Provider.of<ImpresorasServices>(context);
    // Aseguramos controladores si impresoras ya cargadas (por si cambia after init)
    if (impresoraControllers.length != impresoraSvc.impresoras.length && !loadingImpresoras) {
      _ensureImpresoraControllers(impresoraSvc);
    }

    Widget content;
    String title = 'Corte de Caja';

    switch (stage) {
      case StepStage.contadores:
        title = 'Registrar Contadores';
        content = _buildContadores(impresoraSvc);
        break;
      /*case StepStage.fondo:
        title = 'Siguiente Fondo';
        content = _buildFondoStep();
        break;*/
      case StepStage.esperandoRetiro:
        title = '';
        content = _buildEsperandoRetiro();
        break;
      case StepStage.conteoPesos:
        title = 'Conteo de Efectivo (MXN)';
        content = _buildConteoStep();
        break;
      case StepStage.conteoDolares:
        title = 'Conteo de Efectivo (DLLS)';
        content = _buildConteoDolaresStep();
        break;
      case StepStage.voucher:
        title = 'Conteo de Voucher';
        content = buildVoucherStep();
        break;
      case StepStage.terminado:
        title = '';
        content = buildReporteFinal(reporteFinalPage);
        break;
    }

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: title.isNotEmpty ? 
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          stage == StepStage.voucher ? 
          Transform.translate(
            offset: Offset(0, -10),
            child: Tooltip(
              mouseCursor: SystemMouseCursors.click,
              message: 
'''TAB -> Siguiente
Enter -> Descender
---------------------------
Ademas puedes navegar
con las flechas.''',
              waitDuration: Durations.short1,
              child: Icon(Icons.help_outline, color: AppTheme.letraClara,)
            )
          ) : const SizedBox()
        ],
      ) 
      : null,
      content: content,
    );
  }
}

class ReporteFinalVenta extends StatelessWidget {
  const ReporteFinalVenta({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final productos = Provider.of<ProductosServices>(context, listen: false);
    
    return Expanded(
      flex: 10,
      child: Consumer<VentasServices>(
        builder: (context, value, child) {
          Decimal subtotal = Decimal.parse('0');
          for (var venta in value.ventasPorProducto) {
            subtotal += venta.subTotal;
          }
          Decimal iva = Decimal.parse('0');
          for (var venta in value.ventasPorProducto) {
            iva += venta.iva;
          }
          Decimal total = Decimal.parse('0');
          for (var venta in value.ventasPorProducto) {
            total += venta.total;
          }
          
          return Column(
            children: [
              Separador(
                texto: 'Ventas por Articulos',
              ),
              Container(
                color: AppTheme.tablaColorHeader,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical : 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 3 , child: Center(child: Text('Cant'))),
                      Expanded(flex: 10, child: Center(child: Text('Articulos'))),
                      Expanded(flex: 8,  child: Center(child: Text('Subtotal'))),
                      Expanded(flex: 8,  child: Center(child: Text('Iva'))),
                      Expanded(flex: 8,  child: Center(child: Text('Total'))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: AppTheme.tablaColor1,
                  child: ListView.builder(
                    itemCount: value.ventasPorProducto.length,
                    itemBuilder: (context, index) {
                      Productos? producto = productos.obtenerProductoPorId(value.ventasPorProducto[index].productoId);
                      
                      return FilaProductos(
                        cantidad: value.ventasPorProducto[index].cantidad, 
                        articulo: producto!=null ? '${producto.descripcion}s' : 'no se encontro', 
                        iva: Decimal.parse(value.ventasPorProducto[index].iva.toString()), 
                        subtotal: Decimal.parse(value.ventasPorProducto[index].subTotal.toString()), 
                        total: Decimal.parse(value.ventasPorProducto[index].total.toString()), 
                        color: index+1
                      );
                    },
                  ),
                ),
              ),
              Container(
                color: AppTheme.tablaColorHeader,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical : 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 13, child: Center(child: Text('Total:'))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(subtotal.toDouble())))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(iva.toDouble())))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(total.toDouble())))),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }
}

class ReporteFinalDescuentosYVendedores extends StatelessWidget {
  const ReporteFinalDescuentosYVendedores({
    super.key, required this.callback,
  });
  final Function callback;

  @override
  Widget build(BuildContext context) {
    final ventaSvc = Provider.of<VentasServices>(context, listen: false);
    final List<Ventas> ventasConDescuentos = [];    
    final Map<String, List<Ventas>> ventasPorUsuario = {};
    
    for (var venta in ventaSvc.ventasDeCorteActual) {
      //Descuento
      if (venta.descuento > Decimal.parse("0")){
        ventasConDescuentos.add(venta);
      }

      // Agrupar por usuario_id
      final usuarioId = venta.usuarioId; 
      ventasPorUsuario.putIfAbsent(usuarioId, () => []);
      ventasPorUsuario[usuarioId]!.add(venta);
    }

    final usuariosQueVendieron = ventasPorUsuario.keys.toList();
    
    return Expanded(
      flex: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Separador(texto: "Ventas con Descuentos"),
          Container(
            color: AppTheme.tablaColorHeader,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 6,  child: Center(child: Text('Folio'))),
                  Expanded(flex: 10, child: Center(child: Text('Vendedor'))),
                  Expanded(flex: 8,  child: Center(child: Text('Se Descuento'))),
                  Expanded(flex: 8,  child: Center(child: Text('Se Cobro'))),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 8, 
            child: Container(
              color: AppTheme.tablaColor1,
              child: ListView.builder(
                itemCount: ventasConDescuentos.length,
                itemBuilder: (context, index) {
                  return FilaDescuentos(venta: ventasConDescuentos[index], color: index+1);
                },
              ),
            )
          ),
          const SizedBox(height: 10),
          Separador(texto: "Ventas por Vendedor"),
          Container(
            color: AppTheme.tablaColorHeader,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 3, child: Center(child: Text('Vendedor'))),
                  Expanded(flex: 1, child: Center(child: Text('Ventas'))),
                  Expanded(flex: 2, child: Center(child: Text('Total'))),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              color: AppTheme.tablaColor1,
              child: ListView.builder(
                itemCount: usuariosQueVendieron.length,
                itemBuilder: (context, index) {
                  final usuarioId = usuariosQueVendieron[index];
                  final ventasDeEsteUsuario = ventasPorUsuario[usuarioId]!;

                  return FilaPorVendedor(
                    usuarioId: usuarioId,
                    ventas: ventasDeEsteUsuario, 
                    color: index+1);
                },
              ),
            )
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: (){
            callback();
          }, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Siguiente'),
            ],
          ))
        ],
      ),
    );
  }
}

class ReporteFinalMovimientos extends StatelessWidget {
  const ReporteFinalMovimientos({
    super.key, 
   /* required this.proximoFondo, */
    required this.contadoPesos, 
    required this.contadoDolares, 
    required this.contadoDebito, 
    required this.contadoCredito, 
    required this.contadoTransf,
  });

  //final Decimal proximoFondo;
  final Decimal contadoPesos;
  final Decimal contadoDolares;
  final Decimal contadoDebito;
  final Decimal contadoCredito;
  final Decimal contadoTransf;

  @override
  Widget build(BuildContext context) {
    //Calcular Movimientos
    final ventas = Provider.of<VentasServices>(context, listen: false);
    Cortes corte = CajasServices.corteActual!;
    //Decimal fondo = corte.fondoInicial;
    Decimal entrada = Decimal.parse("0");
    Decimal salida = Decimal.parse("0");

    for (var movimiento in corte.movimientoCaja) {
      if (movimiento.tipo=="entrada"){
        entrada += Decimal.parse(movimiento.monto.toString());
      } else if (movimiento.tipo=="retiro"){
        salida += Decimal.parse(movimiento.monto.toString());
      }
    } 

    Decimal abonadoMxn = Decimal.parse("0");
    Decimal abonadoUs = Decimal.parse("0");
    Decimal abonadoTarjD = Decimal.parse("0");
    Decimal abonadoTarjC = Decimal.parse("0");
    Decimal abonadoTrans = Decimal.parse("0");
    for (var venta in ventas.ventasDeCorteActual) {
      if (venta.abonadoMxn!=null){
        abonadoMxn += venta.abonadoMxn!;
      }
      if (venta.abonadoUs!=null){
        abonadoUs += venta.abonadoUs!;
      }
      if (venta.abonadoTarj!=null){
        if (venta.tipoTarjeta == "debito"){
          abonadoTarjD += venta.abonadoTarj!;
        } else if(venta.tipoTarjeta == "credito"){
          abonadoTarjC += venta.abonadoTarj!;
        }
      }
      if (venta.abonadoTrans!=null){
        abonadoTrans += venta.abonadoTrans!;
      }
    }
    Decimal abonadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(abonadoUs.toDouble()).toString());
    Decimal total = /*fondo - proximoFondo +*/ entrada - salida + abonadoMxn + abonadoUsCnv + abonadoTarjD + abonadoTarjC + abonadoTrans;

    //Contado
    Decimal contadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(contadoDolares.toDouble()).toString());
    Decimal totalContado = contadoPesos + contadoUsCnv + contadoDebito + contadoCredito + contadoTransf;

    //diferencia
    Decimal diferencia = total - totalContado;

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Separador(texto: 'Movimientos De Caja'),
          //Fila(texto: 'Fondo', precio: "+${Formatos.pesos.format(fondo.toDouble())}", color: 2),
          //Fila(texto: 'Proximo Fondo', precio: "-${Formatos.pesos.format(proximoFondo.toDouble())}", color: 1),
          Fila(texto: 'Entrada de dinero', precio: "+${Formatos.pesos.format(entrada.toDouble())}", color: 2),
          Fila(texto: 'Salida de dinero', precio: "-${Formatos.pesos.format(salida.toDouble())}", color: 1),
          Fila(texto: 'Efectivo (MX)', precio: "+${Formatos.pesos.format(abonadoMxn.toDouble())}", color: 2),
          Fila(texto: 'Efectivo (US)', precio: "+${Formatos.pesos.format(abonadoUsCnv.toDouble())}", dolar: Formatos.dolares.format(abonadoUs.toDouble()), color: 1),
          Fila(texto: 'Tarjeta de Debito', precio: "+${Formatos.pesos.format(abonadoTarjD.toDouble())}", color: 2),
          Fila(texto: 'Tarjeta de Credito', precio: "+${Formatos.pesos.format(abonadoTarjC.toDouble())}", color: 1),
          Fila(texto: 'Transferencia', precio: "+${Formatos.pesos.format(abonadoTrans.toDouble())}", color: 2),
          Fila(texto: 'Total', precio: Formatos.pesos.format(total.toDouble()), color: 0),
          const SizedBox(height: 15),
          Separador(texto: 'Dinero Entregado'),
          Fila(texto: 'Efectivo (MX)', precio: Formatos.pesos.format(contadoPesos.toDouble()), color: 1),
          Fila(texto: 'Efectivo (US)', precio: "+${Formatos.pesos.format(contadoUsCnv.toDouble())}", dolar: Formatos.pesos.format(contadoDolares.toDouble()), color: 2),
          Fila(texto: 'Tarjerta de Debito', precio: Formatos.pesos.format(contadoDebito.toDouble()), color: 1),
          Fila(texto: 'Tarjerta de Credito', precio: Formatos.pesos.format(contadoCredito.toDouble()), color: 2),
          Fila(texto: 'Transferencia', precio: Formatos.pesos.format(contadoTransf.toDouble()), color: 1),
          Fila(texto: 'Total', precio: Formatos.pesos.format(totalContado.toDouble()), color: 0),
          const SizedBox(height: 15),
          Separador(texto: 'Diferencia'),
          Fila(texto: 'Movimientos de Caja', precio: Formatos.pesos.format(total.toDouble()), color: 1),
          Fila(texto: 'Dinero Entregado', precio: Formatos.pesos.format(totalContado.toDouble()), color: 2),
          Fila(texto: 'Diferencia', precio: diferencia > Decimal.parse("0") ? "Faltante: ${Formatos.pesos.format(diferencia.toDouble())}" : "Sobrante: ${Formatos.pesos.format(diferencia.toDouble()).replaceAll("-", "")}", color: 0),
        ],
      )
    );
  }
}

class ReporteFinalDesgloseDinero extends StatelessWidget {
  const ReporteFinalDesgloseDinero({
    super.key, 
    required this.desglosePesos, 
    required this.desgloseDolares, 
    required this.impresoraControllers, 
    required this.callback,
  });

  final List<Desglose> desglosePesos;
  final List<Desglose> desgloseDolares;
  final Map<String, TextEditingController> impresoraControllers;
  final Function(String) callback;

  @override
  Widget build(BuildContext context) {
    final TextEditingController ctrl = TextEditingController();

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Separador(texto: 'Desglose Dinero Entregado', reducido: true),
          Row(
            children: [
              Expanded(child: Fila(texto: 'Pesos', precio: '', color: 0)),
              const SizedBox(width: 10),
              Expanded(child: Fila(texto: 'Dolares', precio: '', color: 0)),
            ],
          ),
          Expanded(
            flex: 9,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: AppTheme.tablaColor1,
                    child: ListView.builder(
                      itemCount: desglosePesos.length,
                      itemBuilder: (context, index) {
                        final d = desglosePesos[index];
                        return FilaDesglose(
                          denominacion: d.denominacion,
                          cantidad: d.cantidad,
                          color: index + 1
                        );
                      },
                    )
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    color: AppTheme.tablaColor1,
                    child: ListView.builder(
                      itemCount: desgloseDolares.length,
                      itemBuilder: (context, index) {
                        final d = desgloseDolares[index];
                        return FilaDesglose(
                          denominacion: d.denominacion,
                          cantidad: d.cantidad,
                          color: index + 1
                        );
                      },
                    )
                  )
                ),
              ],
            ),
          ), const SizedBox(height: 10),
          
          Separador(texto: 'Contadores'),
          Expanded(
            flex: 6,
            child: ReporteFinalContadores(impresoraControllers: impresoraControllers)
          ), const SizedBox(height: 10),

          Separador(texto: 'Comentarios'),
          TextFormField(
            controller: ctrl,
            maxLines: 2,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color.fromARGB(159, 255, 255, 255), width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white, width: 2)),
              contentPadding: EdgeInsets.all(8),
            ),
            
          ),

          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => callback(ctrl.text),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Finalizar'),
              ],
            )
          )
        ],
      )
    );
  }

}

class ReporteFinalContadores extends StatelessWidget {
  const ReporteFinalContadores({
    super.key, required this.impresoraControllers,
  });

  final Map<String, TextEditingController> impresoraControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.tablaColorHeader,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 10, child: Center(child: Text('Impresora', style: AppTheme.tituloClaro))),
                Expanded(flex: 12, child: Center(child: Text('Contadores sistema/anotado', style: AppTheme.tituloClaro))),
                Expanded(flex: 7,  child: Center(child: Text('  Diferencia', style: AppTheme.tituloClaro))),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<ImpresorasServices>(
            builder: (context, value, child) {
              return Container(
                color: AppTheme.tablaColor1,
                child: ListView.builder(
                  itemCount: value.impresoras.length,
                  itemBuilder: (context, index) {
                    int cantidad = int.tryParse(impresoraControllers[value.impresoras[index].id]?.text.replaceAll(",","")??'hubo un problema') ?? 0;
                    return FilaContadores(impresora: value.impresoras[index], cantidadAnotada: cantidad, color: index+1);
                  },
                ),
              );
            },
          ),
        ),
        //Text('Si la diferencia es negativa significa que hubo merma o no se registro alguna impresion en el sistema', style: AppTheme.tituloClaro, textScaler: TextScaler.linear(0.7)),
      ],
    );
  }
}

class FilaProductos extends StatelessWidget {
  const FilaProductos({
    super.key, 
    required this.cantidad, 
    required this.articulo, 
    required this.subtotal, 
    required this.iva, 
    required this.total,
    required this.color,   
  });

  final int cantidad;
  final String articulo;
  final Decimal subtotal;
  final Decimal iva;
  final Decimal total;
  final int color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 3, child: Center(child: Text(Formatos.numero.format(cantidad), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 10, child: Center(child: Text(articulo, textAlign: TextAlign.center, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(subtotal.toDouble()), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(iva.toDouble()), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(total.toDouble()), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}

class FilaDescuentos extends StatelessWidget {
  const FilaDescuentos({
    super.key, 
    required this.color, required this.venta,   
  });

  final Ventas venta;
  final int color;

  @override
  Widget build(BuildContext context) {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);

    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 6,  child: Center(child: Text(venta.folio!, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 10, child: Center(child: Text(usuarioSvc.obtenerNombreUsuarioPorId(venta.usuarioId), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(venta.descuento.toDouble()), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}

class FilaPorVendedor extends StatelessWidget {
  const FilaPorVendedor({
    super.key, 
    required this.usuarioId,
    required this.ventas,    
    required this.color, 
  });

  final String usuarioId;
  final List<Ventas> ventas;
  final int color;

  @override
  Widget build(BuildContext context) {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);

    Decimal total = Decimal.parse("0");
    for (var venta in ventas) {
      total += venta.total;
    }

    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 3, child: Center(child: Text(usuarioSvc.obtenerNombreUsuarioPorId(usuarioId), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 1, child: Center(child: Text(ventas.length.toString(), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 2,child: Center(child: Text(Formatos.pesos.format(total.toDouble()), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}

class Fila extends StatelessWidget {
  const Fila({
    super.key, required this.texto, required this.precio, required this.color, this.dolar
  });

  final String texto;
  final String precio;
  final String? dolar;
  final int color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:  8, vertical: 2),
        child: dolar==null ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(texto, style: color==0 ?  AppTheme.tituloClaro : AppTheme.subtituloConstraste),
            Text(precio, style: color==0 ?  AppTheme.tituloClaro : AppTheme.subtituloConstraste),
          ],
        ) : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(texto, style: color==0 ?  AppTheme.tituloClaro : AppTheme.subtituloConstraste),
            Row(
              children: [
                Text("(${dolar!})", style: TextStyle(color: AppTheme.colorContraste.withAlpha(220)), textScaler: TextScaler.linear(0.9)),
                Text(precio, style: color==0 ?  AppTheme.tituloClaro : AppTheme.subtituloConstraste),
              ],
            ),
            
          ],
        ),
      ),
    );
  }
}

class FilaDesglose extends StatelessWidget {
  const FilaDesglose({
    super.key, required this.denominacion, required this.cantidad, required this.color,
  });

  final double denominacion;
  final int cantidad;
  final int color;

  @override
  Widget build(BuildContext context) {
    double total = denominacion * cantidad;
    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:  8, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 2, child: Center(child: Text('${denominacion}x', style: AppTheme.subtituloConstraste))),
            Expanded(flex: 1, child: Center(child: Text(cantidad.toString(), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 3, child: Center(child: Text(Formatos.pesos.format(total), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}

class FilaContadores extends StatelessWidget {
  const FilaContadores({
    super.key, 
    required this.impresora,
    required this.cantidadAnotada,
    required this.color,
  });

  final Impresoras impresora;
  final int cantidadAnotada;
  final int color;

  @override
  Widget build(BuildContext context) {
    final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
    int cantidad = impresoraSvc.ultimosContadores[impresora.id]?.cantidad ?? 0;
    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 8, child: Center(child: Text(impresora.modelo, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidad), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidadAnotada), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidad-cantidadAnotada).replaceAll("-", ""), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}