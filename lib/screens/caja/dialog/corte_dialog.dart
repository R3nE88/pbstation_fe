import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/ticket.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:pbstation_frontend/widgets/separador.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StepStage { contadores, esperandoRetiro, conteoPesos, conteoDolares, terminado}

class CorteDialog extends StatefulWidget {
  const CorteDialog({super.key, required this.cierre, required this.caja, required this.corte, required this.ventas, this.readMode=false});

  final bool cierre;
  final Cajas caja;
  final Cortes corte;
  final List<Ventas> ventas;
  final bool readMode;

  @override
  State<CorteDialog> createState() => _CorteDialogState();
}

class _CorteDialogState extends State<CorteDialog> {
  StepStage stage = Configuracion.memoryCorte==null ? StepStage.contadores : StepStage.terminado;

  // Impresoras controllers (uno por impresora)
  final Map<String, TextEditingController> impresoraControllers = {};

  final List<VentasPorProducto> _ventasPorProducto = [];
  final List<Ventas> _ventasConDescuentos = [];
  final List<Ventas> _ventasConDeuda = [];
  final Map<String, List<Ventas>> _ventasPorUsuario = {};
  Decimal _subtotal = Decimal.zero;
  Decimal _iva = Decimal.zero;
  Decimal _total = Decimal.zero;
  Decimal _abonadoMxn = Decimal.zero;
  Decimal _abonadoUs = Decimal.zero;  
  Decimal _abonadoTarjD = Decimal.zero;
  Decimal _abonadoTarjC = Decimal.zero;
  Decimal _abonadoTrans = Decimal.zero;

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

  late DateTime fechaApertura;
  late String fechaAperturaFormatted;
  late DateTime fechaCorte;
  late String fechaCorteFormatted;

  int reporteFinalPage = 1;

  final TextEditingController ctrl = TextEditingController();

  //Cortes? memoryCorte = Configuracion.memoryCorte;
  bool contadoresFromMemory = false;

  late Cortes activeCorte;


  @override
  void initState() {
    super.initState();
    activeCorte = Configuracion.memoryCorte==null ? widget.corte : Configuracion.memoryCorte!;

    //ObtenerProductos
    _ventasPorProducto.addAll(Provider.of<VentasServices>(context, listen: false).consolidarVentasPorProducto(widget.ventas));

    //ReporteFinalDescuentosYVendedores
    for (var venta in widget.ventas) {
      //Descuento
      if (venta.descuento > Decimal.parse('0')){
        _ventasConDescuentos.add(venta);
      }
      // Agrupar por usuario_id
      final usuarioId = venta.usuarioId; 
      _ventasPorUsuario.putIfAbsent(usuarioId, () => []);
      _ventasPorUsuario[usuarioId]!.add(venta);
      //Deuda
      if(venta.wasDeuda && venta.liquidado){
        _ventasConDeuda.add(venta);
      }
    }

    //ReporteFinalVenta
    for (var venta in _ventasPorProducto) {
      _subtotal += venta.subTotal;
    }
    for (var venta in _ventasPorProducto) {
      _iva += venta.iva;
    }
    for (var venta in _ventasPorProducto) {
      _total += venta.total;
    }

    //ReporteFinalMovimientos
    for (var venta in widget.ventas) {
      if (venta.abonadoMxn!=null){
        _abonadoMxn += venta.abonadoMxn!;
      }
      if (venta.abonadoUs!=null){
        _abonadoUs += venta.abonadoUs!;
      }
      if (venta.abonadoTarj!=null){
        if (venta.tipoTarjeta == 'debito'){
          _abonadoTarjD += venta.abonadoTarj!;
        } else if(venta.tipoTarjeta == 'credito'){
          _abonadoTarjC += venta.abonadoTarj!;
        }
      }
      if (venta.abonadoTrans!=null){
        _abonadoTrans += venta.abonadoTrans!;
      }
    }

    // inicializa controladores de denominación (debe coincidir con denominaciones.length)
    if (widget.readMode==false){
      for (var _ in denominacionesMxn) {
        denomControllersMxn.add(TextEditingController());
      }
      for (var _ in denominacionesDlls) {
        denomControllersDlls.add(TextEditingController());
      }

      for (var i = 0; i < denominacionesDlls.length; i++) {
        denominacionesDolarFocus.add(FocusNode());
      }
    }

    //InicializarImpresoras
    final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
    setState(() => loadingImpresoras = true);
    impresoraSvc.loadImpresoras(true).whenComplete(() {
      _ensureImpresoraControllers(impresoraSvc);
      setState(() => loadingImpresoras = false);
    });    

    //Inicializar lo demas
    if (Configuracion.memoryCorte== null){
      initSinMemoryCorte();
    } else {
      initConMemoryCorte();
    }
  }

  void initSinMemoryCorte(){
    //fechas
    fechaApertura = DateTime.parse(activeCorte.fechaApertura);
    fechaAperturaFormatted = DateFormat('dd-MMM-yyyy hh:mm a', 'es_MX').format(fechaApertura);
    if (widget.readMode==false){ 
      fechaCorte = DateTime.now();
      activeCorte.usuarioIdCerro = Login.usuarioLogeado.id!;
    } 
    else { 
      fechaCorte = DateTime.parse(activeCorte.fechaCorte!); 
    }
    fechaCorteFormatted = DateFormat('dd-MMM-yyyy hh:mm a', 'es_MX').format(fechaCorte);
    activeCorte.fechaCorte = fechaCorte.toIso8601String();        

    //comentarios
    if (widget.readMode==true){
      ctrl.text = activeCorte.comentarios??'';
    }
  }

