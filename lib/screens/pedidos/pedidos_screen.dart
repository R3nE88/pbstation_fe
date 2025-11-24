import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final pedidosSvc = Provider.of<PedidosService>(context, listen: false);
    pedidosSvc.loadPedidos();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController.text.toLowerCase();
        pedidosSvc.filtrarPedidos(query);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildHeader({String title = '', bool helpIcon = false}) {
    return Transform.translate(
      offset: const Offset(0, -7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          
          Row(
            children: [
              Text(
                title,
                style: AppTheme.tituloClaro,
                textScaler: const TextScaler.linear(1.3), 
              ),
              if (helpIcon) 
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.translate(
                    offset: const Offset(5, 0),
                    child: const Tooltip(
                      message: 'Aqui se encuentran los pedidos que se mandaron sin archivos',
                      child: Icon(
                        Icons.help, color: AppTheme.letraClara
                      ),
                    ),
                  ),
                )
            ],
          ),
          
          helpIcon ?
            Login.usuarioLogeado.rol == TipoUsuario.vendedor && (Login.usuarioLogeado.permisos.nivel==1 || Login.usuarioLogeado.permisos.nivel==2) ?
             Text(
              Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(SucursalesServices.sucursalActualID!),
              style: AppTheme.tituloClaro,
              textScaler: const  TextScaler.linear(1.3),
            ) : const SizedBox()
          : Transform.scale(
            scale: 0.95,
            child: SizedBox(
                height: 34,
                width: 300,
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar por Folio',
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Expanded _buildTableSinPreparar(PedidosService pedidosSvc) {
    return Expanded(
      flex: 5,
      child: Column(
        children: [

          _buildHeader(title: 'Pedidos pendientes de enviar a produccion', helpIcon: true),

          //Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Center(child: Text('Fecha'))),
                const Expanded(flex: 2, child: Center(child: Text('Folio'))),
                Login.usuarioLogeado.rol == TipoUsuario.vendedor && (Login.usuarioLogeado.permisos.nivel==1 || Login.usuarioLogeado.permisos.nivel==2) ?
                const SizedBox():
                const Expanded(flex: 2, child: Center(child: Text('Sucursal'))),
                const Expanded(flex: 2, child: Center(child: Text('Vendedor'))),
                const Expanded(flex: 3, child: Center(child: Text('Cliente'))),
                const Expanded(flex: 3, child: Center(child: Text('Detalles'))),
                const Expanded(flex: 2, child: Center(child: Text('Fecha Entrega'))),
              ],
            ),
          ),

          //body
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)
              ),
              child: Container(
                color: pedidosSvc.pedidosNotReady.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: pedidosSvc.pedidosNotReady.length,
                  itemBuilder: (context, index) {
                    return FilaNotReady(pedido: pedidosSvc.pedidosNotReady[index], index: index);
                  },
                ),
              ),
            ),
          ),


        ],
      )
    );
  }

  Expanded _buildTablePedidos(PedidosService pedidosSvc) {
    return Expanded(
      flex: 11,
      child: Column(
        children: [

          _buildHeader(title: 'Pedidos enviados a produccion'),

          //Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Center(child: Text('Estatus'))),
                const Expanded(flex: 2, child: Center(child: Text('Fecha'))),
                const Expanded(flex: 2, child: Center(child: Text('Folio'))),
                Login.usuarioLogeado.rol == TipoUsuario.vendedor && (Login.usuarioLogeado.permisos.nivel==1 || Login.usuarioLogeado.permisos.nivel==2) ?
                const SizedBox()
                : const Expanded(flex: 2, child: Center(child: Text('Sucursal'))),
                const Expanded(flex: 3, child: Center(child: Text('Cliente'))),
                const Expanded(flex: 3, child: Center(child: Text('Detalles'))),
                const Expanded(flex: 2, child: Center(child: Text('Fecha Entrega'))),
              ],
            ),
          ),

          //body
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)
              ),
              child: Container(
                color: pedidosSvc.filteredPedidosReady.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: pedidosSvc.filteredPedidosReady.length,
                  itemBuilder: (context, index) {
                    return FilaReady(pedido: pedidosSvc.filteredPedidosReady[index], index: index);
                  },
                ),
              ),
            ),
          ),

        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return  BodyPadding(
      child: Consumer<PedidosService>(
        builder: (context, value, child) {
          if (value.isLoading){
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                _buildTablePedidos(value),
                const SizedBox(height: 10),
                _buildTableSinPreparar(value), 
              ],
            );
          }
        },
      )
    );
  }
}

class FilaNotReady extends StatefulWidget {
  const FilaNotReady({super.key, required this.pedido, required this.index});

  final Pedidos pedido;
  final int index;

  @override
  State<FilaNotReady> createState() => _FilaNotReadyState();
}

