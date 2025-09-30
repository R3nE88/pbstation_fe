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
  List<Ventas> _ventasParaMostrar = [];

  @override
  void initState() {
    super.initState();
    if (CajasServices.cajaActualId != null && CajasServices.cajaActualId != 'buscando' && CajasServices.corteActualId != null) {
      datosIniciales();
    }
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

  Decimal sumarTotal (List<Ventas> ventas){
    Decimal sumaTotal = Decimal.zero;
    for (var venta in ventas) {
      sumaTotal += venta.abonadoTotal;
    }
    return sumaTotal;
  }

  void filtrarVentasPor(Map<String, String>? opcion) async{
    if (opcion==null) return;
    //Si es un corte
    if (opcion.keys.first=='corte'){
      final ventaSvc = Provider.of<VentasServices>(context, listen: false);
      final cajaSvc = Provider.of<CajasServices>(context, listen: false);
      Loading.displaySpinLoading(context);
      List<String> ventasIds = cajaSvc.cortesDeCaja.firstWhere((element) => element.id == opcion.values.first).ventasIds;
      _ventasParaMostrar = await ventaSvc.loadVentasDeCortes(ventasIds);
      setState(() {});
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
      _ventasParaMostrar = tmp;
      setState(() {});
    }
    //Si es la venta total (otro)
    if (opcion.keys.first=='otro'){
      _ventasParaMostrar = Provider.of<VentasServices>(context, listen: false).ventasDeCaja;
      setState(() {});
    }

  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UsuariosServices, VentasServices, CajasServices>(
      builder: (context, usuariosSvc, ventasSvc, cajasSvc, child) {
        
        if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActualId==null)){
          return AbrirCaja(metodo: datosIniciales);
        }

        if (usuariosSvc.isLoading || ventasSvc.isLoading || cajasSvc.cortesDeCajaIsLoading || cajasSvc.isLoading){
          return SimpleLoading();
        }

        return BodyPadding(
          child: Column(
            children: [
              //Header
              _Header(
                total: sumarTotal(_ventasParaMostrar),
                onFiltroCambio: (value) => filtrarVentasPor(value),
              ), 
              //Body
              Expanded(
                child: Column(
                  children: [
                    _TablaHeader(),
                    Expanded(
                      child: Container(
                        color: _ventasParaMostrar.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                        child: ListView.builder(
                          itemCount: _ventasParaMostrar.length,
                          itemBuilder: (context, index) {
                            return _FilaVentas(index: index, venta: _ventasParaMostrar[index]);
                          },
                        ),
                      ),
                    ),
                    _TablaFooter(total: _ventasParaMostrar.length)
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

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onFiltroCambio});
  final Decimal total;
  final ValueChanged<Map<String, String>?> onFiltroCambio;

  @override
  Widget build(BuildContext context) {
    
    final DateTime fecha = DateTime.parse(CajasServices.corteActual!.fechaApertura);
    final mes = DateFormat('MMM', 'es_MX').format(fecha).toUpperCase();
    final String hora = DateFormat('hh:mm a').format(fecha);
    final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(CajasServices.corteActual!.usuarioId);
    
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
                  Text(CajasServices.cajaActual!.folio!, style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.6)),
                  const Text("   TURNO: ", style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                  Text(CajasServices.corteActual!.folio!, style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.6))
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 13, right: 13, bottom: 13),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Turno abierto por\n$usuario', textAlign: TextAlign.center),
                          Text('${fecha.day}/$mes/${fecha.year} a las $hora'),
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
            const SizedBox(height: 40),
        
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
                  texto = 'Corte: ${corte.folio!} (turno actual)';
                } else {
                  texto = 'Corte: ${corte.folio!}';
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
      child:  Row(
        children: [
          const Expanded(flex: 4, child: Text('Folio', textAlign: TextAlign.center)),
          const Expanded(flex: 4, child: Text('Vendedor', textAlign: TextAlign.center)),
          const Expanded(flex: 4, child: Text('Cliente', textAlign: TextAlign.center)),
          const Expanded(flex: 8, child: Text('Detalles', textAlign: TextAlign.center)),
          const Expanded(flex: 4, child: Text('Descuento', textAlign: TextAlign.center)),
          const Expanded(flex: 4, child: Text('Subtotal', textAlign: TextAlign.center)),
          const Expanded(flex: 3, child: Text('IVA', textAlign: TextAlign.center)),
          const Expanded(flex: 4, child: Text('Total', textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Tooltip(
            message: 'El color amarillo indica que la cuenta aún está pendiente de pago,\nmientras que el verde señala que ya ha sido liquidada.',
            waitDuration: Duration(milliseconds: 750),
            child: Text('Pagado', textAlign: TextAlign.center)
          )),
          const Expanded(flex: 3, child: Text('Hora', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _FilaVentas extends StatelessWidget {
  const _FilaVentas({required this.index, required this.venta});

  final int index;
  final Ventas venta;

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

    late TextStyle estilo;
    if (venta.liquidado && venta.wasDeuda){
      estilo = TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
    } else if (!venta.liquidado) {
      estilo = AppTheme.warningStyle;
    } else {
      estilo = AppTheme.subtituloConstraste;
    }


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
          Expanded(flex: 4, child: Text(Formatos.pesos.format(venta.abonadoTotal.toDouble()), style: estilo, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _TablaFooter extends StatelessWidget {
  const _TablaFooter({required this.total});

  final int total;  

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