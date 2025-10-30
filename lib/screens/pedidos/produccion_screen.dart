import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_dialog.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  String _valorSeleccionado = 'Todas las fechas';
  List<String> opciones = [
    'Todas las fechas',
    'Entrega para hoy'
  ];
  
  Estado selected = Estado.pendiente;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produccion',
                style: AppTheme.tituloClaro,
                textScaler: TextScaler.linear(1.7),
              ),
              Text('Pedidos por entregar [hoy|0] [semana|0] [mes|0]')
            ],
          ), const SizedBox(height: 15),

          //Pestañas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              //Organizar por fechas
              selected != Estado.terminado ? 
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                    height: 38,
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
                      child: DropdownButton<String>(
                        focusNode: _focusNode,
                        value: _valorSeleccionado,
                        
                        items: opciones.map((opcion) {          // OJO: usa map(), no list()
                          return DropdownMenuItem<String>(      // AQUÍ era el error
                            value: opcion,
                            child: Text(opcion),
                          );
                        }).toList(),
                        dropdownColor: AppTheme.containerColor2,
                        style: const TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
                        iconEnabledColor: Colors.white,
                        onChanged: (nuevo) {
                          if (nuevo == null) return;
                          setState(() {
                            _valorSeleccionado = nuevo;
                            _focusNode.unfocus();
                          });
                        },
                      ),
                    ),
                  ),
                )
              : const SizedBox(),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PestaniaStatus(selected: selected==Estado.pendiente, estado: Estado.pendiente, onPressed: (){
                    setState(() {selected=Estado.pendiente;});
                  }),
                  PestaniaStatus(selected: selected==Estado.produccion, estado: Estado.produccion, onPressed: (){
                    setState(() {selected=Estado.produccion;});
                  }),
                  PestaniaStatus(selected: selected==Estado.terminado, estado: Estado.terminado, onPressed: (){
                    setState(() {
                      selected=Estado.terminado; 
                    });
                  }),
                ],
              ),
            ],
          ),

          //Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Center(child: Text('Fecha Pedido'))),
                Expanded(flex: 2, child: Center(child: Text('Folio'))),
                Expanded(flex: 3, child: Center(child: Text('Sucursal'))),
                Expanded(flex: 3, child: Center(child: Text('Cliente'))),
                Expanded(flex: 3, child: Center(child: Text('Detalles'))),
                Expanded(flex: 3, child: Center(child: Text('Descripcion'))),
                Expanded(flex: 2, child: Center(child: Text('Fecha Entrega'))),
              ],
            ),
          ),

          //body
          Consumer<PedidosService>(
            builder: (context, pedidosSvc, child) {
              // helper local para comparar solo día/mes/año
              bool isSameDay(DateTime a, DateTime b) =>
                  a.year == b.year && a.month == b.month && a.day == b.day;

              final today = DateTime.now();

              List<Pedidos> pedidos = pedidosSvc.pedidosReady
                // 1) primero filtro por estado
                .where((p) => p.estado == selected)
                // 2) luego filtro por la opción del dropdown
                .where((p) {
                  if (_valorSeleccionado == 'Entrega para hoy') {
                    final entrega = DateTime.tryParse(p.fechaEntrega);
                    if (entrega == null) return false; // si no tiene fecha, lo excluimos
                    return isSameDay(entrega.toLocal(), today);
                  }
                  // 'Todas las fechas' -> no filtrar por fechaEntrega
                  return true;
                })
                .toList();

              // 3) ordenar por fechaEntrega y si empatan por fecha (creación)
              pedidos.sort((a, b) {
                final aEntrega = DateTime.tryParse(a.fechaEntrega)?.toLocal();
                final bEntrega = DateTime.tryParse(b.fechaEntrega)?.toLocal();

                // si alguna fechaEntrega es nula la tratamos como "más al final"
                if (aEntrega == null && bEntrega == null) {
                  // comparar por fecha creación
                  final aFecha = DateTime.tryParse(a.fecha)?.toLocal();
                  final bFecha = DateTime.tryParse(b.fecha)?.toLocal();
                  if (aFecha == null || bFecha == null) return 0;
                  return aFecha.compareTo(bFecha);
                } else if (aEntrega == null) {
                  return 1;
                } else if (bEntrega == null) {
                  return -1;
                }

                final cmpEntrega = aEntrega.compareTo(bEntrega);
                if (cmpEntrega != 0) return cmpEntrega;

                // empate en fechaEntrega -> ordenar por fecha creación
                final aFecha = DateTime.tryParse(a.fecha)?.toLocal();
                final bFecha = DateTime.tryParse(b.fecha)?.toLocal();
                if (aFecha == null || bFecha == null) return 0;
                return aFecha.compareTo(bFecha);
              });

              return Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)
                  ),
                  child: Container(
                    color: pedidos.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                    child: ListView.builder(
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        return FilaPedidos(index: index, pedido: pedidos[index]);
                      },
                    ),
                  ),
                ),
              );
            },
          )   
        ],
      )
    );
  }
}

class PestaniaStatus extends StatelessWidget {
  const PestaniaStatus({
    super.key, 
    required this.selected, 
    required this.estado, 
    required this.onPressed,
  });