  void initConMemoryCorte(){
    //fechas
    fechaApertura = DateTime.parse(activeCorte.fechaApertura);
    fechaAperturaFormatted = DateFormat('dd-MMM-yyyy hh:mm a', 'es_MX').format(fechaApertura);
    fechaCorte = DateTime.parse(activeCorte.fechaCorte!); 
    fechaCorteFormatted = DateFormat('dd-MMM-yyyy hh:mm a', 'es_MX').format(fechaCorte);
    activeCorte.fechaCorte = fechaCorte.toIso8601String();        

    //comentarios
    ctrl.text = activeCorte.comentarios??'';

    //Contadores
    contadoresFromMemory = true;

    //ConteoPesos
    efectivoPesos = activeCorte.conteoPesos?.toDouble() ?? 0;
    efectivoDolares = activeCorte.conteoDolares?.toDouble() ?? 0;
    efectivoDolaresAPeso = CalculosDinero().dolarAPesos(efectivoDolares, CajasServices.cajaActual?.tipoCambio??1);
    
  }

  void buildContadoresFromMemory(){
    if (!contadoresFromMemory) return;
    for (MapEntry contador in activeCorte.contadoresFinales?.entries??[]) {
      impresoraControllers[contador.key]?.text = contador.value.toString();
    }
  }

  void _ensureImpresoraControllers(ImpresorasServices svc) {
    // solo crear si hacen falta (evita recrear en build)
    if (impresoraControllers.length != svc.impresoras.length) {
      impresoraControllers.clear();
      for (var impresora in svc.impresoras) {
        impresoraControllers[impresora.id!] = TextEditingController();
      }
    }
    if (contadoresFromMemory){ buildContadoresFromMemory(); }
  }

  @override
  void dispose() {
    
    for (var node in denominacionesDolarFocus) {
      if (node.hasFocus) {
        node.unfocus();
      }
    }
    
    // Esperar un frame antes de dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var c in impresoraControllers.values) {
        c.dispose();
      }
      for (var c in denomControllersMxn) {
        c.dispose();
      }
      for (var c in denomControllersDlls) {
        c.dispose();
      }

