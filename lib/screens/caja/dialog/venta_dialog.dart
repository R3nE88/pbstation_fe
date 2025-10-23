import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/ticket.dart';
import 'package:pbstation_frontend/logic/verificar_admin_psw.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/venta/procesar_pago.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class VentaDialog extends StatefulWidget {
  const VentaDialog({super.key, required this.venta, required this.tc, required this.isActive, required this.callback, this.fromDeudas = false});

  final Ventas venta;
  final double tc;
  final bool isActive;
  final Function() callback;
  final bool fromDeudas;

  @override
  State<VentaDialog> createState() => _VentaDialogState();
}

class _VentaDialogState extends State<VentaDialog> {
  late final double height;
  late final DateTime fecha = DateTime.parse(widget.venta.fechaVenta!);
  late final String fechaFormateada = DateFormat('EEEE dd-MMM-yyyy hh:mm a', 'es_MX').format(fecha).toUpperCase();
  late Decimal? monto = obtenerMontoPendiente(widget.venta.id!, context);
  double ntc = 0;

  @override
  void initState() {
    super.initState();    
    if (widget.venta.detalles.length > 8){
      height = 213;
    } else {
      height = (25 * widget.venta.detalles.length).toDouble();
    }

    datosIniciales();
  }

  void datosIniciales() async{
    if (widget.tc != 0){
      ntc = widget.tc;
    } else {
      ntc = await Provider.of<CajasServices>(context, listen: false).obtenerTCDeVenta(widget.venta.id!);
      setState(() {});
    }
  }

  Decimal? obtenerMontoPendiente(String ventaId, context) {
    final clientesService = Provider.of<ClientesServices>(context, listen: false);
    
    // Búsqueda temprana con return
    for (var cliente in clientesService.clientesConAdeudo) {
      for (var adeudo in cliente.adeudos) {
        if (adeudo.ventaId == ventaId) {
          return adeudo.montoPendiente;
        }
      }
    }
    return null; // No encontrado
  }

