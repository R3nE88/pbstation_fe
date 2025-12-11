import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mensaje_flotante.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/screens/caja/abrir_caja.dart';
import 'package:pbstation_frontend/screens/caja/dialog/corte_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/movimiento_caja_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/venta_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key, this.readMode=false, this.caja});

  final bool readMode;
  final Cajas? caja;

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  List<Ventas> _ventasParaMostrar = [];
  bool _initLoad = false;
  late Cortes _corteSelected;
  List<Cortes>? _cortesHistorial;
  late Cajas _cajaSelected;

  @override
  void initState() {
    super.initState();
    if(widget.readMode==false){
      if (CajasServices.cajaActualId != null && CajasServices.cajaActualId != 'buscando' && CajasServices.corteActualId != null) {
        datosIniciales();
      }
    } else { datosInicialesReadMode(); }
  }

  void datosIniciales(){
    final ventasSvc =  Provider.of<VentasServices>(context, listen: false);
    ventasSvc.loadVentasDeCaja().whenComplete(
      () {
        if (!mounted) return;
        _ventasParaMostrar = List.from(ventasSvc.ventasDeCaja);
        setState(() {});
      } 
    );
    ventasSvc.loadVentasDeCorteActual();
    Provider.of<CajasServices>(context, listen: false).loadCortesDeCaja();
    Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
  }

  void datosInicialesReadMode(){
    Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
    Provider.of<CajasServices>(context, listen: false).loadDatosCompletosDeCaja(widget.caja!.id!); 
    final ventasSvc = Provider.of<VentasServices>(context, listen: false);
    ventasSvc.loaded = false;
    ventasSvc.loadVentasDeCajaHistorial(widget.caja!.id!).whenComplete(
      () {
        if (!mounted) return;
        _ventasParaMostrar = List.from(ventasSvc.ventasDeCajaHistorial);
        setState(() {});
      } 
    );
  }

  Decimal sumarTotal(List<Ventas> ventas) => 
    ventas.fold(Decimal.zero, (sum, venta) => sum + venta.abonadoTotal);

  void filtrarVentasPor(Map<String, String>? opcion) async {
    if (opcion == null) return;
    
    final ventaSvc = Provider.of<VentasServices>(context, listen: false);
    final ventasSource = widget.readMode 
        ? ventaSvc.ventasDeCajaHistorial 
        : ventaSvc.ventasDeCaja;

    List<Ventas> ventasFiltradas = [];

    switch (opcion.keys.first) {
      case 'corte':
        final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
        loadingSvc.show();
        final cajasSvc = Provider.of<CajasServices>(context, listen: false);
        final cortesLista = widget.readMode ? _cortesHistorial! : cajasSvc.cortesDeCaja;
        final ventasIds = cortesLista
            .firstWhere((element) => element.id == opcion.values.first)
            .ventasIds;
        
        if (widget.readMode) {
          ventasFiltradas = ventasSource
              .where((venta) => ventasIds.contains(venta.id))
              .toList();
        } else {
          ventasFiltradas = await ventaSvc.loadVentasDeCortes(ventasIds);
        }
        
        setState(() {
            _ventasParaMostrar = ventasFiltradas;
            _corteSelected = cortesLista.firstWhere((element) => element.id == opcion.values.first);
          });
          loadingSvc.hide();
        break;

      case 'users':
        ventasFiltradas = ventasSource
            .where((venta) => venta.usuarioId == opcion.values.first)
            .toList();
        setState(() => _ventasParaMostrar = ventasFiltradas);
        break;

      case 'todos':
        setState(() => _ventasParaMostrar = ventasSource);
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.readMode==true && widget.caja==null){
      return Center(child: Text('Hubo un problema al cargar esto. caja_screen.dart :92', style: AppTheme.subtituloConstraste));
    }

    return Consumer3<UsuariosServices, VentasServices, CajasServices>(
      builder: (context, usuariosSvc, ventasSvc, cajasSvc, child) {        
        if(widget.caja==null){
          if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActualId==null)){
            return AbrirCaja(metodo: datosIniciales);
          }
          if (usuariosSvc.isLoading || ventasSvc.isLoading || cajasSvc.cortesDeCajaIsLoading || cajasSvc.isLoading){
            return const SimpleLoading();
          } else if (_initLoad == false){
            _corteSelected = CajasServices.corteActual!;
            _cajaSelected = CajasServices.cajaActual!;
            _initLoad = true;
          }
        } else {
          if (usuariosSvc.isLoading || cajasSvc.isLoadingHistorial || ventasSvc.isLoadingHistorial){
            return const LoadingWidget();
          } else if (_initLoad == false){
            _cortesHistorial = CajasServices.cortesHistorial!;
            _corteSelected = CajasServices.cortesHistorial!.first;
            _cajaSelected = CajasServices.cajaHistorial!;
            _initLoad = true;
          }
        }
        
        return BodyPadding(
          child: Column(
            children: [
              //Header
              _Header(
                onFiltroCambio: (value) => filtrarVentasPor(value),
                caja: _cajaSelected,
                corte: _corteSelected,
                ventas: _ventasParaMostrar,
                readMode: widget.readMode,
                cortesHistorial: _cortesHistorial,
              ), 
              //Body
              Expanded(
                child: Column(
                  children: [
                    const _TablaHeader(),
                    Expanded(
                      child: Container(
                        color: _ventasParaMostrar.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                        child: ListView.builder(
                          itemCount: _ventasParaMostrar.length,
                          itemBuilder: (context, index) {
                            return _FilaVentas(
                              index: index, 
                              venta: _ventasParaMostrar[index], 
                              tc: widget.readMode ? widget.caja!.tipoCambio : CajasServices.cajaActual!.tipoCambio, 
                              readMode: widget.readMode, 
                              callback: datosIniciales,
                            );
                          },
                        ),
                      ),
                    ),
                    _TablaFooter(total: _ventasParaMostrar.length, venta: sumarTotal(_ventasParaMostrar).toDouble(),)
                  ],
                )
              ),
            ],
          )
        );
      }
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({required this.onFiltroCambio, required this.corte, required this.caja, required this.ventas, this.readMode = false, required this.cortesHistorial});
  final ValueChanged<Map<String, String>?> onFiltroCambio;
  final Cortes corte;
  final Cajas caja;
  final List<Ventas> ventas;
  final bool readMode;
  final List<Cortes>? cortesHistorial;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  String estado = 'todos'; //'corte' 'users'

  void filtrarVentasPor(Map<String, String>? opcion) async {
    widget.onFiltroCambio(opcion);
    
    if (opcion == null) return;
    switch (opcion.keys.first) {
      case 'todos':
        setState(() { estado = 'todos'; });
        break;
      case 'corte':
        setState(() { estado = 'corte'; });
        break;
      case 'users':
        setState(() { estado = 'users'; });
        break;
    }
  }
  
  Widget headerTodos() {
    final DateTime fechaCaja = DateTime.parse(widget.caja.fechaApertura);
    final String mes = DateFormat('d - MMMM - yyyy', 'es_MX').format(fechaCaja).toUpperCase();
    final String horaAper = DateFormat('hh:mm a').format(fechaCaja);

    final DateTime? fechaCie;
    if (widget.caja.fechaCierre!=null){
      fechaCie = DateTime.parse(widget.caja.fechaCierre!);
    } else { fechaCie=null; }
    final String? horaCie = fechaCie!= null ? DateFormat('hh:mm a').format(fechaCie) : null;

    final String usuarioAbrio = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.caja.usuarioId);
    final String? usuarioCerro;  
    if (widget.caja.estado == 'cerrada'){
      Cortes? corteReciente;
      if (widget.cortesHistorial != null && widget.cortesHistorial!.isNotEmpty) {
        final cortesConFecha = widget.cortesHistorial!.where((c) => c.fechaCorte != null).toList();
        if (cortesConFecha.isNotEmpty) {
          corteReciente = cortesConFecha.reduce((a, b) {
            final fechaA = DateTime.parse(a.fechaCorte!);
            final fechaB = DateTime.parse(b.fechaCorte!);
            return fechaA.isAfter(fechaB) ? a : b;
          });
        }
      }
      usuarioCerro = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(corteReciente!.usuarioIdCerro!);
    } else { usuarioCerro = null; }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.tablaColorHeader,
            border: const Border(bottom: BorderSide(color: Colors.black12, width: 3)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            )
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CAJA: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                        SelectableText(widget.caja.folio!, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.6)),
                      ],
                    ),
                    const SizedBox(width: 15), // Separación mínima entre grupos
                    Text(mes, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.8)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          textScaler: const TextScaler.linear(0.8),
                          text: TextSpan(
                            style: AppTheme.labelStyle,
                            children: [
                              const TextSpan(text: 'Abierto por '),
                              TextSpan(
                                text: usuarioAbrio,
                                style: AppTheme.tituloClaro,
                              ),
                              const TextSpan(text: ' a las '),
                              TextSpan(
                                text: horaAper,
                                style: AppTheme.tituloClaro,
                              ),
                            ],
                          ),
                        ),
                        usuarioCerro != null
                        ? RichText(
                            textAlign: TextAlign.center,
                            textScaler: const TextScaler.linear(0.8),
                            text: TextSpan(
                              style: AppTheme.labelStyle,
                              children: [
                                const TextSpan(text: 'Cerrado por '),
                                TextSpan(
                                  text: usuarioCerro,
                                  style: AppTheme.tituloClaro,
                                ),
                                const TextSpan(text: ' a las '),
                                TextSpan(
                                  text: horaCie,
                                  style: AppTheme.tituloClaro,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget headerCorte() {
    final DateTime fechaCaja = DateTime.parse(widget.caja.fechaApertura);
    final String mes = DateFormat('d - MMMM - yyyy', 'es_MX').format(fechaCaja).toUpperCase();
    final DateTime fechaAper = DateTime.parse(widget.corte.fechaApertura); 
    final String horaAper = DateFormat('hh:mm a').format(fechaAper);
    final DateTime? fechaCie;
    if (widget.corte.fechaCorte!=null){
      fechaCie = DateTime.parse(widget.corte.fechaCorte!);
    } else { fechaCie=null; }
    final String? horaCie = fechaCie!= null ? DateFormat('hh:mm a').format(fechaCie) : null;

    final String usuarioAbrio = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.corte.usuarioId);
    final String? usuarioCerro;  
    if (widget.corte.usuarioIdCerro!=null){
      usuarioCerro = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.corte.usuarioIdCerro!);
    } else { usuarioCerro = null; }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.tablaColorHeader,
            border: const Border(bottom: BorderSide(color: Colors.black12, width: 3)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            )
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(mes, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.8)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CAJA: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                        SelectableText(widget.caja.folio!, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.6)),
                      ],
                    ),
                    const SizedBox(width: 15), // Separación mínima entre grupos
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TURNO: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.1)),
                        SelectableText(widget.corte.folio!, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.4))
                      ],
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          textScaler: const TextScaler.linear(0.8),
                          text: TextSpan(
                            style: AppTheme.labelStyle,
                            children: [
                              const TextSpan(text: 'Abierto por '),
                              TextSpan(
                                text: usuarioAbrio,
                                style: AppTheme.tituloClaro,
                              ),
                              const TextSpan(text: ' a las '),
                              TextSpan(
                                text: horaAper,
                                style: AppTheme.tituloClaro,
                              ),
                            ],
                          ),
                        ),
                        usuarioCerro != null
                        ? RichText(
                            textAlign: TextAlign.center,
                            textScaler: const TextScaler.linear(0.8),
                            text: TextSpan(
                              style: AppTheme.labelStyle,
                              children: [
                                const TextSpan(text: 'Cerrado por '),
                                TextSpan(
                                  text: usuarioCerro,
                                  style: AppTheme.tituloClaro,
                                ),
                                const TextSpan(text: ' a las '),
                                TextSpan(
                                  text: horaCie,
                                  style: AppTheme.tituloClaro,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget headerUsers() {
    final DateTime fechaCaja = DateTime.parse(widget.caja.fechaApertura);
    final String mes = DateFormat('d - MMMM - yyyy', 'es_MX').format(fechaCaja).toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.tablaColorHeader,
            border: const Border(bottom: BorderSide(color: Colors.black12, width: 3)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            )
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CAJA: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                        SelectableText(widget.caja.folio!, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.6)),
                      ],
                    ),
                    const SizedBox(width: 15), // Separación mínima entre grupos
                    Text(mes, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final cortesLista = widget.cortesHistorial ?? Provider.of<CajasServices>(context, listen: false).cortesDeCaja;
    if (cortesLista.length==1){
      estado = 'corte';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [

        //Header izqui
        Padding(
          padding: EdgeInsets.only(left: widget.readMode ? 40 : 15),
          child: estado == 'todos' 
            ? headerTodos() 
            : estado == 'corte' 
              ? headerCorte() 
              : estado == 'users' 
                ? headerUsers() 
                : const SizedBox(),
        ),
        //Header centra/derecho
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Transform.translate(
              offset: const Offset(-15, -60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  
                  _CajaBoton(
                    label: 'Movimientos',
                    icon: Icons.swap_horiz,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          MovimientoCajaDialog(cortes: widget.cortesHistorial),
                          const WindowBar(overlay: true),
                        ],
                      ),
                    ),
                    cerrar: false,
                    disabled: false,
                  ),
                  SizedBox(width: !widget.readMode ? 15 : 0),

                  widget.readMode==true ? 
                  BotonDetalles(
                    estado: estado,
                    caja: widget.caja,
                    corte: widget.corte,
                    ventas: widget.ventas,
                  ) : const SizedBox(),
                  
                  widget.readMode==false ?
                  _CajaBoton(
                    label: 'Realizar Corte',
                    icon: Icons.price_check,
                    onTap: () {
                      if (Configuracion.memoryCorte!=null){
                        if (Configuracion.memoryCorte!.isCierre){
                          mostrarMensajeFlotante(context, 'Tienes un cierre de caja pendiente');
                          return;
                        }
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          final ventasServices = Provider.of<VentasEnviadasServices>(context, listen: false);
                          if (VentasStates.tabs.any((element) => element.fromVentaEnviada) || 
                              ventasServices.ventas.isNotEmpty) {
                            return const CustomErrorDialog(
                              respuesta: 'Tienes ventas sin completar', 
                              titulo: 'No puedes continuar'
                            );
                          }

                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CorteDialog(cierre: false, caja: CajasServices.cajaActual!, corte: CajasServices.corteActual!, ventas: Provider.of<VentasServices>(context, listen: false).ventasDeCorteActual),
                              const WindowBar(overlay: true),
                            ],
                          );
                        } 
                      );
                    },
                    cerrar: false,
                    disabled: !Configuracion.esCaja,
                  ): const SizedBox(),
                  SizedBox(width: widget.readMode==false ? 15: 0),

                  widget.readMode==false ?
                  _CajaBoton(
                    label: 'Cerrar Caja',
                    icon: Icons.point_of_sale,
                    onTap: () {
                      if (Configuracion.memoryCorte!=null){
                        if (!Configuracion.memoryCorte!.isCierre){
                          mostrarMensajeFlotante(context, 'Tienes un cierre de corte pendiente');
                          return;
                        }
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          final ventasServices = Provider.of<VentasEnviadasServices>(context, listen: false);
                          if (VentasStates.tabs.any((element) => element.fromVentaEnviada) || 
                              ventasServices.ventas.isNotEmpty) {
                            return const CustomErrorDialog(
                              respuesta: 'Tienes ventas sin completar', 
                              titulo: 'No puedes continuar'
                            );
                          }

                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CorteDialog(cierre: true, caja: CajasServices.cajaActual!, corte: CajasServices.corteActual!, ventas: Provider.of<VentasServices>(context, listen: false).ventasDeCorteActual),
                              const WindowBar(overlay: true),
                            ],
                          );
                        } 
                      );
                    }, 
                    cerrar: true, 
                    disabled: !Configuracion.esCaja,
                  ): const SizedBox(),
                ],
              ),
            ),
        
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [ 

                //Info ReadMode
                widget.readMode ? 
                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      border: const Border(bottom: BorderSide(color: Colors.black12, width: 3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.caja.sucursalId),
                            style: AppTheme.tituloClaro,
                          ),
                          Text('Tipo de cambio: ${Formatos.moneda.format(widget.caja.tipoCambio)}', textScaler: const TextScaler.linear(0.8))
                        ],
                      ),
                    ),
                  ),
                )
                : const SizedBox(),

                //Drop Down Button
                Filtro(onFiltroCambio: (value) => filtrarVentasPor(value), cortesHistorial: widget.cortesHistorial),
                const SizedBox(height: 88),
              ],
            ),
        
          ],
        )
      ],
    );
  }
}