      for (var i = 0; i < denominacionesDolarFocus.length; i++) {
        denominacionesDolarFocus[i].dispose();
      }
    });

    super.dispose();
  }

  void guardarMemoryCorte() async{
    if (Configuracion.memoryCorte!=null) return;
    final prefs = await SharedPreferences.getInstance();
    String corteJson = _corte('').toJson();
    prefs.setString('memory_corte', corteJson);
  }

  Future<void> deleteMemoryCorte() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('memory_corte');
    Configuracion.memoryCorte = null;
  }

  Cortes _corte(String comentario){
    //Contado
    Decimal contadoUsCnv = Decimal.parse(CalculosDinero().dolarAPesos(efectivoDolares, CajasServices.cajaActual!.tipoCambio).toString());
    Decimal contadoPesos = Decimal.parse(efectivoPesos.toString());
    Decimal contadoDolares = Decimal.parse(efectivoDolares.toString());
    Decimal contadoDebito = contarVouchers(debitoControllers);
    Decimal contadoCredito = contarVouchers(creditoControllers);
    Decimal contadoTransf = contarVouchers(transferenciaControllers);
    Decimal totalContado = contadoPesos + contadoUsCnv + contadoDebito + contadoCredito + contadoTransf;

    //Venta
    Decimal abonadoMxn = Decimal.parse('0');
    Decimal abonadoUs = Decimal.parse('0');
    Decimal abonadoTarjD = Decimal.parse('0');
    Decimal abonadoTarjC = Decimal.parse('0');
    Decimal abonadoTrans = Decimal.parse('0');
    for (var venta in widget.ventas) {
      if (venta.abonadoMxn!=null){
        abonadoMxn += venta.abonadoMxn!;
      }
      if (venta.abonadoUs!=null){
        abonadoUs += venta.abonadoUs!;
      }
      if (venta.abonadoTarj!=null){
        if (venta.tipoTarjeta == 'debito'){
          abonadoTarjD += venta.abonadoTarj!;
        } else if(venta.tipoTarjeta == 'credito'){
          abonadoTarjC += venta.abonadoTarj!;
        }
      }
      if (venta.abonadoTrans!=null){
        abonadoTrans += venta.abonadoTrans!;
      }
    }
    //Decimal abonadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(abonadoUs.toDouble()).toString());
    Decimal ventaTotal = abonadoMxn + abonadoUs + abonadoTarjD + abonadoTarjC + abonadoTrans;

    //Diferencia
    Decimal diferencia = Decimal.parse('0');

    Cortes corte = Cortes(
      id: activeCorte.id,
      folio: activeCorte.folio,
      usuarioId: activeCorte.usuarioId, 
      usuarioIdCerro: activeCorte.usuarioIdCerro,
      sucursalId: activeCorte.sucursalId, 
      fechaApertura: activeCorte.fechaApertura,
      fechaCorte: activeCorte.fechaCorte,
      contadoresFinales: convertir(impresoraControllers),
      fondoInicial: activeCorte.fondoInicial, 
      conteoPesos: contadoPesos,
      conteoDolares: contadoDolares,
      conteoDebito: contadoDebito, 
      conteoCredito: contadoCredito, 
      conteoTransf: contadoTransf, 
      conteoTotal: totalContado,
      ventaPesos: abonadoMxn,
      ventaDolares: abonadoUs,
      ventaDebito: abonadoTarjD,
      ventaCredito: abonadoTarjC,
      ventaTransf: abonadoTrans,
      ventaTotal: ventaTotal,
      diferencia: (diferencia + ventaTotal) - totalContado,
      movimientosCaja: activeCorte.movimientosCaja,
      desglosePesos: mapearDesglose(true),
      desgloseDolares: mapearDesglose(false),
      ventasIds: activeCorte.ventasIds,
      comentarios: comentario,
      isCierre: widget.cierre
    );

    return corte;
  }

  void terminarCorte(String comentario) async{
    FocusScope.of(context).unfocus();
    Loading.displaySpinLoading(context);

    //Cerrar Corte
    Cortes corte = _corte(comentario);
    final cajasSvc = Provider.of<CajasServices>(context, listen: false);
    await cajasSvc.actualizarDatosCorte(corte, activeCorte.id!);
    CajasServices.corteActual=null;
    CajasServices.corteActualId=null;
    if (!mounted) return;
    Provider.of<VentasServices>(context, listen: false).ventasDeCorteActual.clear();

    //Cerrar Caja
    if (widget.cierre){
      Decimal ventaTotal = Decimal.zero;
      for (var corteCaja in cajasSvc.cortesDeCaja) {
        ventaTotal += corteCaja.ventaTotal ?? Decimal.zero;
      }

      Cajas caja = Cajas(
        id: widget.caja.id,
        folio: widget.caja.folio,
        usuarioId: widget.caja.usuarioId, 
        sucursalId: widget.caja.sucursalId, 
        fechaApertura: widget.caja.fechaApertura, 
        fechaCierre: corte.fechaCorte,
        ventaTotal: ventaTotal,
        estado: 'cerrada', 
        cortesIds: widget.caja.cortesIds, 
        tipoCambio: widget.caja.tipoCambio
      );
      await cajasSvc.cerrarCaja(caja);
      if (!mounted) return;
      final ventasSvc = Provider.of<VentasServices>(context, listen: false);
      ventasSvc.ventasDeCaja.clear();
      cajasSvc.cortesDeCaja.clear();
      //cajasSvc.movimientos.clear();
    }

    await deleteMemoryCorte();
  
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
    double t = 0.0;
    for (var i = 0; i < denomControllersDlls.length; i++) {
      final text = denomControllersDlls[i].text.trim();
      if (text.isEmpty) continue;
      final intCount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final value = denominacionesDlls[i]['value'] as double;
      t += intCount * value;
    }
    return t;
  }

  void _nextStage() async {
    switch (stage) {
      case StepStage.contadores:
        setState(() {
          performingRetiro = true;
          stage = StepStage.esperandoRetiro;
          }
        );
        break;
      case StepStage.esperandoRetiro:
        break;
      case StepStage.conteoPesos:
        setState(() => stage = StepStage.conteoDolares);
        denominacionesDolarFocus.first.requestFocus();
        break;
      case StepStage.conteoDolares:
        for (var node in denominacionesDolarFocus) {
          if (node.hasFocus) {
            node.unfocus();
          }
        }
        setState(() => stage = StepStage.terminado);
        guardarMemoryCorte();
        break;
      case StepStage.terminado:
        if(reporteFinalPage==2){
          setState(() {});
        }
        break;
    }
  }

  Widget _buildContadores(ImpresorasServices impresoraSvc) {
    if (loadingImpresoras) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 15, top: 10),
      child: SingleChildScrollView(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Regresar')),
                const SizedBox(width: 15),
                ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEsperandoRetiro(Cortes corte) {
    final impresoraSvc = Provider.of<ImpresorasServices>(context);

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 15, top: 10),
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text('¡Ahora retira el Fondo de  ', style: AppTheme.subtituloPrimario, textAlign: TextAlign.center),
                  Text(Formatos.pesos.format(corte.fondoInicial.toDouble()), style: AppTheme.tituloClaro.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const Text('para continuar con el conteo del corte!', style: AppTheme.subtituloPrimario, textAlign: TextAlign.center),
                ],
              ),
            ),
            if (performingRetiro) LinearProgressIndicator(color: AppTheme.containerColor1.withAlpha(150), minHeight: 10,),
            const SizedBox(height: 12),
      
            Row( 
              mainAxisAlignment: impresoraSvc.impresoras.isEmpty ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                impresoraSvc.impresoras.isEmpty ?
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  }, 
                  child: const Text('Regresar')
                ) : const SizedBox(),
      
                ElevatedButton(
                  autofocus: true,
                  onPressed: (){
                    setState(() {
                      performingRetiro = false;
                      stage = StepStage.conteoPesos;
                    });
                  }, 
                  child: const Text('Continuar')
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConteoStep() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 15, top: 10),
      child: SizedBox(
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
                      if(value.isEmpty){ ctrl.text = '0'; }
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
      ),
    );
  }

  Widget _buildConteoDolaresStep() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 15, top: 10),
      child: SizedBox(
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
                      if(value.isEmpty){ ctrl.text = '0'; }
                      setState(() {
                        efectivoDolares = calculateTotalDolares();
                        efectivoDolaresAPeso = CalculosDinero().dolarAPesos(efectivoDolares, CajasServices.cajaActual!.tipoCambio);
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
      ),
    );
  }

  Widget buildReporteFinal(
    int page, 
    List<VentasPorProducto> ventas, 
    List<Ventas> ventasConDescuentos,
    List<Ventas> ventasConDeuda,
    Map<String, List<Ventas>> ventasPorUsuario, 
    Decimal subtotal, 
    Decimal iva, 
    Decimal total,
    Decimal abonadoMxn,
    Decimal abonadoUs,
    Decimal abonadoTarjD,
    Decimal abonadoTarjC,
    Decimal abonadoTrans
    ){

    final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
    if (activeCorte.id==null) return const SizedBox();

    return SizedBox(
      width: 1048,
      height: 670,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
      
          //Header
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('#Corte: '),
                    SelectableText(activeCorte.folio ?? 'error', style: AppTheme.tituloClaro),
                  ],
                ),
                Row(
                  children: [
                    const Text('Tipo de cambio: '),
                    Text(Formatos.pesos.format(widget.caja.tipoCambio), style: AppTheme.tituloClaro), //TODO: no se si dejar el dolar de config o el de la caja
                  ],
                ),
              ],
            ),
          ),
          
          //Header2
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Abierta: '),
                    Text(fechaAperturaFormatted.toUpperCase(), style: AppTheme.tituloClaro),
                    const Text(' por '),
                    Text(usuariosSvc.obtenerNombreUsuarioPorId(activeCorte.usuarioId), style: AppTheme.tituloClaro),
                  ],
                ),
                Row(
                  children: [
                    const Text('Hora del corte: '),
                    Text(fechaCorteFormatted.toUpperCase(), style: AppTheme.tituloClaro),
                    const Text(' por '),
                    Text(usuariosSvc.obtenerNombreUsuarioPorId(activeCorte.usuarioIdCerro!), style: AppTheme.tituloClaro),
                  ],
                ),
              ],
            ),
          ), const SizedBox(height: 15),
    
          //Body 1
          page==1 ?Expanded(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left:24, bottom: 20, right: 24),
                  child: Row(
                    children: [
                      ReporteFinalVenta(ventasPorProducto: ventas, subtotal: subtotal, iva: iva, total: total,),
                      const SizedBox(width: 10),
                      ReporteFinalDescuentosYVendedores(
                        ventasConDescuentos: ventasConDescuentos,
                        ventasConDeuda: ventasConDeuda,
                        ventasPorUsuario: ventasPorUsuario,
                        callback: (){
                          reporteFinalPage=2;
                          _nextStage();
                        },
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () {
                    setState(() {
                      reporteFinalPage = 2;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.letraClara,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      )
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right, 
                      size: 30, 
                      color: AppTheme.containerColor1,
                    ),
                  )
                )
              ],
            )
          ) 
          : 
          //Body 2
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left:24, bottom: 10, right: 24),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Row(
                        children: [
                          ReporteFinalMovimientos(
                            contadoPesos: widget.readMode ? activeCorte.conteoPesos??Decimal.zero : Decimal.parse(efectivoPesos.toString()), 
                            contadoDolares: widget.readMode ? activeCorte.conteoDolares??Decimal.zero : Decimal.parse(efectivoDolares.toString()), 
                            contadoDebito: widget.readMode ? activeCorte.conteoDebito??Decimal.zero : contarVouchers(debitoControllers), 
                            contadoCredito: widget.readMode ? activeCorte.conteoCredito??Decimal.zero : contarVouchers(creditoControllers), 
                            contadoTransf: widget.readMode ? activeCorte.conteoTransf??Decimal.zero : contarVouchers(transferenciaControllers), 
                            abonadoMxn: abonadoMxn, 
                            abonadoUs: abonadoUs, 
                            abonadoTarjD: abonadoTarjD, 
                            abonadoTarjC: abonadoTarjC, 
                            abonadoTrans: abonadoTrans, 
                            corte: activeCorte,
                            readMode: widget.readMode,
                            tc: widget.readMode ? widget.caja.tipoCambio : CajasServices.cajaActual?.tipoCambio??Configuracion.dolar,
                          ),
                          const SizedBox(width: 10),
                          ReporteFinalDesgloseDinero(
                            desglosePesos: widget.readMode==false ? mapearDesglose(true) : activeCorte.desglosePesos!,
                            desgloseDolares: widget.readMode==false ? mapearDesglose(false) : activeCorte.desgloseDolares!,
                            impresoraControllers: impresoraControllers,
                            ctrl: ctrl,
                            readMode: widget.readMode,
                            corte: activeCorte,
                          ),
                        ],
                      ),
                      
                      //Botones finales
                      Row( 
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [                      
                          Tooltip(
                            message: 'Funcion En Desarrollo...',
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Descargar PDF'),
                                  Transform.translate(
                                    offset: const Offset(8, 1.5),
                                    child: const Icon(Icons.picture_as_pdf_outlined, size: 25)
                                  )
                                ],
                              )
                            ),
                          ), const SizedBox(width: 20),
                      
                          Tooltip(
                            message: 'Funcion En Desarrollo...',
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Enviar Por Correo'),
                                  Transform.translate(
                                    offset: const Offset(8, 1.5),
                                    child: const Icon(Icons.email_outlined, size: 25)
                                  )
                                ],
                              )
                            ),
                          ), const SizedBox(width: 20),
                      
                          ElevatedButton(
                            onPressed: () {
                              if (widget.readMode){
                                Ticket.imprimirTicketCorte(context, widget.caja, activeCorte, widget.ventas, {});
                              } else {
                                Ticket.imprimirTicketCorte(context, CajasServices.cajaActual!, _corte(ctrl.text), Provider.of<VentasServices>(context, listen:false).ventasDeCorteActual, impresoraControllers);
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Imprimir Ticket'),
                                Transform.translate(
                                  offset: const Offset(8, 1.5),
                                  child: const Icon(Icons.print_outlined, size: 25)
                                )
                              ],
                            )
                          ), const SizedBox(width: 20),
                      
                          !widget.readMode ?
                          ElevatedButton(
                            onPressed: () => terminarCorte(ctrl.text),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.cierre ? 'Finalizar Dia' : 'Finalizar'),
                                Transform.translate(
                                  offset: const Offset(8, 1.5),
                                  child: const Icon(Icons.done, size: 25)
                                )
                              ],
                            ), 
                          ):
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(-8, 1.5),
                                  child: const Icon(Icons.close, size: 25)
                                ),
                                const Text('Salir'),
                              ],
                            ), 
                          ),
                        ],
                      ) 
                    ],
                  ),
                ),
              
                InkWell(
                  onTap: () {
                    setState(() {
                      reporteFinalPage = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.letraClara,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      )
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_left, 
                      size: 30, 
                      color: AppTheme.containerColor1,
                    ),
                  )
                )
              ],
            )
          ),
        ],
      )
    );
  }

  List<Desglose> mapearDesglose(bool pesos) {
    if(Configuracion.memoryCorte!=null){
      if (pesos){
        return activeCorte.desglosePesos??[];
      } else {
        return activeCorte.desgloseDolares??[];
      }
    }

    List<Desglose> lista = [];
    if (pesos) {
      for (var i = 0; i < denominacionesMxn.length; i++) {
        if (denomControllersMxn[i].text.isNotEmpty) {
          double denominacion = denominacionesMxn[i]['value'] as double;
          int cantidad = int.parse(denomControllersMxn[i].text.replaceAll(',', ''));
          lista.add(Desglose(denominacion: denominacion, cantidad: cantidad));
        }
      }
    } else {
      for (var i = 0; i < denominacionesDlls.length; i++) {
        if (denomControllersDlls[i].text.isNotEmpty) {
          double denominacion = denominacionesDlls[i]['value'] as double;
          int cantidad = int.parse(denomControllersDlls[i].text.replaceAll(',', ''));
          lista.add(Desglose(denominacion: denominacion, cantidad: cantidad));
        }
      }
    }
    lista.removeWhere((element) => element.cantidad == 0);
    return lista;
  }

  Decimal contarVouchers(List<TextEditingController> lista){
    Decimal total = Decimal.parse('0');
    for (var item in lista) {
      total += item.text.isNotEmpty ? Decimal.parse(item.text.replaceAll('MX\$', '').replaceAll(',', '')) : Decimal.parse('0');
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

    //Si no tengo impresoras y estoy en la primera ventana, ignorarla
    if (!loadingImpresoras){
      if (impresoraSvc.impresoras.isEmpty && stage == StepStage.contadores){
        stage = StepStage.esperandoRetiro;
        performingRetiro = true;
      }
    }
     
    if(widget.readMode){
      stage = StepStage.terminado;
    }


    Widget content;
    String title = 'Corte de Caja';

    switch (stage) {
      case StepStage.contadores:
        title = 'Registrar Contadores';
        content = _buildContadores(impresoraSvc);
        break;
      case StepStage.esperandoRetiro:
        title = '';
        content = _buildEsperandoRetiro(activeCorte);
        break;
      case StepStage.conteoPesos:
        title = 'Conteo de Efectivo (MXN)';
        content = _buildConteoStep();
        break;
      case StepStage.conteoDolares:
        title = 'Conteo de Efectivo (DLLS)';
        content = _buildConteoDolaresStep();
        break;
      case StepStage.terminado:
        title = '';
        content = buildReporteFinal(
          reporteFinalPage,
          _ventasPorProducto,
          _ventasConDescuentos,
          _ventasConDeuda,
          _ventasPorUsuario,
          _subtotal,
          _iva,
          _total,
          _abonadoMxn,
          _abonadoUs,
          _abonadoTarjD,
          _abonadoTarjC,
          _abonadoTrans
          );
        break;
    }

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      contentPadding: const EdgeInsets.all(0),
      title: title.isNotEmpty ? 
      Text(title) 
      : null,
      content: content,
    );
  }
}