  @override
  Widget build(BuildContext context) {
    if (ntc == 0){
      return const SimpleLoading();
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.only(left: 18, right:18, top: 12),
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Venta: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.6)),
          Text(widget.venta.folio??'', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.7)),
          const Spacer(),
          Text(fechaFormateada, style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.6))
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      content: SizedBox(
        width: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          
            //Header info
            Transform.translate(
              offset: const Offset(0, -13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 6,
                    child: Wrap(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Vendedor: ', style: AppTheme.labelStyle),
                            Text(Provider.of<UsuariosServices>(context, listen:false).obtenerNombreUsuarioPorId(widget.venta.usuarioId), style: AppTheme.tituloPrimario)
                          ],
                        ), const SizedBox(width: 15),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Cliente: ', style: AppTheme.labelStyle),
                            Text(Provider.of<ClientesServices>(context, listen:false).obtenerNombreClientePorId(widget.venta.clienteId), style: AppTheme.tituloPrimario)
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.venta.liquidado ?  
                        const Text( 'Venta pagada', style: AppTheme.labelStyle)
                        : 
                        const Text( 'Venta con deuda', style: AppTheme.warningStyle),
                      ],
                    ),
                  )
                ],
              ),
            ),

            widget.venta.detalles.length == 1 ? const Separador(texto: 'Detalles (1 articulo)')
            : Separador(texto: 'Detalles (${widget.venta.detalles.length} articulos)'),

            //Hedaer table
            Container(
              color: AppTheme.tablaColorHeader,
              child: const Row(
                children: [
                  Expanded(child: Center(child: Text('Cant.'))),
                  Expanded(flex: 3, child: Center(child: Text('Articulo'))),
                  Expanded(flex: 3, child: Center(child: Text('Comentarios'))),
                  Expanded(flex: 2, child: Center(child: Text('Descuento'))),
                  Expanded(flex: 2, child: Center(child: Text('SubTotal'))),
                  Expanded(flex: 2, child: Center(child: Text('IVA'))),
                  Expanded(flex: 2, child: Center(child: Text('Total'))),
                ],
              ),
            ),

            //bodye table
            Container(
              height: height,
              width: double.infinity,
              color: widget.venta.detalles.length%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
              child: ListView.builder(
                itemCount: widget.venta.detalles.length,
                itemBuilder: (context, index) {
                  return FilaDetalles(detalle: widget.venta.detalles[index], color: index);
                }, 
              ),
            ),
            
            //Total 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('SubTotal: ', style: AppTheme.labelStyle),
                      Text(Formatos.pesos.format(widget.venta.subTotal.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                    ],
                  ), const SizedBox(width: 15),
                  Row(
                    children: [
                      const Text('Descuento: ', style: AppTheme.labelStyle),
                      Text(Formatos.pesos.format(widget.venta.descuento.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                    ],
                  ), const SizedBox(width: 15),
                  Row(
                    children: [
                      const Text('Iva: ', style: AppTheme.labelStyle),
                      Text(Formatos.pesos.format(widget.venta.iva.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                    ],
                  ), const SizedBox(width: 15),
                  Row(
                    children: [
                      const Text('Total: ', style: AppTheme.labelStyle),
                      Text(Formatos.pesos.format(widget.venta.total.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                    ],
                  ), const SizedBox(width: 15),
                ],
              ),
            ),

            const Separador(),

            //Datos del pago
            !widget.venta.cancelado ?
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.venta.comentariosVenta!= null ? Wrap(
                        children: [
                          const Text('Comentario de venta: ', style: AppTheme.labelStyle),
                          Text(widget.venta.comentariosVenta!, style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.1))
                        ],
                      ) : const SizedBox(), 
                      const SizedBox(width: 15),

                      widget.fromDeudas ? const SizedBox() :
                      Row(
                        children: [
                          const Text('Tipo de Cambio: ', style: AppTheme.labelStyle),
                          Text(Formatos.moneda.format(ntc), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ),
                      
                      widget.fromDeudas ? const SizedBox() :
                      Row(
                        children: [
                          const Text('Cambio Entregado: ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format(widget.venta.cambio.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Recibido', style: AppTheme.labelStyle, textScaler: TextScaler.linear(1.3)),
                          SizedBox(width: 15),
                        ],
                      ),
                      widget.venta.recibidoMxn!=null ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Pesos: ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format(widget.venta.recibidoMxn!.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ) : const SizedBox(), 
                      widget.venta.recibidoUs!=null ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Dolares: ', style: AppTheme.labelStyle),
                          Text('(${Formatos.dolares.format(CalculosDinero().pesosADolar(widget.venta.recibidoUs!.toDouble(), ntc))}) ', style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1)),
                          Text(Formatos.pesos.format(widget.venta.recibidoUs!.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ) : const SizedBox(), 
                      widget.venta.recibidoTarj!=null ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Tarjeta ${widget.venta.tipoTarjeta} ', style: AppTheme.labelStyle),
                          Text('(Ref. ${widget.venta.referenciaTarj}): ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format(widget.venta.recibidoTarj!.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ) : const SizedBox(),
                      widget.venta.recibidoTrans!=null ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Transferencia ', style: AppTheme.labelStyle),
                          Text('(Ref. ${widget.venta.referenciaTrans}): ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format(widget.venta.recibidoTrans!.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ) : const SizedBox(), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Total Recibido: ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format(widget.venta.recibidoTotal.toDouble()), style: AppTheme.tituloPrimario, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ),
                      !widget.venta.liquidado ?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Por Pagar: ', style: AppTheme.labelStyle),
                          Text(Formatos.pesos.format((widget.venta.total - widget.venta.abonadoTotal).toDouble()), style: AppTheme.warningStyle, textScaler: const TextScaler.linear(1.2)),
                          const SizedBox(width: 15),
                        ],
                      ) : const SizedBox()
                    ],
                  ),
                ),
              ],
            ) : Wrap(
              //mainAxisAlignment: MainAxisAlignment.center,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Venta Cancelada: ', style: TextStyle(color: Color.fromARGB(255, 225, 162, 53), fontWeight: FontWeight.bold)),
                Text(widget.venta.motivoCancelacion??'', style: AppTheme.warningStyle, textAlign: TextAlign.justify,),
              ],
            ), 
            const SizedBox(height: 15),

            //Botones 
            widget.fromDeudas== false ?
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
            
                 widget.isActive ? !widget.venta.cancelado? Padding(
                   padding: const EdgeInsets.only(right: 25),
                   child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorError2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Custom radius
                        ),
                      ),
                      onPressed: () async{
                        final resp = await verificarAdminPsw(context);
                        if (resp==true){
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                MotivoCancelacion(id: widget.venta.id!, callback: widget.callback),
                                const WindowBar(overlay: true),
                              ],
                            ),
                          );
                        }
                      }, 
                      child: const Text('Cancelar Venta', style: AppTheme.tituloClaro)
                    ),
                 ) : const SizedBox() : const SizedBox(), 
                 widget.isActive ? const Spacer() : const SizedBox(),

                /*Tooltip( //TODO: en desarrollo
                  message: 'En desarrollo',
                  child: ElevatedButton(
                    onPressed: (){}, 
                    child: const Text('Facturar')
                  ),
                ), const SizedBox(width: 15),
                Tooltip(
                  message: 'En desarrollo',
                  child: ElevatedButton(
                    onPressed: (){}, 
                    child: const Text('Enviar por WhatsApp')
                  ),
                ), const SizedBox(width: 15),*/
                
                !widget.venta.cancelado ?
                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: ElevatedButton(
                    onPressed: ()=>Ticket.imprimirTicketVenta(context, widget.venta, widget.venta.folio), 
                    child: const Text('Reimprimir Ticket')
                  ),
                ) : const SizedBox(),
                
                ElevatedButton(
                  onPressed: ()=> Navigator.pop(context), 
                  child: const Text('Regresar')
                )
              ],
            )
            :
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //TODO: boton para cancelar venta tambien cuando es deuda? simplificaria algo la clase por la parte esta de aqui arriba xd

                Configuracion.esCaja ?
                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: ElevatedButton(
                    onPressed: (){
                      // Lógica para pagar
                      if(!context.mounted){ return; }
                      showDialog(
                        context: context,
                        builder: (_) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ProcesarPago(
                              venta: widget.venta,
                              isDeuda: true,
                              deudaMonto: monto?.toDouble() ?? 0, 
                              afterProcesar: (value){},
                            ),
                            const WindowBar(overlay: true),
                          ],
                        ),
                      ).then((value) {
                        if(!context.mounted){ return; }
                        Navigator.pop(context);
                      });
                    }, child: const Text('Pagar')
                  ),
                ) : const SizedBox(),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Regresar')
                )

              ],
            )
          ],
        ),
      )
    );
  }
}

