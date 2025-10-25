import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    Provider.of<PedidosService>(context, listen: false).loadPedidos();

  }

  Widget _buildHeader({String title = '', bool helpIcon = false}) {
    return Transform.translate(
      offset: const Offset(0, -7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.tituloClaro,
            textScaler: const TextScaler.linear(1.3), 
          ),
          helpIcon ? IconButton(
            onPressed: (){
              //TODO Dialog
            }, 
            icon: const Icon(Icons.help, color: AppTheme.letraClara,)
          ) : const SizedBox()
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: const Row(
              children: [
                Expanded(child: Center(child: Text('Vendedor'))),
                Expanded(child: Center(child: Text('Fecha'))),
                Expanded(child: Center(child: Text('Folio'))),
                Expanded(child: Center(child: Text('Cliente'))),
                Expanded(flex:2, child: Center(child: Text('Detalles'))),
                Expanded(child: Center(child: Text('Fecha Entrega'))),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: const Row(
              children: [
                Expanded(child: Center(child: Text('Estatus'))),
                Expanded(child: Center(child: Text('Fecha'))),
                Expanded(child: Center(child: Text('Folio'))),
                Expanded(child: Center(child: Text('Cliente'))),
                Expanded(flex:2, child: Center(child: Text('Detalles'))),
                Expanded(child: Center(child: Text('Fecha Entrega'))),
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
                color: pedidosSvc.pedidosReady.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: pedidosSvc.pedidosReady.length,
                  itemBuilder: (context, index) {
                    return FilaReady(pedido: pedidosSvc.pedidosReady[index], index: index);
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
                _buildTableSinPreparar(value), 
                const SizedBox(height: 15),
                _buildTablePedidos(value)
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
  late final fecha = DateFormat('E d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
  late final fechaEntrega = DateFormat('E d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
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
              PedidosDialog(pedido: widget.pedido, venta: venta!),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        color: widget.index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child:  Row(
          children: [
            Expanded(child: Center(child: Text(usuario, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(child: Center(child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex:2, 
              child: Center(
                child: detalleLoaded ? 
                  Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)
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
            Expanded(child: Center(child: Text(fechaEntrega, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
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
  late final fecha = DateFormat('E d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
  late final fechaEntrega = DateFormat('E d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final Ventas? venta;
  late final String detalles;
  bool detalleLoaded = false;
  late final Color color;

  obtenerEstadoParaColor(){
    switch (widget.pedido.estado) {
      case 'pendiente':
        color = Colors.red;
        break;
      case 'produccion':
        color = Colors.yellow;
        break;
      case 'terminado':
        color = Colors.green;
        break;
      case 'entregado':
        color = const Color.fromARGB(255, 0, 170, 255);
        break;
      default:
        color = Colors.red;
        break;
    }
  }

  void obtenerVenta() async{
    venta = await Provider.of<VentasServices>(context, listen: false).searchVenta(widget.pedido.ventaId);
    if (!mounted) return;
    detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(venta?.detalles??[]);
    setState(() { detalleLoaded = true; });
  }

  @override
  void initState() {
    super.initState();
    obtenerEstadoParaColor();
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
              PedidosDialog(pedido: widget.pedido, venta: venta!),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        color: widget.index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  foquito(color),
                  Text(capitalizarPrimeraLetra(widget.pedido.estado), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center),
                ],
              )
            ),
            Expanded(child: Center(child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
            Expanded(flex:2, 
              child: Center(
                child: detalleLoaded ? 
                  Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)
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
            Expanded(child: Center(child: Text(fechaEntrega, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
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