class ReporteFinalVenta extends StatelessWidget {
  const ReporteFinalVenta({
    super.key, 
    required this.ventasPorProducto, 
    required this.subtotal, 
    required this.iva, 
    required this.total,
  });

  final List<VentasPorProducto> ventasPorProducto;
  final Decimal subtotal;
  final Decimal iva;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final productos = Provider.of<ProductosServices>(context, listen: false);
    
    return Expanded(
      flex: 10,
      child: Stack(
        alignment: AlignmentGeometry.bottomCenter,
        children: [
          Column(
            children: [
              const Separador(
                texto: 'Ventas por Articulos',
              ),
              Container(
                color: AppTheme.tablaColorHeader,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical : 2),
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
                    itemCount: ventasPorProducto.length,
                    itemBuilder: (context, index) {
                      Productos? producto = productos.obtenerProductoPorId(ventasPorProducto[index].productoId);
                      
                      return FilaProductos(
                        cantidad: ventasPorProducto[index].cantidad, 
                        articulo: producto!=null ? '${producto.descripcion}s' : 'no se encontro', 
                        iva: Decimal.parse(ventasPorProducto[index].iva.toString()), 
                        subtotal: Decimal.parse(ventasPorProducto[index].subTotal.toString()), 
                        total: Decimal.parse(ventasPorProducto[index].total.toString()), 
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
                      const Expanded(flex: 13, child: Center(child: Text('Total:'))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(subtotal.toDouble())))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(iva.toDouble())))),
                      Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(total.toDouble())))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, 15),
            child: const Text('El total puede ser mayor al monto realmente cobrado, ya que no incluye deudas pendientes.', textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.8))
          ),
        ],
      )
    );
  }
}

