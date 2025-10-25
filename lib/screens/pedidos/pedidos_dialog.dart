import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/pedidos/pedidos_subir_archivo_form.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class PedidosDialog extends StatefulWidget {
  const PedidosDialog({super.key, required this.pedido, required this.venta});

  final Pedidos pedido;
  final Ventas venta;

  @override
  State<PedidosDialog> createState() => _PedidosDialogState();
}

class _PedidosDialogState extends State<PedidosDialog> {
    late final String fecha = DateFormat('EEE dd-MMM-yy hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fecha));
    late final String entrega = DateFormat('EEE dd-MMM-yy hh:mm a', 'es_MX').format(DateTime.parse(widget.pedido.fechaEntrega));
    late final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(widget.pedido.usuarioId);
    late final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(widget.pedido.clienteId);
    late final Color color;

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
            backgroundColor: AppTheme.secundario2,
            padding: const EdgeInsets.only(right: 50, left: 80, top: 15, bottom: 20),
            content: Text('✅ Archivos descargados en:\n${file.path}'),
            action: SnackBarAction(
              label: 'Abrir carpeta',
              onPressed: () {
                Process.run('explorer', [file.parent.path]);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

  @override
  void initState() {
    super.initState();
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
        color = Colors.orange;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidosService = Provider.of<PedidosService>(context);

    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      content: SizedBox(
        width: pedidosService.isDownloading ? 400 : 700,
        child: pedidosService.isDownloading ? 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Descargando...'),
            Padding(
              padding: const EdgeInsets.all(6),
              child: LinearProgressIndicator(
                color: AppTheme.containerColor1.withAlpha(150),
                value: pedidosService.downloadProgress,
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
                    SelectableText(widget.venta.folio??'', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.3)),
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
                      widget.venta.liquidado ?
                      Formatos.pesos.format(widget.venta.total.toDouble())
                      :
                      Formatos.pesos.format(widget.venta.abonadoTotal.toDouble()), 
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
                    Text(Formatos.pesos.format(widget.venta.total.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.15)),
                  ],
                ),
              ],
            ),

            widget.venta.liquidado ? 
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venta liquidada.', style: AppTheme.goodStyle, textScaler: const TextScaler.linear(1.15)),
              ],
            )
            :
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restante por pagar: ', style: AppTheme.labelStyle),
                Text(Formatos.pesos.format(widget.venta.total.toDouble() - widget.venta.abonadoTotal.toDouble()), style:AppTheme.warningStyle, textScaler: const TextScaler.linear(1.15)),
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
                    Text('${widget.pedido.estado} ', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.3)),
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

            _buildTabla(),

            /*(widget.pedido.descripcion ?? '').isNotEmpty
            ? Wrap (
              children: [
                const Text('Comentarios: ', style: AppTheme.labelStyle),
                for (var i = 0; i < widget.venta.detalles.length; i++)
                  if (widget.venta.detalles[i].comentarios!=null)
                    i == widget.venta.detalles.length - 1
                      ? Text(widget.venta.detalles[i].comentarios!, style: AppTheme.tituloPrimario)
                      : Wrap(
                        children: [
                          Text(widget.venta.detalles[i].comentarios!, style: AppTheme.tituloPrimario),
                          const Text(',  '),
                        ],
                      )
              ],
            )
            : const Text('Sin comentarios', style: AppTheme.labelStyle),*/

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
            )

          ],
        ),
      ),
    );
  }

  Widget _buildTabla(){
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
                color: widget.venta.detalles.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: widget.venta.detalles.length,
                  itemBuilder: (context, index) {
                    return FilaDetalles(detalle: widget.venta.detalles[index], index: index,);
                  },
                ),
              ),
            ),
          )
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
          Flexible(flex: 2, child: Center(child: Text(detalle.cantidad.toString(), style: AppTheme.subtituloConstraste))),
          Flexible(flex: 5, child: Center(child: Text(productoDescripcion, style: AppTheme.subtituloConstraste))),
          Flexible(flex: 5, child: Center(child: Text(detalle.comentarios??'-', style: AppTheme.subtituloConstraste))),
        ],
      ),
    );
  }
}