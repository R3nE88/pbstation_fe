import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mostrar_dialog_permiso.dart';
import 'package:pbstation_frontend/logic/ticket.dart';
import 'package:pbstation_frontend/logic/verificar_admin_psw.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/loading_state.dart';
import 'package:pbstation_frontend/screens/caja/venta/procesar_pago.dart';
import 'package:pbstation_frontend/services/login.dart';
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
  late final String fechaFormateada = DateFormat('EEEE dd-MMM-yyyy hh:mm a', 'es_MX').format(fecha);
  Pedidos? pedido;
  late Decimal? monto = obtenerMontoPendiente(widget.venta.id!, context);
  double ntc = 0;
  bool _buscandoPedido = false;

  @override
  void initState() {
    super.initState();    
    if (widget.venta.detalles.length > 8){
      height = 213;
    } else {
      height = (25 * widget.venta.detalles.length).toDouble();
    }

    datosIniciales();
    
    // Buscar pedido
    if (widget.venta.hasPedido) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buscarPedido();
      });
    }
  }

  void datosIniciales() async{
    if (widget.tc != 0){
      ntc = widget.tc;
    } else {
      ntc = await Provider.of<CajasServices>(context, listen: false).obtenerTCDeVenta(widget.venta.id!);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _buscarPedido() async {
    final pedidosSvc = Provider.of<PedidosService>(context, listen: false);
    
    // Verificar si el pedido ya está en memoria
    try {
      pedidosSvc.pedidosReady.firstWhere(
        (element) => element.ventaFolio == widget.venta.folio
      );
      return; // Ya está en memoria
    } catch (e) {
      try {
        pedidosSvc.pedidosNotReady.firstWhere(
          (element) => element.ventaFolio == widget.venta.folio
        );
        return; // Ya está en memoria
      } catch (e) {
        // No está en memoria, buscar en BD
        if (_buscandoPedido) return; // Evitar búsquedas duplicadas
        
        setState(() {
          _buscandoPedido = true;
        });

        try {
          final pedidoEncontrado = await pedidosSvc.searchPedidoByVentaFolio(widget.venta.folio!);
          
          if (pedidoEncontrado != null && mounted) {
            // El Selector se actualizará automáticamente si el service notifica los cambios
            setState(() {
              pedido = pedidoEncontrado;
              _buscandoPedido = false;
            });
          } else {
            if (mounted) {
              setState(() {
                _buscandoPedido = false;
              });
            }
          }
        } catch (e) {
          debugPrint('Error al buscar pedido: $e');
          if (mounted) {
            setState(() {
              _buscandoPedido = false;
            });
          }
        }
      }
    }
  }

  void entregarPedido() async{
    //Solo si tiene pedido
    if (widget.venta.hasPedido){
      final pedidosSvc = Provider.of<PedidosService>(context, listen: false);

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

      //Cambiar estado de pedido a entregado y actualizar venta con hasPedido = false;
      if (continuar==true){ 
        
        if (!mounted) return;
        final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
        loadingSvc.show();

        //await Provider.of<VentasServices>(context, listen: false).marcarVentasEntregadasPorFolio(widget.venta.folio!);
        if (pedido!=null){
          await pedidosSvc.actualizarEstadoPedido(pedidoId: pedido!.id!, estado: 'entregado');
        }
        

        loadingSvc.hide();
      }
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

    return Selector<PedidosService, Pedidos?>(
      selector: (context, pedidosSvc) {
        // Solo retorna el pedido específico de esta venta
        if (!widget.venta.hasPedido) return null;
        
        // Si ya encontramos el pedido en la búsqueda asíncrona, usarlo
        if (pedido != null) return pedido;
        
        try {
          return pedidosSvc.pedidosReady.firstWhere(
            (element) => element.ventaFolio == widget.venta.folio
          );
        } catch (e) {
          try {
            return pedidosSvc.pedidosNotReady.firstWhere(
              (element) => element.ventaFolio == widget.venta.folio
            );
          } catch (e) {
            // Si está buscando, retornar null (se mostrará loading en la UI si es necesario)
            return null;
          }
        }
      },
      shouldRebuild: (previous, current) {
        // Rebuild solo si el pedido cambió (comparación por referencia o por ID)
        return previous != current;
      },
      builder: (context, pedidoActual, child) {
        pedido = pedidoActual;

        return AlertDialog(
          titlePadding: const EdgeInsets.only(left: 18, right:18, top: 12),
          elevation: 4,
          shadowColor: Colors.black,
          backgroundColor: AppTheme.containerColor2,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Venta: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.6)),
              SelectableText(widget.venta.folio??'', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.7)),
              if (pedidoActual!=null)
                if (widget.venta.hasPedido)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('   Pedido: ', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.6)),
                      SelectableText('${pedidoActual.folio} ', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(0.7)),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        decoration: BoxDecoration(
                          color:  AppTheme.isDarkTheme ?const Color.fromARGB(62, 0, 0, 0) : const Color.fromARGB(211, 255, 255, 255),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(pedidoActual.estado.name, style: TextStyle(color: pedidoActual.estado.color, fontWeight: FontWeight.bold),textScaler: const TextScaler.linear(0.6))
                      )
                    ],
                  ),
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
                  offset: const Offset(0, -10),
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
                            !widget.venta.cancelado ? 
                              widget.venta.liquidado ?  
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal:8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.isDarkTheme ? Colors.black26 : Colors.white54,
                                ),
                                child: Text( 'Venta pagada', style: AppTheme.goodStyle)
                              )
                              : 
                              const Text( 'Venta con deuda', style: AppTheme.warningStyle2)
                            : Text('Venta cancelada', style: AppTheme.errorStyle2.copyWith(color: AppTheme.colorError.withAlpha(180))),
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
                              Text(Formatos.pesos.format((widget.venta.total - widget.venta.abonadoTotal).toDouble()), style: AppTheme.warningStyle2, textScaler: const TextScaler.linear(1.2)),
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
                    const Text('Motivo de cancelacion: ', style:AppTheme.warningStyle2),
                    Text(widget.venta.motivoCancelacion??'', style: AppTheme.warningStyle2, textAlign: TextAlign.justify,),
                  ],
                ), 
                const SizedBox(height: 15),

                //Botones 
                widget.fromDeudas== false ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                
                    
                    widget.isActive ? 
                      !widget.venta.cancelado? Padding(
                        padding: const EdgeInsets.only(right: 25),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colorError2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Custom radius
                            ),
                          ),
                          onPressed: () async{
                            bool? permiso;
                            if (!Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.elevado)){
                              permiso = await mostrarDialogoPermiso(context);
                            } else {
                              permiso = await verificarAdminPsw(context);
                            }
                            
                            permiso ??= false;
                            if (permiso==true){
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    MotivoCancelacion(ventaId: widget.venta.id!, callback: widget.callback, pedido: pedido),
                                    const WindowBar(overlay: true),
                                  ],
                                ),
                              );
                            }
                          }, 
                          child: const Text('Cancelar Venta', style: AppTheme.tituloClaro)
                        ),
                    ) : const SizedBox() 
                    : const SizedBox(), 
                    
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

                    Configuracion.esCaja ?
                    Padding(
                      padding: const EdgeInsets.only(right: 25),
                      child: ElevatedButton(
                        onPressed: (){
                          
                          // Lógica para pagar
                          if(!context.mounted) return; 
                          showDialog(
                            context: context,
                            builder: (_) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                CajasServices.cajaActual==null
                                ? const CustomErrorDialog(respuesta: 'Necesitas tener la caja abierta para\nregistrar una venta', titulo: 'No puedes continuar')
                                : ProcesarPago(
                                  venta: widget.venta,
                                  isDeuda: true,
                                  deudaMonto: monto?.toDouble() ?? 0, 
                                  afterProcesar: ({String? ventaId, String? ventaFolio}) => entregarPedido()
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
    );
  }
}

class MotivoCancelacion extends StatelessWidget {
  const MotivoCancelacion({
    super.key, required this.ventaId, required this.callback, this.pedido
  });

  final String ventaId;
  final Pedidos? pedido;
  final Function() callback;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    void submited() async{ 
      if (!formKey.currentState!.validate()) return;
      final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
      loadingSvc.show();

      final ventaSvc = Provider.of<VentasServices>(context, listen: false);
      try {
        await ventaSvc.cancelarVenta(ventaId, controller.text);
        if (pedido!=null){
          if (!context.mounted) return;
          await Provider.of<PedidosService>(context, listen: false).cancelarPedido(pedidoId: pedido!.id!);
        }

        if (!context.mounted) return;
        Navigator.pop(context, true);
        Navigator.pop(context, true);
        callback();
      } catch (e) { 
        debugPrint('$e');
     }
      loadingSvc.hide();
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
                    return 'Por favor ingrese el motivo';
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
    //final subTotal = detalle.subtotal.toDouble(); // - detalle.iva.toDouble() + detalle.descuentoAplicado.toDouble();
    return Container(
      height: 25,
      color: color%2==0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Center(child: Text(detalle.cantidad.toString(), style: AppTheme.subtituloConstraste))),
          Expanded(flex: 3, child: Center(child: Text(producto??'No se encontro el producto', style: AppTheme.subtituloConstraste))),
          Expanded(flex: 3, child: Center(child: Text(detalle.comentarios??'-', style: AppTheme.subtituloConstraste))),
          Expanded(flex: 2, child: Center(child: Text(detalle.descuento==0 ? '-' : '${detalle.descuento}%', style: AppTheme.subtituloConstraste))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(detalle.subtotal.toDouble()), style: AppTheme.subtituloConstraste))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(detalle.iva.toDouble()), style: AppTheme.subtituloConstraste))),
          Expanded(flex: 2, child: Center(child: Text(Formatos.pesos.format(detalle.total.toDouble()), style: AppTheme.subtituloConstraste))),
        ],
      ),
    );
  }
}