class ReporteFinalDescuentosYVendedores extends StatelessWidget {
  const ReporteFinalDescuentosYVendedores({
    super.key, 
    required this.ventasConDescuentos,
    required this.ventasConDeuda,
    required this.ventasPorUsuario,
    required this.callback,
  });
  final List<Ventas> ventasConDescuentos;
  final List<Ventas> ventasConDeuda;
  final Map<String, List<Ventas>> ventasPorUsuario;
  final Function callback;

  @override
  Widget build(BuildContext context) {    
    final usuariosQueVendieron = ventasPorUsuario.keys.toList();

    return Expanded(
      flex: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Separador(texto: 'Deudas pagadas'),
          Container(
            color: AppTheme.tablaColorHeader,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 6,  child: Center(child: Text('Folio'))),
                  Expanded(flex: 12, child: Center(child: Text('Detalles'))),
                  Expanded(flex: 8,  child: Center(child: Text('Total'))),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5, 
            child: Container(
              color: AppTheme.tablaColor1,
              child: ListView.builder(
                itemCount: ventasConDeuda.length,
                itemBuilder: (context, index) {
                  return FilaDeudas(venta: ventasConDeuda[index], color: index+1);
                },
              ),
            )
          ),
          const SizedBox(height: 10),
          const Separador(texto: 'Ventas con Descuentos'),
          Container(
            color: AppTheme.tablaColorHeader,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical : 2),
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
            flex: 6, 
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
          const Separador(texto: 'Ventas por Vendedor'),
          Container(
            color: AppTheme.tablaColorHeader,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 3, child: Center(child: Text('Vendedor'))),
                  Expanded(child: Center(child: Text('Ventas'))),
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
          //const SizedBox(height: 10),
          /*ElevatedButton(onPressed: (){
            callback();
          }, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Siguiente'),
              Transform.translate(
                offset: const Offset(8, 1.5),
                child: const Icon(Icons.chevron_right_sharp, size: 25)
              )
            ],
          ))*/
        ],
      ),
    );
  }
}