class BotonDetalles extends StatelessWidget {
  const BotonDetalles({
    super.key, required this.estado, required this.caja, required this.corte, required this.ventas,
  });

  final String estado;
  final Cajas caja;
  final Cortes corte;
  final List<Ventas> ventas;

  @override
  Widget build(BuildContext context) {
    if (estado=='todos'){
      return const SizedBox();
      /*return _CajaBoton(
        label: 'Detalles de la Caja',
        icon: Icons.price_check,
        onTap: () => showDialog(
          context: context,
          builder: (_) => const Stack(
            alignment: Alignment.topRight,
            children: [
              WindowBar(overlay: true),
            ],
          ),
        ),
        cerrar: false,
        disabled: false,
      );*/
    } else if (estado=='corte'){
      return Padding(
        padding: const EdgeInsets.only(left: 15),
        child: _CajaBoton(
          label: 'Detalles del Corte',
          icon: Icons.price_check,
          onTap: () => showDialog(
            context: context,
            builder: (_) => Stack(
              alignment: Alignment.topRight,
              children: [
                CorteDialog(cierre: false, caja: caja, corte:corte, ventas: ventas, readMode: true),
                const WindowBar(overlay: true),
              ],
            ),
          ),
          cerrar: false,
          disabled: false,
        ),
      );
    }
    return const SizedBox();
  }
}