class MotivoCancelacion extends StatelessWidget {
  const MotivoCancelacion({
    super.key, required this.id, required this.callback,
  });

  final String id;
  final Function() callback;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    void submited() async{ 
      if (!formKey.currentState!.validate()) return;
      Loading.displaySpinLoading(context);

      final ventaSvc = Provider.of<VentasServices>(context, listen: false);
      try {
        await ventaSvc.cancelarVenta(id, controller.text);
        if (!context.mounted) return;
        Navigator.pop(context, true);
        Navigator.pop(context, true);
        Navigator.pop(context, true);
        callback();
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context, true);
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Text('Motivo de cancelacion',textAlign: TextAlign.center, style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.75)),
      content: SizedBox(
        width: 300,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextFormField(
                controller: controller,
                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  labelStyle: AppTheme.labelStyle,
                  isDense: true,
                  contentPadding: EdgeInsets.only(left: 10, top: 20),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                ),
                autofocus: true,
                maxLength: 250,
                maxLines: 3,

                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la contraseña';
                  }
                  return null;
                },
                onFieldSubmitted: (value) => submited(),
              ),const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () => submited(),
                child: const Text('Continuar')
              ),

            ]
          )
        )
      )
    );
  }
}

class FilaDetalles extends StatelessWidget {
  const FilaDetalles({super.key, required this.detalle, required this.color,});
  final DetallesVenta detalle;
  final int color;

  @override
  Widget build(BuildContext context) {
    final producto = Provider.of<ProductosServices>(context, listen:false).obtenerProductoPorId(detalle.productoId)?.descripcion;
    final subSubTotal = detalle.subtotal.toDouble() - detalle.iva.toDouble() + detalle.descuentoAplicado.toDouble();
    return Container(
      height: 25,
      color: color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Center(child: Text(detalle.cantidad.toString()))),
          Expanded(flex: 3, child: Center(child: Text(producto??'No se encontro el producto'))),
          Expanded(flex: 3, child: Center(child: Text(detalle.comentarios??'-'))),
          Expanded(flex: 2, child: Center(child: Text(detalle.descuento==0 ? '-' : '${detalle.descuento}%'))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(subSubTotal)))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(detalle.iva.toDouble())))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(detalle.subtotal.toDouble())))),
        ],
      ),
    );
  }
}