class ReporteFinalMovimientos extends StatelessWidget {
  const ReporteFinalMovimientos({
    super.key, 
    required this.contadoPesos, 
    required this.contadoDolares, 
    required this.contadoDebito, 
    required this.contadoCredito, 
    required this.contadoTransf, 
    required this.abonadoMxn, 
    required this.abonadoUs, 
    required this.abonadoTarjD, 
    required this.abonadoTarjC, 
    required this.abonadoTrans,
    required this.corte,
    required this.readMode,
    required this.tc,
  });

  final Decimal contadoPesos;
  final Decimal contadoDolares;
  final Decimal contadoDebito;
  final Decimal contadoCredito;
  final Decimal contadoTransf;
  final Decimal abonadoMxn;
  final Decimal abonadoUs;
  final Decimal abonadoTarjD;
  final Decimal abonadoTarjC;
  final Decimal abonadoTrans;
  final Cortes corte;
  final double tc;
  final bool readMode;

  @override
  Widget build(BuildContext context) {
    //Calcular Movimientos
    Decimal entrada = Decimal.parse('0');
    Decimal salida = Decimal.parse('0');

    for (var movimiento in corte.movimientosCaja) {
      if (movimiento.tipo=='entrada'){
        entrada += Decimal.parse(movimiento.monto.toString());
      } else if (movimiento.tipo=='retiro'){
        salida += Decimal.parse(movimiento.monto.toString());
      }
    } 

    //sistema
    //Decimal abonadoUsCnv = Decimal.parse(CalculosDinero().conversionADolar(abonadoUs.toDouble()).toString());
    final double abonadoMxToUsd = CalculosDinero().pesosADolar(abonadoUs.toDouble(), tc);
    final Decimal totalEfectivo = entrada - salida + abonadoMxn + abonadoUs;
    final Decimal totalTarjetas = abonadoTarjD + abonadoTarjC + abonadoTrans;
    final Decimal total = totalEfectivo + totalTarjetas;

    //Contado
    late final Decimal contadoUsCnv;
    late final Decimal totalContado;
    if(!readMode){
      contadoUsCnv = Decimal.parse(CalculosDinero().dolarAPesos(contadoDolares.toDouble(), tc).toString());
      totalContado = contadoPesos + contadoUsCnv + contadoDebito + contadoCredito + contadoTransf;
    } else {
      contadoUsCnv =  Decimal.parse(CalculosDinero().dolarAPesos(corte.conteoDolares?.toDouble()??0, tc).toString());
      totalContado = corte.conteoTotal??Decimal.zero;
    }

    //diferencia
    Decimal diferencia = totalEfectivo - totalContado;

    double mx = abonadoMxn.toDouble();

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          const Separador(texto: 'Saldo de Caja'),
          Fila(texto: 'Entrada de dinero (Movimientos)', precio: '+${Formatos.pesos.format(entrada.toDouble())}', color: 2),
          Fila(texto: 'Salida de dinero (Movimientos)', precio: '-${Formatos.pesos.format(salida.toDouble())}', color: 1),
          Fila(texto: 'Efectivo (MX)', precio: mx < 0 ? Formatos.pesos.format(mx) : '+${Formatos.pesos.format(mx)}', color: 2),
          Fila(texto: 'Efectivo (US)', precio: ' ${Formatos.pesos.format(abonadoUs.toDouble())}', dolar: Formatos.dolares.format(abonadoMxToUsd), color: 1),
          //Fila(texto: 'Tarjeta de Debito', precio: '+${Formatos.pesos.format(abonadoTarjD.toDouble())}', color: 2),
          //Fila(texto: 'Tarjeta de Credito', precio: '+${Formatos.pesos.format(abonadoTarjC.toDouble())}', color: 1),
          //Fila(texto: 'Transferencia', precio: '+${Formatos.pesos.format(abonadoTrans.toDouble())}', color: 2),
          Fila(texto: 'Total', precio: Formatos.pesos.format(totalEfectivo.toDouble()), color: 0),
          const SizedBox(height: 9),

          const Separador(texto: 'Saldo de tarjetas y transferencias'),
          Fila(texto: 'Tarjeta de Debito', precio: '+${Formatos.pesos.format(abonadoTarjD.toDouble())}', color: 2),
          Fila(texto: 'Tarjeta de Credito', precio: '+${Formatos.pesos.format(abonadoTarjC.toDouble())}', color: 1),
          Fila(texto: 'Transferencia', precio: '+${Formatos.pesos.format(abonadoTrans.toDouble())}', color: 2),
          const SizedBox(height: 9),

          const Separador(texto: 'Total venta'),
          Fila(texto: 'Saldo de Caja', precio: '+${Formatos.pesos.format(totalEfectivo.toDouble())}', color: 2),
          Fila(texto: 'Saldo de tarjetas y transferencias', precio: '+${Formatos.pesos.format(totalTarjetas.toDouble())}', color: 1),
          Fila(texto: 'Total', precio: Formatos.pesos.format(total.toDouble()), color: 0),
          const SizedBox(height: 9),

          const Separador(texto: 'Dinero Entregado'),
          Fila(texto: 'Efectivo (MX)', precio: Formatos.pesos.format(contadoPesos.toDouble()), color: 1),
          Fila(texto: 'Efectivo (US)', precio: ' ${Formatos.pesos.format(contadoUsCnv.toDouble())}', dolar: Formatos.dolares.format(contadoDolares.toDouble()), color: 2),
          // Fila(texto: 'Tarjerta de Debito', precio: Formatos.pesos.format(contadoDebito.toDouble()), color: 1),
          // Fila(texto: 'Tarjerta de Credito', precio: Formatos.pesos.format(contadoCredito.toDouble()), color: 2),
          // Fila(texto: 'Transferencia', precio: Formatos.pesos.format(contadoTransf.toDouble()), color: 1),
          Fila(texto: 'Total', precio: Formatos.pesos.format(totalContado.toDouble()), color: 0),
          const SizedBox(height: 9),

          const Separador(texto: 'Diferencia'),
          //Fila(texto: 'Saldo de Caja Esperado', precio: Formatos.pesos.format(total.toDouble()), color: 1),
          //Fila(texto: 'Dinero Entregado', precio: Formatos.pesos.format(totalContado.toDouble()), color: 2),
          Container(
            color: AppTheme.tablaColorHeader,
            padding: const EdgeInsets.symmetric(horizontal:  4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Efectivo de caja ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.85)),
                    Text(Formatos.pesos.format(totalEfectivo.toDouble()), textScaler: const TextScaler.linear(1)),
                  ],
                ),
                //const Text('-'),
                Row(
                  children: [
                    const Text('Dinero Entregado ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.85)),
                    Text(Formatos.pesos.format(totalContado.toDouble()), textScaler: const TextScaler.linear(1)),
                  ],
                ),
              ],
            ),
          ),
          Fila(texto: '', precio: diferencia > Decimal.parse('0') ? 'Faltante: ${Formatos.pesos.format(diferencia.toDouble())}' : "Sobrante: ${Formatos.pesos.format(diferencia.toDouble()).replaceAll("-", "")}", color: 2),


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
    required this.ctrl,
    required this.readMode,
    required this.corte,
  });

  final List<Desglose> desglosePesos;
  final List<Desglose> desgloseDolares;
  final Map<String, TextEditingController> impresoraControllers;
  final TextEditingController ctrl;
  final bool readMode;
  final Cortes corte;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Separador(texto: 'Desglose Dinero Entregado', reducido: true),
          const Row(
            children: [
              Expanded(child: Fila(texto: 'Pesos', precio: '', color: 0)),
              SizedBox(width: 10),
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
                          color: index + 1,
                          dolar: false
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
                          color: index + 1,
                          dolar: true
                        );
                      },
                    )
                  )
                ),
              ],
            ),
          ), const SizedBox(height: 10),
          
          const Separador(texto: 'Contadores'),
          Expanded(
            flex: 6,
            child: ReporteFinalContadores(impresoraControllers: impresoraControllers, readMode: readMode, corte: corte)
          ), const SizedBox(height: 10),

          const Separador(texto: 'Comentarios'),
          TextFormField(
            controller: ctrl,
            readOnly: readMode,
            maxLines: 2,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromARGB(159, 255, 255, 255), width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white, width: 2)),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),

          const SizedBox(height: 48),
        ],
      )
    );
  }

}