class Filtro extends StatefulWidget {
  const Filtro({super.key, required this.onFiltroCambio, this.cortesHistorial});

  final ValueChanged<Map<String, String>?> onFiltroCambio;
  final List<Cortes>? cortesHistorial;

  @override
  State<Filtro> createState() => _FiltroState();
}

class _FiltroState extends State<Filtro> {
  final List<Map<String, String>> opciones = [
    {'todos':'Todas las ventas del dia'},
  ];

  Map<String, String>? _valorSeleccionado;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final cajasSvc = Provider.of<CajasServices>(context, listen: false);
    final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
    final cortesLista = widget.cortesHistorial ?? cajasSvc.cortesDeCaja;

    if (Login.usuarioLogeado.permisos==Permiso.normal){
      opciones.clear();
      opciones.add({'users': Login.usuarioLogeado.id!});
    } else {
      if (cortesLista.length==1){
        opciones.removeAt(0);
      }
      opciones.addAll(
        cortesLista.map((corte) => {'corte': corte.id!})
      );
      opciones.addAll(
        usuariosSvc.usuarios.map((user) => {'users': user.id!})
      );
    }
    _valorSeleccionado = opciones.first;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  String _getDropdownText(Map<String, String> opcion) {
    final key = opcion.keys.first;
    final value = opcion.values.first;
    
    if (key == 'todos') return value;
    
    if (key == 'corte') {
      final cajasSvc = Provider.of<CajasServices>(context, listen: false);
      final cortesLista = widget.cortesHistorial ?? cajasSvc.cortesDeCaja;
      final corte = cortesLista.firstWhere((element) => element.id == value);
      final esTurnoActual = CajasServices.corteActualId == corte.id;
      return 'Turno: ${corte.folio!}${esTurnoActual ? ' (actual)' : ''}';
    }
    
    if (key == 'users') {
      final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
      final user = usuariosSvc.usuarios.firstWhere((element) => element.id == value);
      return user.nombre;
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 13),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isFocused ? AppTheme.tablaColorHeader.withAlpha(200) : AppTheme.tablaColorHeader,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          border: const Border(bottom: BorderSide(color: Colors.black12, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, String>>(
            focusNode: _focusNode,
            value: _valorSeleccionado,
            items: opciones.map((opcion) {
              return DropdownMenuItem<Map<String, String>>(
                value: opcion,
                child: Text(_getDropdownText(opcion)),
              );
            }).toList(),
            dropdownColor: AppTheme.containerColor2,
            style: const TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
            iconEnabledColor: Colors.white,
            onChanged: (nuevo) {
              widget.onFiltroCambio(nuevo);
              setState(() {
                _valorSeleccionado = nuevo;
                _focusNode.unfocus();
                
              });
            },
          ),
        ),
      ),
    );
  }
}

