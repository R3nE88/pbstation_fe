import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/abrir_caja.dart';
import 'package:pbstation_frontend/screens/caja/dialog/corte_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/movimiento_caja_dialog.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
    bool init = false;
    Cajas? caja;
    Cortes? corte;
    Usuarios? usuario;
    late DateTime fechaApertura;
    late String hora;
    List<Ventas> ventasParaMostrar = [];

    void datosIniciales(){
      caja = CajasServices.cajaActual;
      corte = CajasServices.corteActual;
      fechaApertura = DateTime.parse(caja!.fechaApertura);
      hora = DateFormat('hh:mm a').format(fechaApertura);
      final ventasSvc =  Provider.of<VentasServices>(context, listen: false);
      ventasSvc.loadVentasDeCaja(caja!.id!).whenComplete(
        () => ventasParaMostrar.addAll(ventasSvc.ventasDeCaja),
      );
      Provider.of<CajasServices>(context, listen: false).loadCortesDeCaja(CajasServices.cajaActualId!);
      final usuariosSvc = Provider.of<UsuariosServices>(context, listen: false);
      usuariosSvc.loadUsuarios().whenComplete(
        () => usuario = usuariosSvc.usuarios.firstWhere((element) => element.id == caja!.usuarioId),
      );
    }

  @override
  void initState() {
    super.initState();
    if (CajasServices.cajaActualId != null && CajasServices.cajaActualId != 'buscando' && CajasServices.corteActual != null) {
      datosIniciales();
    }
  }

  Decimal sumarTotal (List<Ventas> ventas){
    Decimal sumaTotal = Decimal.zero;
    for (var venta in ventas) {
      sumaTotal += venta.total;
    }
    return sumaTotal;
  }

  void filtrarVentasPor(Map<String, String>? opcion) async{
    if (opcion==null) return;
    //Si es un corte
    if (opcion.keys.first=='corte'){
      final ventaSvc = Provider.of<VentasServices>(context, listen: false);
      Loading.displaySpinLoading(context);
      ventasParaMostrar = await ventaSvc.loadVentasDeCorte(opcion.values.first) ?? [];
      if (!mounted) return;
      Navigator.pop(context);
    }
    //Si es un usuario
    if (opcion.keys.first=='users'){
      List<Ventas> tmp = [];
      for (var venta in Provider.of<VentasServices>(context, listen: false).ventasDeCaja) {
        if (venta.usuarioId == opcion.values.first){
          tmp.add(venta);
        }
      }
      ventasParaMostrar = tmp;
      setState(() {});
    }
    //Si es la venta total (otro)
    if (opcion.keys.first=='otro'){
      ventasParaMostrar = Provider.of<VentasServices>(context, listen: false).ventasDeCaja;
      setState(() {});
    }

  }

  @override
  Widget build(BuildContext context) {
    if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActual==null)){
      return AbrirCaja(metodo: datosIniciales);
    }

    return Consumer3<UsuariosServices, VentasServices, CajasServices>(
      builder: (context, usuariosSvc, ventasSvc, cajasSvc, child) {
        if (usuariosSvc.isLoading || ventasSvc.isLoading || cajasSvc.cortesDeCajaIsLoading){
          return SimpleLoading();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
          child: Container(
            color: AppTheme.containerColor1,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  
                  //Header
                  _Header(
                    total: sumarTotal(ventasParaMostrar),
                    onFiltroCambio: (value) => filtrarVentasPor(value),
                  ), 

                  //Body
                  Expanded(
                    child: Column(
                      children: [
                        _TablaHeader(),
                        Expanded(
                          child: Container(
                            color: ventasParaMostrar.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                            child: ListView.builder(
                              itemCount: ventasParaMostrar.length,
                              itemBuilder: (context, index) {
                                return _FilaVentas(index: index, venta: ventasParaMostrar[index]);
                              },
                            ),
                          ),
                        ),
                        _TablaFooter(total: ventasParaMostrar.length)
                      ],
                    )
                  ),
                ],
              )
            )
          )
        );
      }
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onFiltroCambio});
  final Decimal total;
  final ValueChanged<Map<String, String>?> onFiltroCambio;

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = DateTime.parse(CajasServices.cajaActual!.fechaApertura);
    final mes = DateFormat('MMM', 'es_MX').format(fecha).toUpperCase();
    final String hora = DateFormat('hh:mm a').format(fecha);
    final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(CajasServices.cajaActual!.usuarioId);
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [

        //Header izqui
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: Offset(0, -8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("CAJA: ", style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                  Text(CajasServices.cajaActual!.folio!, style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.6))
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)
                      ),
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 3))
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Abierta por $usuario'),
                          Text('${fecha.day}/$mes/${fecha.year} a las $hora'),
                          //Text('Fondo: ${Formatos.pesos.format(fondo)}'),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 3)),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)
                      ),
                    ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Total: ', textScaler: TextScaler.linear(1.3)),
                            Text(Formatos.pesos.format(total.toDouble()),style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    
        //Header centra/derecho
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CajaBoton(
                  label: 'Movimientos',
                  icon: Icons.swap_horiz,
                  onTap: () => showDialog(
                    context: context,
                    useSafeArea: true,
                    builder: (_) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        const MovimientoCajaDialog(),
                        const WindowBar(overlay: true),
                      ],
                    ),
                  ),
                  cerrar: false,
                  disabled: false,
                ),
                const SizedBox(width: 15),
                _CajaBoton(
                  label: 'Realizar Corte',
                  icon: Icons.price_check,
                  onTap: () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        const CorteDialog(cierre: false),
                        const WindowBar(overlay: true),
                      ],
                    ),
                  ),
                  cerrar: false,
                  disabled: !Configuracion.esCaja,
                ),
                const SizedBox(width: 15),
                _CajaBoton(
                  label: 'Cerrar Caja',
                  icon: Icons.point_of_sale,
                  onTap: () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        const CorteDialog(cierre: true),
                        const WindowBar(overlay: true),
                      ],
                    ),
                  ),
                  cerrar: true, 
                  disabled: !Configuracion.esCaja,
                ),
              ],
            ),
            const SizedBox(height: 15),
        
            //Drop Down Button
            Filtro(onFiltroCambio: onFiltroCambio),
        
          ],
        ),
      ],
    );
  }
}

