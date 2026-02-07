import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
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
  final Color color = AppTheme.isDarkTheme ? const Color.fromARGB(255, 135, 206, 137) : const Color.fromARGB(255, 140, 255, 142);
  String _valorSeleccionado = 'Todas las fechas';
  List<String> opciones = [
    'Todas las fechas',
    'Entrega para hoy'
  ];
  
  Estado selected = Estado.pendiente;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // Estado para selección múltiple
  final Set<String> _pedidosSeleccionados = {};

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

  void _toggleSeleccion(String pedidoId, bool isCtrlPressed) {
    setState(() {
      if (isCtrlPressed) {
        // Multi-selección con Ctrl
        if (_pedidosSeleccionados.contains(pedidoId)) {
          _pedidosSeleccionados.remove(pedidoId);
        } else {
          _pedidosSeleccionados.add(pedidoId);
        }
      } else {
        // Selección simple (limpia otras)
        _pedidosSeleccionados.clear();
        _pedidosSeleccionados.add(pedidoId);
      }
    });
  }

  void _limpiarSeleccion() {
    setState(() => _pedidosSeleccionados.clear());
  }

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      child: Consumer<PedidosService>(
        builder: (context, pedidosSvc, child) {
          // --- Cálculos para ContadorDePedidos ---
          final pedidos = pedidosSvc.pedidosReady;
          final hoy = DateTime.now();

          bool mismoDia(DateTime a, DateTime b) =>
              a.year == b.year && a.month == b.month && a.day == b.day;

          int pedidosHoy = pedidos.where((p) {
            final fecha = DateTime.tryParse(p.fechaEntrega)?.toLocal();
            return fecha != null && mismoDia(fecha, hoy);
          }).length;

          int pedidosSemana = pedidos.where((p) {
            final fecha = DateTime.tryParse(p.fechaEntrega)?.toLocal();
            if (fecha == null) return false;
            final diferencia = hoy.difference(fecha).inDays;
            return diferencia >= 0 && diferencia < 7;
          }).length;

          int pedidosMes = pedidos.where((p) {
            final fecha = DateTime.tryParse(p.fechaEntrega)?.toLocal();
            return fecha != null &&
                fecha.year == hoy.year &&
                fecha.month == hoy.month;
          }).length;

          // --- Filtro por pestaña y fecha seleccionada ---
          List<Pedidos> pedidosFiltrados = pedidos
              .where((p) => p.estado == selected)
              .where((p) {
                if (_valorSeleccionado == 'Entrega para hoy') {
                  final entrega = DateTime.tryParse(p.fechaEntrega);
                  if (entrega == null) return false;
                  return mismoDia(entrega.toLocal(), hoy);
                }
                return true;
              })
              .toList();

          // --- Ordenar por fecha entrega y pedido ---
          pedidosFiltrados.sort((a, b) {
            final aEntrega = DateTime.tryParse(a.fechaEntrega)?.toLocal();
            final bEntrega = DateTime.tryParse(b.fechaEntrega)?.toLocal();

            if (aEntrega == null && bEntrega == null) {
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

            final aFecha = DateTime.tryParse(a.fecha)?.toLocal();
            final bFecha = DateTime.tryParse(b.fecha)?.toLocal();
            if (aFecha == null || bFecha == null) return 0;
            return aFecha.compareTo(bFecha);
          });

          // --- UI ---
          return Column(
            children: [
              // --- Título + Contador ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Producción   ',
                        style: AppTheme.tituloClaro,
                        textScaler: TextScaler.linear(1.7),
                      ),

                      if (_pedidosSeleccionados.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${_pedidosSeleccionados.length} seleccionado${_pedidosSeleccionados.length > 1 ? "s" : ""}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FeedBackButton(
                                onPressed: _limpiarSeleccion,
                                child: Icon(Icons.close, color: color, size: 18),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // --- Ahora el contador dinámico ---
                  ContadorDePedidos(
                    dia: pedidosHoy,
                    semana: pedidosSemana,
                    mes: pedidosMes,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // --- Pestañas y filtros ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (selected != Estado.terminado)
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isFocused
                              ? AppTheme.tablaColorHeader.withAlpha(200)
                              : AppTheme.tablaColorHeader,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          border: const Border(
                              bottom: BorderSide(color: Colors.black12, width: 3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            focusNode: _focusNode,
                            value: _valorSeleccionado,
                            items: opciones.map((opcion) {
                              return DropdownMenuItem<String>(
                                value: opcion,
                                child: Text(opcion),
                              );
                            }).toList(),
                            dropdownColor: AppTheme.containerColor2,
                            style: const TextStyle(
                                color: AppTheme.letraClara, fontWeight: FontWeight.w500),
                            iconEnabledColor: Colors.white,
                            onChanged: (nuevo) {
                              if (nuevo == null) return;
                              setState(() {
                                _valorSeleccionado = nuevo;
                                _focusNode.unfocus();
                                _pedidosSeleccionados.clear();
                              });
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PestaniaStatus(
                        selected: selected == Estado.pendiente,
                        estado: Estado.pendiente,
                        onPressed: () {
                          setState(() {
                            selected = Estado.pendiente;
                            _pedidosSeleccionados.clear();
                          });
                        },
                      ),
                      PestaniaStatus(
                        selected: selected == Estado.produccion,
                        estado: Estado.produccion,
                        onPressed: () {
                          setState(() {
                            selected = Estado.produccion;
                            _pedidosSeleccionados.clear();
                          });
                        },
                      ),
                      PestaniaStatus(
                        selected: selected == Estado.terminado,
                        estado: Estado.terminado,
                        onPressed: () {
                          setState(() {
                            selected = Estado.terminado;
                            _pedidosSeleccionados.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // --- Encabezado de tabla ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.tablaColorHeader,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Center(child: Text('Fecha Pedido'))),
                    Expanded(flex: 2, child: Center(child: Text('Folio'))),
                    Expanded(flex: 3, child: Center(child: Text('Sucursal'))),
                    Expanded(flex: 3, child: Center(child: Text('Cliente'))),
                    Expanded(flex: 3, child: Center(child: Text('Detalles'))),
                    Expanded(flex: 3, child: Center(child: Text('Descripción'))),
                    Expanded(flex: 2, child: Center(child: Text('Fecha Entrega'))),
                  ],
                ),
              ),

              // --- Lista de pedidos ---
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                  child: Container(
                    color: pedidosFiltrados.length % 2 == 0
                        ? AppTheme.tablaColor1
                        : AppTheme.tablaColor2,
                    child: ListView.builder(
                      itemCount: pedidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidosFiltrados[index];
                        return FilaPedidos(
                          key: ValueKey(pedido.id),
                          index: index,
                          pedido: pedido,
                          estaSeleccionado:
                              _pedidosSeleccionados.contains(pedido.id),
                          onSeleccionCambiada: _toggleSeleccion,
                          pedidosSeleccionados: _pedidosSeleccionados,
                          onLimpiarSeleccion: _limpiarSeleccion,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
  const FilaPedidos({
    super.key,
    required this.index,
    required this.pedido,
    required this.estaSeleccionado,
    required this.onSeleccionCambiada,
    required this.pedidosSeleccionados,
    required this.onLimpiarSeleccion,
  });

  final int index;
  final Pedidos pedido;
  final bool estaSeleccionado;
  final Function(String, bool) onSeleccionCambiada;
  final Set<String> pedidosSeleccionados;
  final VoidCallback onLimpiarSeleccion;

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
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();
    await Provider.of<PedidosService>(context, listen: false).actualizarEstadoPedido(pedidoId: widget.pedido.id!, estado: promover);
    loadingSvc.hide();
  }

  void promoverPedidosMultiples(BuildContext context) async {
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();          
    
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    
    // Promover todos los seleccionados
    for (String pedidoId in widget.pedidosSeleccionados) {
      await pedidosService.actualizarEstadoPedido(
        pedidoId: pedidoId, 
        estado: promover
      );
    }
    
    widget.onLimpiarSeleccion();
    loadingSvc.hide();
  }

  void mostrarMenu(BuildContext context, Offset offset) async {
    final int cantidadSeleccionados = widget.pedidosSeleccionados.length;
    final bool esMultiple = cantidadSeleccionados > 1;
    
    final String? seleccion = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
      ),
      color: AppTheme.dropDownColor,
      elevation: 4,
      shadowColor: Colors.black,
      items: [
        PopupMenuItem(
          value: 'promover',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.send, color: AppTheme.letraClara, size: 17),
              Text(
                esMultiple 
                  ? '  Enviar $cantidadSeleccionados pedido${cantidadSeleccionados > 1 ? "s" : ""} a $promover'
                  : promover == 'enSucursal'
                      ? '  Enviar a sucursal'
                      : '  Enviar a $promover',
                style: AppTheme.subtituloPrimario
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'descargar',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download, color: AppTheme.letraClara, size: 17),
              Text(
                esMultiple
                  ? '  Descargar archivos ($cantidadSeleccionados)'
                  : '  Descargar Archivos',
                style: AppTheme.subtituloPrimario
              ),
            ],
          ),
        ),
        if (esMultiple)
          const PopupMenuItem(
            value: 'limpiar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: AppTheme.letraClara, size: 17),
                Text('  Limpiar selección', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
      ],
    );
    
    if (seleccion != null) {
      if (seleccion == 'promover') {
        if (!context.mounted) return;
        if (widget.pedidosSeleccionados.length > 1) {
          promoverPedidosMultiples(context);
        } else {
          promoverPedido(context);
        }
      } else if (seleccion == 'descargar') {
        if (!context.mounted) return;
        if (esMultiple) {
          List<String> pedidos = [];
          for (String pedidoId in widget.pedidosSeleccionados) {
            pedidos.add(pedidoId);
          }
          showDialog(
              context: context, 
              builder: ( _ ) => Stack(
                alignment: Alignment.topRight,
                children: [
                  DescargaDialog(pedidosId: pedidos),
                  const WindowBar(overlay: true),
                ],
              )
            );
        } else {
          showDialog(
            context: context, 
            builder: ( _ ) => Stack(
              alignment: Alignment.topRight,
              children: [
                DescargaDialog(pedidosId: [widget.pedido.id!]),
                const WindowBar(overlay: true),
              ],
            )
          );
        }
      } else if (seleccion == 'limpiar') {
        widget.onLimpiarSeleccion();
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
      onPressed: () {
        // Detectar si Ctrl está presionado
        final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
        
        if (isCtrlPressed) {
          // Si Ctrl está presionado, solo seleccionar
          widget.onSeleccionCambiada(widget.pedido.id!, true);
        } else {
          // Si no hay Ctrl, abrir el diálogo normal
          if (venta == null) return;
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
        }
      },
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          // Si no está en la selección, agrégalo antes de mostrar el menú
          if (!widget.pedidosSeleccionados.contains(widget.pedido.id)) {
            widget.onSeleccionCambiada(widget.pedido.id!, false);
          }
          mostrarMenu(context, details.globalPosition);
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: widget.estaSeleccionado
                ? Colors.green.withValues(alpha: AppTheme.isDarkTheme ? 0.15 : 0.35)
                : Colors.transparent,
            ),
      
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Indicador visual de selección (barra verde a la izquierda)
                  if (widget.estaSeleccionado)
                    Container(
                      width: 5,
                      color: Colors.green,
                      margin: const EdgeInsets.only(right: 5),
                    ),
                  
                  Expanded(flex: 2, child: Center(child: Text('$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                  Expanded(flex: 2, child: Center(child: Text(widget.pedido.folio??'no pude obtener folio', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.95)))),
                  Expanded(flex: 3, child: Center(child: Text(sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                  Expanded(flex: 3, child: Center(child: Text(cliente, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                  Expanded(flex: 3, child: Center( child: Text(detalleLoaded ? detalles : '...', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                  Expanded(flex: 3, child: Center(child: Text(widget.pedido.descripcion?.replaceAll('&&', ' - ') ?? '', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                  Expanded(flex: 2, child: Center(child: Text('$fechaEntregaDia\n$fechaEntrega', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.85)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DescargaDialog extends StatefulWidget {
  const DescargaDialog({super.key, required this.pedidosId});

  final List<String> pedidosId;

  @override
  State<DescargaDialog> createState() => _DescargaDialogState();
}

class _DescargaDialogState extends State<DescargaDialog> {

  void descargar() async{
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    
    //Elegir el path
    pedidosService.downloadProgress = 0;
    pedidosService.isDownloading = false;
    Directory dirDestino;
    final loadingSvc = Provider.of<LoadingProvider>( context, listen: false );
    WidgetsBinding.instance.addPostFrameCallback((_) { loadingSvc.show(); });
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
      dialogTitle: 'Selecciona dónde guardar el archivo ZIP',
    ); loadingSvc.hide();
    if (selectedDirectory==null) {
      if (!mounted)return;
      Navigator.pop(context);
      return;
    }
    dirDestino = Directory(selectedDirectory);    
    
    for (String pedido in widget.pedidosId) {
      await pedidosService.descargarArchivosZIP(
        pedidoId: pedido,
        dirDestino: dirDestino
      );
    }

    if (!mounted)return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Archivos descargados en:\n$dirDestino'),
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
            Process.run('explorer', [dirDestino.path]);
          },
        ),
      ),
    );
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
      elevation: 6,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: AppTheme.borde,
      content: SizedBox(
        child: pedidosService.isDownloading ? 
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text( 'Descargando archivos...'),
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
          )
        : const SizedBox(height: 20),
      ),
    );
  }
}

class ContadorDePedidos extends StatelessWidget {
  const ContadorDePedidos({
    super.key, required this.dia, required this.semana, required this.mes,
  });

  final int dia;
  final int semana;
  final int mes;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.secundario1,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20)
              )
            ),
            child: const Center(child: Text('Pedidos para entregar')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.isDarkTheme ? AppTheme.primario2 : AppTheme.primario1,
              border: Border.symmetric(
                horizontal: BorderSide(color: AppTheme.secundario1, width: 2)
              )
            ),
            child: Center(child: Row(
              children: [
                const Text('HOY: ', style: AppTheme.labelStyle),
                Text('$dia', textScaler: const TextScaler.linear(1.2),),
              ],
            )),
          ), Container(width: 1, color: AppTheme.secundario1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.isDarkTheme ? AppTheme.primario2 : AppTheme.primario1,
              border: Border.symmetric(
                horizontal: BorderSide(color: AppTheme.secundario1, width: 2)
              )
            ),
            child: Center(child: Row(
              children: [
                const Text('SEMANA: ', style: AppTheme.labelStyle),
                Text('$semana', textScaler: const TextScaler.linear(1.2),),
              ],
            )),
          ), Container(width: 1, color: AppTheme.secundario1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.isDarkTheme ? AppTheme.primario2 : AppTheme.primario1,
              border: Border.symmetric(
                horizontal: BorderSide(color: AppTheme.secundario1, width: 2)
              ),
            ),
            child: Center(child: Row(
              children: [
                const Text('MES: ', style: AppTheme.labelStyle),
                Text('$mes', textScaler: const TextScaler.linear(1.2),),
              ],
            )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            width: 20,
            decoration: BoxDecoration(
              color: AppTheme.secundario1,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20)
              )
            ),
          ),
        ],
      ),
    );
  }
}