class _FilaNotReadyState extends State<FilaNotReady> {
  late final dateTime = DateTime.parse(widget.pedido.fecha);
  late final fecha = DateFormat('d MMM hh:mm a', 'es_MX').format(dateTime);
  late final fechaDia = DateFormat('EEEE', 'es_MX').format(dateTime);
  late final dateTimeE = DateTime.parse(widget.pedido.fechaEntrega);
  late final fechaEntrega = DateFormat('d MMM hh:mm a', 'es_MX').format(dateTimeE);
  late final fechaEntregaDia = DateFormat('EEEE', 'es_MX').format(dateTimeE);
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.pedido.sucursalId);
  late final Ventas? venta;
  late final String detalles;
  bool detalleLoaded = false;

  void obtenerVenta() async{
    venta = await Provider.of<VentasServices>(context, listen: false).searchVenta(widget.pedido.ventaId);
    if (!mounted) return;
    detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(venta?.detalles??[]);
    setState(() { detalleLoaded = true; });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      obtenerVenta();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeedBackButton(
      onlyVertical: true,
      onPressed: (){
        if (venta==null) return;
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              PedidosDialog(pedido: widget.pedido, ventaId: venta!.id!),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        color: widget.index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child:  Row(
          children: [
            Expanded(flex: 2, child: Center(child: Text('$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),            
            Expanded(flex: 2, child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Login.usuarioLogeado.rol == TipoUsuario.vendedor && (Login.usuarioLogeado.permisos.nivel==1 || Login.usuarioLogeado.permisos.nivel==2) ?
            const SizedBox() 
            : Expanded(flex: 2, child: Center(child: Text(sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 2, child: Center(child: Text(usuario, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
            Expanded(flex: 3, child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
            Expanded(flex: 3, 
              child: Center(
                child: detalleLoaded ? 
                  Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85))
                : 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: LinearProgressIndicator(
                      color: AppTheme.containerColor1.withAlpha(150),
                      minHeight: 10,
                    ),
                  )
              )
            ),
            Expanded(flex: 2, child: Center(child: Text('$fechaEntregaDia\n$fechaEntrega', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
          ],
        ),
      ),
    );
  }
}

class FilaReady extends StatefulWidget {
  const FilaReady({super.key, required this.pedido, required this.index});

  final Pedidos pedido;
  final int index;

  @override
  State<FilaReady> createState() => _FilaReadyState();
}

class _FilaReadyState extends State<FilaReady> {
  late final dateTime = DateTime.parse(widget.pedido.fecha);
  late final fecha = DateFormat('d MMM hh:mm a', 'es_MX').format(dateTime);
  late final fechaDia = DateFormat('EEEE', 'es_MX').format(dateTime);
  late final dateTimeE = DateTime.parse(widget.pedido.fechaEntrega);
  late final fechaEntrega = DateFormat('d MMM hh:mm a', 'es_MX').format(dateTimeE);
  late final fechaEntregaDia = DateFormat('EEEE', 'es_MX').format(dateTimeE);
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.pedido.sucursalId);
  late final Ventas? venta;
  late final String detalles;
  bool detalleLoaded = false;
  late Color color = widget.pedido.estado.color;


  void obtenerVenta() async{
    venta = await Provider.of<VentasServices>(context, listen: false).searchVenta(widget.pedido.ventaId);
    if (!mounted) return;
    detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(venta?.detalles??[]);
    setState(() { detalleLoaded = true; });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      obtenerVenta();
    });
  }

  @override
  Widget build(BuildContext context) {
    color = widget.pedido.estado.color;

    return FeedBackButton(
      onlyVertical: true,
      onPressed: (){
        if (venta==null) return;
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              PedidosDialog(pedido: widget.pedido, ventaId: venta!.id!),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        color: widget.index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(flex: 2, child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                decoration: BoxDecoration(
                  color: AppTheme.isDarkTheme ?const Color.fromARGB(62, 0, 0, 0) : Colors.white70,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(capitalizarPrimeraLetra(widget.pedido.estado.name), style: TextStyle(color: color, fontWeight: FontWeight.bold))
              )
            )),
            Expanded(flex: 2, child: Center(child: Text('$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 2, child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Login.usuarioLogeado.rol == TipoUsuario.vendedor && (Login.usuarioLogeado.permisos.nivel==1 || Login.usuarioLogeado.permisos.nivel==2) ?
            const SizedBox() 
            : Expanded(flex: 2, child: Center(child: Text(sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 3, child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 3, child: Center( child: Text(detalleLoaded ? detalles : '...', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
            Expanded(flex: 2, child: Center(child: Text('$fechaEntregaDia\n$fechaEntrega', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
          ],
        ),
      ),
    );
  }

  Transform foquito(Color color) {
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: Container(
        height: 15, width: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15)
        )
      )
    );
  }
}