class Filtro extends StatefulWidget {
  const Filtro({super.key, required this.onFiltroCambio});
  final ValueChanged<Map<String, String>?> onFiltroCambio;


  @override
  State<Filtro> createState() => _FiltroState();
}

class _FiltroState extends State<Filtro> {
  final List<Map<String, String>> opciones = [
    {'otro':'Todas las ventas del dia'},
  ];

  Map<String, String>? _valorSeleccionado;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    //Agregar los cortes como opcion
    for (var corte in Provider.of<CajasServices>(context, listen: false).cortesDeCaja) {
      opciones.add({'corte': corte.id!});
    }
    //Agregar los empelados como opcion
    for (var users in Provider.of<UsuariosServices>(context, listen: false).usuarios) {
      opciones.add({'users': users.id!});
    }


    _valorSeleccionado = opciones.first;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 13),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isFocused ? AppTheme.containerColor2 : AppTheme.tablaColorHeader,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          border: Border(bottom: BorderSide(color: Colors.black12, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, String>>(
            focusNode: _focusNode,
            value: _valorSeleccionado,
            items: opciones.map((opcion) {
              late final String texto;
              if (opcion.keys.first=='otro') {
                texto = opcion.values.first;
              } else if (opcion.keys.first=='corte') {
                Cortes corte = Provider.of<CajasServices>(context, listen: false).cortesDeCaja.firstWhere((element) => element.id == opcion.values.first);
                if (CajasServices.corteActualId == corte.id) {
                  texto = 'Tuno: ${corte.folio!} (actual)';
                } else {
                  texto = 'Tuno: ${corte.folio!}';
                }
                
              } else if (opcion.keys.first=='users'){
                Usuarios user = Provider.of<UsuariosServices>(context, listen: false).usuarios.firstWhere((element) => element.id == opcion.values.first);
                texto = user.nombre;
              }
              return DropdownMenuItem<Map<String, String>>(
                value: opcion,
                child: Text(texto),
              );
            }).toList(),
            dropdownColor: AppTheme.containerColor2,
            style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
            iconEnabledColor: Colors.white,
            onChanged: (nuevo) {
              widget.onFiltroCambio(nuevo);
              setState(() {
                _valorSeleccionado = nuevo;
                
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Folio', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Vendedor', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Cliente', textAlign: TextAlign.center)),
          Expanded(flex: 8, child: Text('Detalles', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Descuento', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Subtotal', textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('IVA', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Total', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Abonado', textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('Hora', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _FilaVentas extends StatelessWidget {
  final int index;
  final Ventas venta;

  const _FilaVentas({required this.index, required this.venta});

  @override
  Widget build(BuildContext context) {
    /*final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);

    final vendedorNombre = usuarioSvc.obtenerNombreUsuarioPorId(venta.usuarioId);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(venta.clienteId);
    final detalles = productosSvc.obtenerDetallesComoTexto(venta.detalles);
    final fecha = DateFormat('hh:mm a').format(DateTime.parse(venta.fechaVenta!));*/

    return Container(
      padding: const EdgeInsets.all(8),
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('venta.folio!', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('vendedorNombre', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('clienteNombre', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 8, child: Text('detalles', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.descuento.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.subTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(Formatos.pesos.format(venta.iva.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _TablaFooter extends StatelessWidget {
  final int total;

  const _TablaFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text('  Total de ventas: $total   ', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CajaBoton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool cerrar;
  final bool disabled;

  const _CajaBoton({required this.label, required this.icon, required this.onTap, required this.cerrar, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'Necesitas estar en la Caja' : '',
      waitDuration: Durations.short4,
      child: ElevatedButton(
        style: cerrar 
        ? ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 211, 196),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Custom radius
          ),
        ) 
        : ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey
        ),
        onPressed: !disabled ? onTap : null,
        child: Row(
          children: [
            Icon(icon, size: 21),
            Text(' $label'),
          ],
        ),
      ),
    );
  }
}

//TODO: TERMINAR LO DE ARRIBA Y COMENTAR LO DE ABAJO, HASTA QUE COMPRUEBE QUE LAS VENTAS SE OBTIENEN BIEN SORTEADAS POR FECHAS
/*
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/abrir_caja.dart';
import 'package:pbstation_frontend/screens/caja/dialog/cerrar_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/corte_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/movimiento_caja_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  bool init = false;
  Cajas? caja;
  Cortes? corte;
  Usuarios? usuario;
  late DateTime fechaApertura;
  late String hora;
  //bool cajaNotFound=false;
  String? _opcionSeleccionada = 'Todas las ventas del dia';
  final List<String> _opciones = ['Todas las ventas del dia', 'Turno actual'];

  // ============ LÓGICA ============

  Future<void> obtenerUsuarioDeCaja() async {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    usuario = await usuarioSvc.searchUsuario(caja!.usuarioId);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    if (CajasServices.cajaActualId != null && CajasServices.cajaActualId != 'buscando' && CajasServices.corteActual != null) {
      datosIniciales();
    }
  }


  void datosIniciales(){
    caja = CajasServices.cajaActual;
    corte = CajasServices.corteActual;
    obtenerUsuarioDeCaja();
    fechaApertura = DateTime.parse(caja!.fechaApertura);
    hora = DateFormat('hh:mm a').format(fechaApertura);
    Provider.of<VentasServices>(context, listen: false).loadVentasDeCaja(caja!.id!);
    //Provider.of<VentasServices>(context, listen: false).loadVentasDeCorte(CajasServices.corteActualId!);
    Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
    Provider.of<CajasServices>(context, listen: false)
        .loadCaja(CajasServices.cajaActualId!);
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    //final cajaSvc = Provider.of<CajasServices>(context);

    if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActual==null)){
      return AbrirCaja(metodo: datosIniciales);
    }

    return Consumer3<VentasServices, UsuariosServices, CajasServices>(
      builder: (context, ventasSvc, usr, cajaSvc, _) {
        if (ventasSvc.isLoading || usr.isLoading || cajaSvc.isLoading) {
          return const _CargandoDatos();
        }

        // Actualizar opciones del dropdown
        _opciones
          ..clear()
          ..add('Todas las ventas del dia')
          ..add('Turno actual')
          ..addAll(usr.usuarios.map((u) => u.id!));

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
          child: Container(
            color: AppTheme.containerColor1,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildTable(
                      _opcionSeleccionada != 'Todas las ventas del dia' && _opcionSeleccionada != 'Turno actual'
                          ? _opcionSeleccionada
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        _buildTopRow(),
        const SizedBox(height: 8),
        _buildInfoRow(),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('CAJA: ', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.6)),
        Text(caja!.folio!, style: AppTheme.subtituloPrimario, textScaler: const TextScaler.linear(1.3)),
        const Spacer(),
        Row(
          children: [
            _CajaBoton(
              label: 'Movimientos',
              icon: Icons.swap_horiz,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const MovimientoCajaDialog(),
              ),
              cerrar: false,
              disabled: false,
            ),
            const SizedBox(width: 15),
            _CajaBoton(
              label: 'Realizar Corte',
              icon: Icons.price_check,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CorteDialog(),
              ),
              cerrar: false,
              disabled: !Configuracion.esCaja,
            ),
            const SizedBox(width: 15),
            _CajaBoton(
              label: 'Cerrar Caja',
              icon: Icons.point_of_sale,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CerrarDialog(),
              ),
              cerrar: true, 
              disabled: !Configuracion.esCaja,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TarjetaUsuario(usuario: usuario, fecha: fechaApertura, hora: hora, fondo: corte!.fondoInicial.toDouble()),
        const SizedBox(width: 20),
        _TarjetaTotalVentas(
          opcionSeleccionada: _opcionSeleccionada!,
          onFiltroCambio: (val) => setState(() => _opcionSeleccionada = val),
        ),
      ],
    );
  }

  Widget _buildTable([String? filtrarPorUsuario]) {
    return Consumer<VentasServices>(
      builder: (context, servicios, _) {
        final ventas = _filtrarVentas(_opcionSeleccionada=='Turno actual' ? servicios.ventasDeCorteActual : servicios.ventasDeCaja, filtrarPorUsuario);

        return Column(
          children: [
            const _TablaHeader(),
            Expanded(
              child: Container(
                color: ventas.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: ventas.length,
                  itemBuilder: (context, i) => FilaVentas(venta: ventas[i], index: i),
                ),
              ),
            ),
            _TablaFooter(total: ventas.length),
          ],
        );
      },
    );
  }

  List<Ventas> _filtrarVentas(List<Ventas> ventas, String? usuarioId) {
    if (!Login.admin) {
      return ventas.where((v) => v.usuarioId == Login.usuarioLogeado.id).toList();
    }
    if (usuarioId == null) return ventas;
    return ventas.where((v) => v.usuarioId == usuarioId).toList();
  }
}

// ============ SUBWIDGETS ============


class _CargandoDatos extends StatelessWidget {
  const _CargandoDatos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cargando datos...', style: TextStyle(color: AppTheme.colorContraste)),
          const SizedBox(height: 10),
          CircularProgressIndicator(color: AppTheme.colorContraste),
        ],
      ),
    );
  }
}

class _CajaBoton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool cerrar;
  final bool disabled;

  const _CajaBoton({required this.label, required this.icon, required this.onTap, required this.cerrar, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'Necesitas estar en la Caja' : '',
      waitDuration: Durations.short4,
      child: ElevatedButton(
        style: cerrar 
        ? ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 211, 196),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Custom radius
          ),
        ) 
        : ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey
        ),
        onPressed: !disabled ? onTap : null,
        child: Row(
          children: [
            Icon(icon, size: 21),
            Text(' $label'),
          ],
        ),
      ),
    );
  }
}

class _TarjetaUsuario extends StatelessWidget {
  final Usuarios? usuario;
  final DateTime fecha;
  final String hora;
  final double fondo;

  const _TarjetaUsuario({
    required this.usuario,
    required this.fecha,
    required this.hora,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _decoracion(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: usuario == null
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Abierta por ${usuario!.nombre}'),
                Text('${fecha.day}/${fecha.month}/${fecha.year} a las $hora'),
                Text('Fondo: ${Formatos.pesos.format(fondo)}'),
              ],
            ),
    );
  }

  BoxDecoration _decoracion() => BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: BorderRadius.circular(15),
      );
}

class _TarjetaTotalVentas extends StatelessWidget {
  final String opcionSeleccionada;
  final ValueChanged<String?> onFiltroCambio;

  const _TarjetaTotalVentas({
    required this.opcionSeleccionada,
    required this.onFiltroCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer2<VentasServices, UsuariosServices>(
        builder: (context, service, usr, _) {
          final total = _calcularTotal(opcionSeleccionada=='Turno actual' ? service.ventasDeCorteActual : service.ventasDeCaja);
          final esAdmin = Login.usuarioLogeado.rol == "admin";

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat("EEEE, d 'de' MMMM, y", 'es_ES').format(DateTime.now()), style: AppTheme.tituloClaro),
                  const SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      children: [
                        Text(
                          _textoTitulo(esAdmin, usr),
                          style: AppTheme.subtituloPrimario,
                        ),
                        Text(Formatos.pesos.format(total.toDouble()), textScaler: const TextScaler.linear(1.3)),
                      ],
                    ),
                  ),
                ],
              ), const SizedBox(width: 20),
              
              const Spacer(),
              if (esAdmin)
              Row(
                children: [
                  Text('Filtrar: '),
                  _DropdownUsuarios(
                    opcionSeleccionada: opcionSeleccionada,
                    opciones: ['Todas las ventas del dia', 'Turno actual', ...usr.usuarios.map((u) => u.id!)],
                    usr: usr,
                    onFiltroCambio: onFiltroCambio,
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Decimal _calcularTotal(List<Ventas> ventas) {
    Decimal total = Decimal.zero;
    if (Login.usuarioLogeado.rol != "admin") {
      total = ventas
          .where((v) => v.usuarioId == Login.usuarioLogeado.id)
          .fold(Decimal.zero, (acc, v) => acc + v.total);
    } else if (opcionSeleccionada == 'Todas las ventas del dia' || opcionSeleccionada == 'Turno actual') {
      total = ventas.fold(Decimal.zero, (acc, v) => acc + v.total);
    } else {
      total = ventas
          .where((v) => v.usuarioId == opcionSeleccionada)
          .fold(Decimal.zero, (acc, v) => acc + v.total);
    }
    return total;
  }

  String _textoTitulo(bool esAdmin, UsuariosServices usr) {
    if (!esAdmin) return 'Mis Ventas del Turno: ';
    if (opcionSeleccionada == 'Todas las ventas del dia') return 'Total Vendido: ';
    if (opcionSeleccionada == 'Turno actual') return 'Vendido en este turno: ';
    return 'Ventas de ${usr.obtenerNombreUsuarioPorId(opcionSeleccionada)}: ';
  }
}

class _DropdownUsuarios extends StatefulWidget {
  final String opcionSeleccionada;
  final List<String> opciones;
  final UsuariosServices usr;
  final ValueChanged<String?> onFiltroCambio;

  const _DropdownUsuarios({
    required this.opcionSeleccionada,
    required this.opciones,
    required this.usr,
    required this.onFiltroCambio,
  });

  @override
  State<_DropdownUsuarios> createState() => _DropdownUsuariosState();
}

class _DropdownUsuariosState extends State<_DropdownUsuarios> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _isFocused ? AppTheme.containerColor2     : AppTheme.tablaColorHeader,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          focusNode: _focusNode,
          value: widget.opcionSeleccionada,
          items: widget.opciones.map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text((id == 'Todas las ventas del dia' || id == 'Turno actual') ? id : widget.usr.obtenerNombreUsuarioPorId(id)),
            );
          }).toList(),
          onChanged: widget.onFiltroCambio,
          dropdownColor: AppTheme.containerColor2,
          style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
          iconEnabledColor: Colors.white,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Folio', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Vendedor', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Cliente', textAlign: TextAlign.center)),
          Expanded(flex: 8, child: Text('Detalles', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Descuento', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Subtotal', textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('IVA', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Total', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text('Abonado', textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('Hora', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _TablaFooter extends StatelessWidget {
  final int total;

  const _TablaFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text('  Total de ventas: $total   ', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============ FILAS ============

class FilaVentas extends StatelessWidget {
  final int index;
  final Ventas venta;

  const FilaVentas({super.key, required this.index, required this.venta});

  @override
  Widget build(BuildContext context) {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);

    final vendedorNombre = usuarioSvc.obtenerNombreUsuarioPorId(venta.usuarioId);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(venta.clienteId);
    final detalles = productosSvc.obtenerDetallesComoTexto(venta.detalles);
    final fecha = DateFormat('hh:mm a').format(DateTime.parse(venta.fechaVenta!));

    return Container(
      padding: const EdgeInsets.all(8),
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(venta.folio!, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(vendedorNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(clienteNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 8, child: Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.descuento.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.subTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(Formatos.pesos.format(venta.iva.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
*/