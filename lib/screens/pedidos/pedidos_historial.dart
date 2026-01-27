import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class PedidosHistorial extends StatefulWidget {
  const PedidosHistorial({super.key});

  @override
  State<PedidosHistorial> createState() => _PedidosHistorialState();
}

class _PedidosHistorialState extends State<PedidosHistorial> {
  final ScrollController _scrollController = ScrollController();
  String? sucursalId;

  @override
  void initState() {
    super.initState();
    
    if (Login.usuarioLogeado.permisos==Permiso.admin || Login.usuarioLogeado.rol == TipoUsuario.administrativo || Login.usuarioLogeado.rol == TipoUsuario.maquilador){
      sucursalId = null;
    } else {
      sucursalId = SucursalesServices.sucursalActualID;
    }

    // Cargar primera página cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cajasService = Provider.of<PedidosService>(context, listen: false);
      cajasService.cargarHistorial(sucursalId: sucursalId);
    });

    // Detectar scroll para cargar más
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Si está cerca del final, cargar más
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final cajasService = Provider.of<PedidosService>(context, listen: false);
      cajasService.cargarMasHistorial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      child: Column(
        children: [
          
          //Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Historial de pedidos',
                    style: AppTheme.tituloClaro,
                    textScaler: TextScaler.linear(1.7), 
                  ),
                  if (sucursalId!=null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(sucursalId!),
                        style: AppTheme.labelStyle,
                        textScaler: const TextScaler.linear(1.3), 
                      ),
                    ),
                ],
              ),

              ElevatedButtonIcon(
                text: 'Buscar pedido', 
                icon: Icons.search, 
                onPressed: (){

                }
              )
            ],
          ), const SizedBox(height: 10),

          //Tabla header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12)
              )
            ),
            child: Row(
              children: [
                const Expanded(flex:2, child: Center(child: Text('Folio'))),
                if (sucursalId!=null)
                  const Expanded(flex:2, child: Center(child: Text('Sucursal'))),
                const Expanded(flex: 3, child: Center(child: Text('Usuario'))),
                const Expanded(flex: 3, child: Center(child: Text('Cliente'))),
                //const Expanded(flex: 3, child: Center(child: Text('Detalles'))),
                const Expanded(flex: 2, child: Center(child: Text('Entrego'))),
                const Expanded(flex: 2, child: Center(child: Text('Fecha Entregado'))),
              ],
            ),
          ),

          //tabla body
          Expanded(
            child: Consumer<PedidosService>(
              builder: (context, pedidoSvc, child) {

                // Estado de carga inicial
                if (pedidoSvc.historialIsLoading && pedidoSvc.pedidosHistorial.isEmpty) {
                  return Container(
                    color: pedidoSvc.pedidosHistorial.length%2==0?AppTheme.tablaColor1:AppTheme.tablaColor2,
                    child: const Center(child: CircularProgressIndicator())
                  );
                }

                // Error sin datos
                if (pedidoSvc.historialError != null && pedidoSvc.pedidosHistorial.isEmpty) {
                  return Container(
                    color: pedidoSvc.pedidosHistorial.length%2==0?AppTheme.tablaColor1:AppTheme.tablaColor2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pedidoSvc.historialError!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => pedidoSvc.cargarHistorial(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                //Historial content
                return Container(
                  color: pedidoSvc.pedidosHistorial.length%2==0?AppTheme.tablaColor1:AppTheme.tablaColor2,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: pedidoSvc.pedidosHistorial.length,
                    itemBuilder: (context, index) {
                      return FilaPedidosHistorial(index: index, pedido: pedidoSvc.pedidosHistorial[index], sucursal: sucursalId!=null);
                    },
                  ),
                );
              }
            ),
          )

        ],
      )
    );
  }
}

class FilaPedidosHistorial extends StatefulWidget {
  const FilaPedidosHistorial({super.key, required this.index, required this.pedido, required this.sucursal});

  final int index;
  final Pedidos pedido;
  final bool sucursal;

  @override
  State<FilaPedidosHistorial> createState() => _FilaPedidosHistorialState();
}

class _FilaPedidosHistorialState extends State<FilaPedidosHistorial> {
  late final fechaDT = DateTime.parse(widget.pedido.fechaEntregado!);
  late final fecha = DateFormat('d MMM hh:mm a', 'es_MX').format(fechaDT);
  late final fechaDia = DateFormat('EEEE', 'es_MX').format(fechaDT);
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final String usuarioEntrego = widget.pedido.usuarioIdEntrego!=null ? Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioIdEntrego!) : '';
  late final String sucursal = widget.sucursal ? Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.pedido.sucursalId) : '';
  /*late final Ventas? venta;
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
  }*/
   
  @override
  Widget build(BuildContext context) {
    return FeedBackButton(
      onPressed: (){
        //if (venta==null) return;
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              PedidosDialog(pedido: widget.pedido, ventaId: null), //TODO: si ventaId es null, buscar dentro del dialog la venta
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      onlyVertical: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: widget.pedido.cancelado ? 
            AppTheme.colorError2.withAlpha(widget.index % 2 == 0 ? 130 : 85) 
          : widget.index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        ),
        child: Row(
          children: [
            Expanded(flex:2, child: Center(child: Text(widget.pedido.folio??'', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            if (widget.sucursal)
              Expanded(flex:2, child: Center(child: Text(sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 3, child: Center(child: Text(usuario, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 3, child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            //Expanded(flex: 3, child: Center( child: Text(detalleLoaded ? detalles : '...', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
            Expanded(flex: 2, child: Center(child: Text(widget.pedido.cancelado ? '-' : usuarioEntrego, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex: 2, child: Center(child: Text(widget.pedido.cancelado ? 'Cancelado' : '$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
          ],
        ),
      ),
    );
  }
}