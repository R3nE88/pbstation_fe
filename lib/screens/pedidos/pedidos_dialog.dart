import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/search_fields_estaticos.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_subir_archivo_form.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class PedidosDialog extends StatefulWidget {
  const PedidosDialog({super.key, required this.pedido, required this.ventaId});

  final Pedidos pedido;
  final String ventaId;

  @override
  State<PedidosDialog> createState() => _PedidosDialogState();
}

class _PedidosDialogState extends State<PedidosDialog> {
  late final String fecha = DateFormat('EEE dd-MMM-yy hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
  late final String entrega = DateFormat('EEE dd-MMM-yy hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
  late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
  late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
  late final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(widget.pedido.sucursalId);
  late Color color = widget.pedido.estado.color;

  void descargarArchivo(String id, String archivo) async{
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    File? file = await pedidosService.descargarArchivoIndividual(
      pedidoId: id,
      nombreArchivo: archivo,
      context: context,
    );
    if (file!=null){
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Archivos descargados en:\n${file.path}'),
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
              Process.run('explorer', [file.parent.path]);
            },
          ),
        ),
      );
    }
  }
  
  void marcarComoEntregado(Ventas venta) async{
    //Solo si tiene pedido pendiente
    if (venta.pedidoPendiente){
      final pedidosSvc = Provider.of<PedidosService>(context, listen: false);

      //Solo con pedidos ya en sucursal, si no esta marcado como en sucursal, se puede forzar con admin password???
      /*if (widget.pedido.estado!=Estado.enSucursal){return;}*/

      //Abrir dialogo y preguntar si entregar
      final bool? continuar = await showDialog(
        context: context, 
        builder: (context) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              AlertDialog(
                backgroundColor: AppTheme.containerColor2,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('¿Le entregaste el pedido al cliente?\n', style: AppTheme.subtituloPrimario, textScaler: TextScaler.linear(1.15), textAlign: TextAlign.center),
                    Row(
                      //mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: ()=>Navigator.pop(context, false), 
                          child: const Text('No')
                        ),
                        ElevatedButton(
                          onPressed: ()=>Navigator.pop(context, true), 
                          child: const Text('Si')
                        )
                      ],
                    )
                  ],
                ),
              ),
              const WindowBar(overlay: true),
            ],
          );
        },
      ).then((value)=>value==null?value=false:value=value);

      if (continuar==true){
        //Cambiar estado de pedido a entregado y actualizar venta con pedidoPendiente = false;
        if (!mounted) return;
        final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
        loadingSvc.show();   
        
        await Provider.of<VentasServices>(context, listen: false).marcarVentasEntregadasPorFolio(venta.folio!);
        venta.pedidoPendiente = false;
        await pedidosSvc.actualizarEstadoPedido(pedidoId: widget.pedido.id!, estado: 'entregado');

        loadingSvc.hide();

        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  void pagarDeuda(Ventas venta){
    SearchFieldStatics.adeudoSearchText=venta.folio??'';
    final modProv = context.read<ModulosProvider>();
    modProv.navegarA(modulo: 'venta', subModulo: 'adeudos');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.containerColor1,
      content: Selector2<PedidosService, VentasServices, _DialogData>(
        selector: (context, pedidosService, ventasServices) {
          final venta = ventasServices.ventasDePedidos.firstWhere(
            (element) => element.id == widget.ventaId
          );
          
          return _DialogData(
            isDownloading: pedidosService.isDownloading,
            downloadProgress: pedidosService.downloadProgress,
            venta: venta,
          );
        },
        shouldRebuild: (previous, next) {
          // Solo reconstruir si cambió algo relevante
          if (previous.isDownloading != next.isDownloading) return true;
          if (previous.downloadProgress != next.downloadProgress) return true;
          
          // Comparar ventas
          if (previous.venta == null && next.venta == null) return false;
          if (previous.venta == null || next.venta == null) return true;
          
          // Solo reconstruir si cambian propiedades importantes de LA venta
          return previous.venta!.folio != next.venta!.folio ||
                previous.venta!.total != next.venta!.total ||
                previous.venta!.liquidado != next.venta!.liquidado ||
                previous.venta!.abonadoTotal != next.venta!.abonadoTotal ||
                previous.venta!.cancelado != next.venta!.cancelado ||
                previous.venta!.detalles.length != next.venta!.detalles.length;
        },
        builder: (context, data, child) {
          if (data.venta == null) {
            return const SizedBox(
              width: 400,
              child: Center(child: Text('Venta no encontrada')),
            );
          }

          final venta = data.venta!;

          return SizedBox(
            width: data.isDownloading ? 400 : 700,
            child: data.isDownloading ? 
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Descargando...'),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: LinearProgressIndicator(
                    color: AppTheme.containerColor1.withAlpha(150),
                    value: data.downloadProgress,
                    minHeight: 10,
                  ),
                ),
              ]
            )
            :
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [

                const Separador(texto: 'Venta'),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Folio de venta: ', style: AppTheme.labelStyle),
                        SelectableText(venta.folio??'', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.3)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Fecha: ', style: AppTheme.labelStyle),
                        Text(fecha, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.1)),
                      ],
                    ),
                  ],
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Vendedor: ', style: AppTheme.labelStyle),
                        Text(usuario, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Pagado: ', style: AppTheme.labelStyle),
                        Text(
                          venta.liquidado ?
                          Formatos.pesos.format(venta.total.toDouble())
                          :
                          Formatos.pesos.format(venta.abonadoTotal.toDouble()), 
                          style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)
                        ),
                      ],
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Cliente: ', style: AppTheme.labelStyle),
                        Text(cliente, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)),
                      ],
                    ),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Venta: ', style: AppTheme.labelStyle),
                        Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)),
                      ],
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Sucursal: ', style: AppTheme.labelStyle),
                        Text(sucursal, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)),
                      ],
                    ),

                    venta.liquidado ? 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.isDarkTheme ? Colors.transparent : const Color.fromARGB(226, 255, 255, 255),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text('Venta liquidada.', style: AppTheme.goodStyle, textScaler: const TextScaler.linear(1.15))
                        ),
                      ],
                    )
                    :
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Restante por pagar: ', style: AppTheme.labelStyle),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.isDarkTheme ? Colors.transparent : const Color.fromARGB(226, 255, 255, 255),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(Formatos.pesos.format(venta.total.toDouble() - venta.abonadoTotal.toDouble()), style:AppTheme.warningStyle2, textScaler: const TextScaler.linear(1.15))
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Separador(texto: 'Pedido'),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Folio de pedido: ', style: AppTheme.labelStyle),
                        SelectableText(widget.pedido.folio??'', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.3)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('   Entrega: ', style: AppTheme.labelStyle),
                        Text(entrega, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.1)),
                      ],
                    )
                  ],
                ),
            
                Row( 
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Estado: ', style: AppTheme.labelStyle),
                        widget.pedido.estado == Estado.enSucursal ?
                          const Text('en sucursal ', style: AppTheme.tituloPrimario, textScaler: TextScaler.linear(1.3))
                        : Text('${widget.pedido.estado.name} ', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.3)),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(25)
                          ),
                        )
                      ],
                    ),
                  ],
                ), const SizedBox(height: 10),

                _buildTabla(venta),

                const SizedBox(height: 10),

                widget.pedido.archivos.isNotEmpty
                ? Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text('Archivos: ', style: AppTheme.labelStyle),
                    for (var i = 0; i < widget.pedido.archivos.length; i++)
                      i == widget.pedido.archivos.length - 1
                        ? Tooltip(
                          message: 'descargar',
                          showDuration: const Duration(seconds: 1),
                          child: FeedBackButton(
                            onlyVertical: true,
                            onPressed: () => descargarArchivo(widget.pedido.id!, widget.pedido.archivos[i].nombre),
                            child: Text(widget.pedido.archivos[i].nombre, style: AppTheme.tituloPrimario)
                          ),
                        )
                        : Wrap(
                          children: [
                            Tooltip(
                              message: 'descargar',
                              showDuration: const Duration(seconds: 1),
                              child: FeedBackButton(
                                onlyVertical: true,
                                onPressed: () => descargarArchivo(widget.pedido.id!, widget.pedido.archivos[i].nombre),
                                child: Text(widget.pedido.archivos[i].nombre, style: AppTheme.tituloPrimario)
                              ),
                            ),
                            const Text(',  '),
                          ],
                        )
                  ],
                )
                : ElevatedButtonIcon(
                  onPressed: (){
                    if(!context.mounted){ return; }
                    showDialog(
                      context: context,
                      builder: (_) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          PedidosSubirArchivoForm(pedidoId: widget.pedido.id!),
                          const WindowBar(overlay: true),
                        ],
                      ),
                    );
                  }, 
                  icon: Icons.upload,
                  text: 'Subir archivos y mandar a produccion',
                ),

                if (widget.pedido.archivos.isNotEmpty)
                  if (venta.liquidado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Transform.translate(
                            offset: const Offset(0, 7),
                            child: ElevatedButton(
                              onPressed: ()=>marcarComoEntregado(venta),
                              child: Row(
                                children: [
                                  const Text('Entregar a cliente'),
                                  Transform.translate(
                                    offset: const Offset(5, 1.5),
                                    child: const Icon(Icons.send)
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                  if (Login.usuarioLogeado.rol==TipoUsuario.vendedor && !venta.liquidado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Transform.translate(
                            offset: const Offset(0, 7),
                            child: ElevatedButton(
                              onPressed: ()=>pagarDeuda(venta),
                              child: Row(
                                children: [
                                  const Text('Pagar y entregar a cliente'),
                                  Transform.translate(
                                    offset: const Offset(5, 1.5),
                                    child: const Icon(Icons.send)
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabla(Ventas venta){
    return SizedBox(
      height: 130,
      child: Column(
        children: [
          
          //Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )
            ),
            child: const Row(
              children: [
                Flexible(flex: 2, child: Center(child: Text('Cant.'))),
                Flexible(flex: 5, child: Center(child: Text('Articulo'))),
                Flexible(flex: 5, child: Center(child: Text('Comentario'))),
              ],
            ),
          ),

          //Body
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadiusGeometry.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: Container(
                color: venta.detalles.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: venta.detalles.length,
                  itemBuilder: (context, index) {
                    return FilaDetalles(detalle: venta.detalles[index], index: index,);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilaDetalles extends StatelessWidget {
  const FilaDetalles({super.key, required this.index, required this.detalle});
  
  final DetallesVenta detalle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final producto = Provider.of<ProductosServices>(context, listen: false).obtenerProductoPorId(detalle.productoId);
    String? medida;
    if (detalle.alto!=null && detalle.ancho!=null){
      medida = '${detalle.ancho.toString()}m x ${detalle.alto.toString()}m';
    }
    String productoDescripcion = producto?.descripcion??'problema al obtener producto...';
    if (medida!=null){
      productoDescripcion += ' ($medida)';
    }


    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: index%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        )
      ),
      child: Row(
        children: [
          Flexible(flex: 2, child: Center(child: Text(detalle.cantidad.toString(), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
          Flexible(flex: 5, child: Center(child: Text(productoDescripcion, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
          Flexible(flex: 5, child: Center(child: Text(detalle.comentarios??'-', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center))),
        ],
      ),
    );
  }
}

// Clase helper para los datos del selector
class _DialogData {
  final bool isDownloading;
  final double downloadProgress;
  final Ventas? venta;

  _DialogData({
    required this.isDownloading,
    required this.downloadProgress,
    required this.venta,
  });
}