class ReporteFinalContadores extends StatelessWidget {
  const ReporteFinalContadores({
    super.key, 
    required this.impresoraControllers,
    required this.readMode, 
    required this.corte,
  });

  final Map<String, TextEditingController> impresoraControllers;
  final bool readMode;
  final Cortes corte;

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
                const Expanded(flex: 8, child: Center(child: Text('Impresora', style: AppTheme.tituloClaro))),
                Expanded(flex: 5, child: Center(child: Text(!readMode ? 'Calculado' : 'Contador', style: AppTheme.tituloClaro))),
                !readMode ? const Expanded(flex: 5, child: Center(child: Text('Real', style: AppTheme.tituloClaro))) : const SizedBox(),
                !readMode ? const Expanded(flex: 5, child: Center(child: Text('Diferencia', style: AppTheme.tituloClaro))) : const SizedBox(),
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
                    int cantidad = 0;
                    if (readMode){
                      cantidad = corte.contadoresFinales?[value.impresoras[index].id] ?? 0;
                    } else {
                      cantidad = int.tryParse(impresoraControllers[value.impresoras[index].id]?.text.replaceAll(',','')??'hubo un problema') ?? 0;
                    }
                    
                    return FilaContadores(impresora: value.impresoras[index], cantidadAnotada: cantidad, color: index+1, readMode: readMode);
                  },
                ),
              );
            },
          ),
        ),
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
            Expanded(flex: 8, child: Center(child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: AppTheme.subtituloConstraste))),
          ],
        ),
      ),
    );
  }
}