  final bool selected;
  final Estado estado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: FeedBackButton(
        valor: 1.025,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.tablaColorHeaderSelected : AppTheme.tablaColorHeader,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: const Border(bottom: BorderSide(color: Color.fromARGB(22, 0, 0, 0), width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list, color: estado.color),
              estado.name=='produccion' ?
                Text('  Pedidos en ${estado.name}')
              : Text('  Pedidos ${estado.name}s'),
            ],
          ),
        ),
      ),
    );
  }
}

class FilaPedidos extends StatefulWidget {
  const FilaPedidos({super.key, required this.index, required this.pedido});

  final int index;
  final Pedidos pedido;

  @override
  State<FilaPedidos> createState() => _FilaPedidosState();
}

class _FilaPedidosState extends State<FilaPedidos> {
  late final fecha = DateFormat('d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
  late final fechaDia = DateFormat('EEEE', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
  late final fechaEntrega = DateFormat('d MMM hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
  late final fechaEntregaDia = DateFormat('EEEE', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.pedido.sucursalId);
  late final Ventas? venta;
  late final String detalles;
  bool detalleLoaded = false;
  String promover = '';

  void obtenerVenta() async{
    venta = await Provider.of<VentasServices>(context, listen: false).searchVenta(widget.pedido.ventaId);
    if (!mounted) return;
    detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(venta?.detalles??[]);
    setState(() { detalleLoaded = true; });
  }

  void promoverPedido(BuildContext context) async {
    Loading.displaySpinLoading(context);
    await Provider.of<PedidosService>(context, listen: false).actualizarEstadoPedido(pedidoId: widget.pedido.id!, estado: promover);
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  void mostrarMenu(BuildContext context, Offset offset) async {
    final String? seleccion;

    seleccion = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
      ),
      color: AppTheme.dropDownColor,
      elevation: 2,
      items: [
        PopupMenuItem(
          value: 'promover',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.send, color: AppTheme.letraClara, size: 17),
              promover=='enSucursal' ?
                const Text('  Enviar a sucursal', style: AppTheme.subtituloPrimario)
              : Text('  Enviar a $promover', style: AppTheme.subtituloPrimario),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'descargar',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, color: AppTheme.letraClara, size: 17),
              Text('  Descargar Archivos', style: AppTheme.subtituloPrimario),
            ],
          ),
        ),
      ],
    );
    

    if (seleccion != null) {
      if (seleccion == 'promover') {
        if (!context.mounted) return;
        promoverPedido(context);
      } else if (seleccion == 'descargar') {
        if (!context.mounted)return;
        showDialog(
          context: context, 
          builder: ( _ ) => Stack(
            alignment: Alignment.topRight,
            children: [
              DescargaDialog(pedidoId: widget.pedido.id!),
              const WindowBar(overlay: true),
            ],
          )
        );
      }
    }
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
    switch (widget.pedido.estado) {
      case Estado.pendiente: 
        promover = 'produccion';
        break;
      case Estado.produccion:
        promover = 'terminado';
        break;
      case Estado.terminado:
        promover = 'enSucursal';
        break;
      default:
    }

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
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          mostrarMenu(context, details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          color: widget.index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
          child: Row(
            children: [
              Expanded(flex: 2, child: Center(child: Text('$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
              Expanded(flex: 2, child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.95)))),
              Expanded(flex: 3, child: Center(child: Text(sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
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
              Expanded(flex: 3, child: Center(child: Text(widget.pedido.descripcion?.replaceAll('&&', ' - ') ?? '', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
              Expanded(flex: 2, child: Center(child: Text('$fechaEntregaDia\n$fechaEntrega', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
            ],
          ),
        ),
      ),
    );
  }
}

class DescargaDialog extends StatefulWidget {
  const DescargaDialog({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<DescargaDialog> createState() => _DescargaDialogState();
}

class _DescargaDialogState extends State<DescargaDialog> {

  void descargar() async{
    if (!context.mounted)return;
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    final archivo = await pedidosService.descargarArchivosZIP(
      pedidoId: widget.pedidoId,
      context: context,
    );
    if (!mounted)return;
    Navigator.pop(context);
    if (archivo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Archivos descargados en:\n${archivo.path}'),
          duration: const Duration(seconds: 5),
          backgroundColor: AppTheme.secundario2,
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height/2,
            left: 20,
            right: 20,
          ),
          action: SnackBarAction(
            label: 'Abrir carpeta',
            onPressed: () {
              Process.run('explorer', [archivo.parent.path]);
            },
          ),
        ),
      );
    } else {
      if (!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('❌ Error al descargar archivos')),
          duration: const Duration(seconds: 5),
          backgroundColor: AppTheme.colorError2.withAlpha(200),
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(vertical: 20),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height/2,
            left: 20,
            right: 20,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    descargar();
  }

  @override
  Widget build(BuildContext context) {
    final pedidosService = Provider.of<PedidosService>(context);

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Descargando archivos...'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: pedidosService.downloadProgress,
                minHeight: 10,
              ),
            ),
            Text(
              '${(pedidosService.downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}