class _TablaHeader extends StatelessWidget {
  const _TablaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child:  const Row(
        children: [
          Expanded(flex: 4, child: Text('Folio', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Vendedor', textAlign: TextAlign.center)),
          Expanded(flex: 5, child: Text('Cliente', textAlign: TextAlign.center)),
          Expanded(flex: 8, child: Text('Detalles', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Descuento', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Subtotal', textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('IVA', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Total', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Tooltip(
            message: 'El color amarillo indica que la cuenta aún está pendiente de pago,\nmientras que el verde señala que ya ha sido liquidada.',
            waitDuration: Duration(milliseconds: 250),
            child: Text('Total pagado', textAlign: TextAlign.center)
          )),
          Expanded(flex: 3, child: Text('Hora', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _FilaVentas extends StatelessWidget {
  const _FilaVentas({required this.index, required this.venta, required this.tc, required this.readMode, required this.callback});

  final int index;
  final Ventas venta;
  final double tc;
  final bool readMode;
  final Function() callback;

  @override
  Widget build(BuildContext context) {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);

    final vendedorNombre = usuarioSvc.obtenerNombreUsuarioPorId(venta.usuarioId);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(venta.clienteId);
    final detalles = productosSvc.obtenerDetallesComoTexto(venta.detalles);
    final fecha = DateFormat('hh:mm a').format(DateTime.parse(venta.fechaVenta!));
    //double abonado = venta.liquidado? venta.total.toDouble() : venta.recibidoTotal.toDouble(); 

    TextStyle estilo;
    if (venta.liquidado && venta.wasDeuda && !venta.cancelado){
      estilo = AppTheme.goodStyle;
    } else if (!venta.liquidado) {
      estilo = AppTheme.warningStyle;
    } else {
      estilo = AppTheme.subtituloConstraste;
    }


    return FeedBackButton(
      onlyVertical: true,
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              VentaDialog(venta: venta, tc: tc, isActive: !readMode, callback: callback),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        color: venta.cancelado ? 
          AppTheme.colorError2.withAlpha(index % 2 == 0 ? 130 : 85) 
        : index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            if (venta.facturaId!=null)
              Transform.translate(
                offset: const Offset(1, -3),
                child: Icon(
                  Icons.receipt, 
                  size: 15,
                  color: AppTheme.colorContraste.withAlpha(100),
                )
              ),
            Row(
              children: [
                Expanded(flex: 4, child: Text(venta.folio!, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 4, child: Text(vendedorNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 5, child: Text(clienteNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 8, child: Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.descuento.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.subTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text(Formatos.pesos.format(venta.iva.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
                !venta.cancelado ?
                Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: estilo, textAlign: TextAlign.center))
                :
                Expanded(flex: 4, child: Text('CANCELADO', style: estilo.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500), textScaler: const TextScaler.linear(0.9), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaFooter extends StatelessWidget {
  const _TablaFooter({required this.total, required this.venta});

  final int total;  
  final double venta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          
          Text('  Total de ventas: $total   ', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),

          
          Row(
            children: [
              const Text('Total:  ', textScaler: TextScaler.linear(1.2)),
              Text(
                Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.elevado) ?
                  Formatos.pesos.format(venta)
                  : '*'*Formatos.pesos.format(venta).length,
                style: AppTheme.tituloClaro, 
                textScaler: const TextScaler.linear(1.5),
              ),
              const SizedBox(width: 8)
            ],
          )

        ],
      ),
    );
  }
}

class _CajaBoton extends StatelessWidget {
  const _CajaBoton({required this.label, required this.icon, required this.onTap, required this.cerrar, required this.disabled});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool cerrar;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'Necesitas estar en la Caja' : '',
      waitDuration: Durations.short4,
      child: ElevatedButton(
        style: cerrar 
        ? ElevatedButton.styleFrom(
          backgroundColor: AppTheme.colorError2,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Custom radius
          ),
        ) 
        : ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey
        ),
        onPressed: !disabled ? onTap : null,
        child:cerrar ? Row(
          children: [
            Icon(icon, size: 21, color: Colors.white),
            Text(' $label', style: AppTheme.tituloClaro),
          ],
        ) 
        :
        Row(
          children: [
            Icon(icon, size: 21),
            Text(' $label'),
          ],
        ),
      ),
    );
  }
}