class FilaDeudas extends StatelessWidget {
  const FilaDeudas({
    super.key, 
    required this.color, required this.venta,   
  });

  final Ventas venta;
  final int color;

  @override
  Widget build(BuildContext context) {
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    final detalles = productosSvc.obtenerDetallesComoTexto(venta.detalles);

    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 6,  child: Center(child: Text(venta.folio!, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 12, child: Center(child: Text(detalles, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTheme.subtituloConstraste))),
            Expanded(flex: 8,  child: Center(child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: AppTheme.subtituloConstraste))),
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

    Decimal total = Decimal.parse('0');
    for (var venta in ventas) {
      total += venta.abonadoTotal;
    }

    return Container(
      color: color==0 ? AppTheme.tablaColorHeader : color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 3, child: Center(child: Text(usuarioSvc.obtenerNombreUsuarioPorId(usuarioId), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTheme.subtituloConstraste))),
            Expanded(child: Center(child: Text(ventas.length.toString(), style: AppTheme.subtituloConstraste))),
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
                Text('+(${dolar!})', style: TextStyle(color: AppTheme.colorContraste.withAlpha(220)), textScaler: const TextScaler.linear(0.9)),
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
    super.key, required this.denominacion, required this.cantidad, required this.color, required this.dolar,
  });

  final double denominacion;
  final int cantidad;
  final int color;
  final bool dolar;
  
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
            Expanded(child: Center(child: Text(cantidad.toString(), style: AppTheme.subtituloConstraste))),
            Expanded(flex: 3, child: Center(child: Text(dolar?Formatos.dolares.format(total):Formatos.pesos.format(total), style: AppTheme.subtituloConstraste))),
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
    required this.readMode,
  });

  final Impresoras impresora;
  final int cantidadAnotada;
  final int color;
  final bool readMode;

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
            !readMode ? Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidad), style: AppTheme.subtituloConstraste))) : const SizedBox(),
            Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidadAnotada), style: AppTheme.subtituloConstraste))),
            !readMode ? Expanded(flex: 5, child: Center(child: Text(Formatos.numero.format(cantidad-cantidadAnotada).replaceAll('-', ''), style: AppTheme.subtituloConstraste))) : const SizedBox(),
          ],
        ),
      ),
    );
  }
}