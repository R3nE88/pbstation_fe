import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mostrar_dialog_permiso.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/abrir_caja.dart';
import 'package:pbstation_frontend/screens/caja/venta/venta_form.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  int _indexResta = 0;
  final int _maximoPestanias = 4;

  @override
  void initState() {
    super.initState();
    Provider.of<ClientesServices>(context, listen: false).loadClientes();
    Provider.of<ProductosServices>(context, listen: false).loadProductos();
    Provider.of<VentasEnviadasServices>(context, listen: false).ventasRecibidas();
  }

  @override
  Widget build(BuildContext context) {
    final suc = Provider.of<SucursalesServices>(context, listen: false);
    Provider.of<CajasServices>(context); //para escuchar listening

    void agregarPestania() {
      if (VentasStates.pestanias >= _maximoPestanias) { return; }
      setState(() {
        VentasStates.pestanias++;
        VentasStates.indexSelected = VentasStates.pestanias-2;
      });
    }

    void selectedPestania(int index) {
      if (VentasStates.indexSelected==index){ return; }
      setState(() {
        VentasStates.indexSelected = index;
      });
    }

    void rebuildAndClean(index) async{
      VentasStates.clearTab(index);
      _indexResta = 10;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 235));
      setState(() {});
      _indexResta = 0;
    }

    void rebuild() async{
      _indexResta = 10;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 235));
      setState(() {});
      _indexResta = 0;
    }

    
    if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActualId==null)){
      return const AbrirCaja();
    }

    return Consumer3<ClientesServices, ProductosServices, VentasEnviadasServices>(
      builder: (context, value, value2, value3, child) {
        if (value.isLoading || value2.isLoading || value3.isLoading){
          return const SimpleLoading();
        }
        return body(agregarPestania, selectedPestania, rebuildAndClean, context, rebuild, suc);
      });
  }


  Widget body(
    void Function() agregarPestania, 
    void Function(int index) selectedPestania, 
    void Function(dynamic index) rebuildAndClean, 
    BuildContext context, 
    void Function() rebuild, 
    SucursalesServices suc){
      
      return Padding(
      padding: const EdgeInsets.only(top:8, bottom: 5, left: 54, right: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              
                  SizedBox( //Pestañas
                    height: 36,
                    width: 500,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: VentasStates.pestanias,
                      itemBuilder: (context, index) {
                        if (index == VentasStates.pestanias - 1) {
                          return Pestania(last: true, selected: false, agregarPestania: agregarPestania, index: index);
                        }
                        return Pestania(last: false, selected: index == VentasStates.indexSelected, selectedPestania: selectedPestania, rebuild: rebuildAndClean, index: index);
                      },
                    ),
                  ),
                      
                  Configuracion.esCaja 
                  ? ventaRecibida(context, rebuild) 
                  : const SizedBox()
                ],
              ),

              //Nombre del usuario que envio la venta
              VentasStates.tabs[VentasStates.indexSelected].usuarioQueEnvioNombre != null ?
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.containerColor1,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    )
                  ),
                  height: 26,
                  child: Padding(
                    padding: const EdgeInsets.only( left: 12, right: 12, top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('venta de ', style: AppTheme.labelStyle),
                        Text(VentasStates.tabs[VentasStates.indexSelected].usuarioQueEnvioNombre!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ) : const SizedBox(),
            ],
          ),
          suc.sucursalActual!=null ? KeyedSubtree(
            key: ValueKey<int>(VentasStates.indexSelected),
            child: VentaForm(
              key: ValueKey('venta-${VentasStates.indexSelected - _indexResta}'),
              index: VentasStates.indexSelected, 
              rebuild: rebuildAndClean,
            ),
          ) 
          : 
          const AdvertenciaSucursal(),
        ],
      ),
    );
  }

  VentasRecibidasButton ventaRecibida(BuildContext context, void Function() rebuild) {
    return VentasRecibidasButton(
      onPressed: () async{
        final ventasRecibida = Provider.of<VentasEnviadasServices>(context, listen: false);
        int? seleccion;
        bool continuar = true;

        if (VentasStates.tabs[VentasStates.indexSelected].fromVentaEnviada){
          await showDialog(
            context: context, 
            builder: (context) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  AlertDialog(
                    elevation: 6,
                    shadowColor: Colors.black54,
                    backgroundColor: AppTheme.containerColor1,
                    shape: AppTheme.borde,
                    title: const Center(child: Text('No se puede sobreescribir esta pestaña de venta')),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Seleccione otra pestaña o complete la venta')
                      ],
                    )
                  )
                ]
              );
            }
          );
          return;
        }

        //Elegir venta
        if (ventasRecibida.ventas.length > 1){
          if (!context.mounted) return;
          seleccion = await showDialog(
            context: context, 
            builder: (context) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  AlertDialog(
                    elevation: 6,
                    shadowColor: Colors.black54,
                    backgroundColor: AppTheme.containerColor1,
                    shape: AppTheme.borde,
                    title: const Center(child: Text('Seleccione una venta'),),
                    content: SizedBox(
                      height: 250, 
                      width: 600,
                      child: ListView.builder(
                        itemCount: ventasRecibida.ventas.length,
                        itemBuilder: (context, index) {
                  
                          //fecha
                          DateTime dt = DateTime.parse(ventasRecibida.ventas[index].fechaEnvio);
                          final DateFormat formatter = DateFormat('hh:mm:ss a');
                          final String formatted = formatter.format(dt);

                          String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(ventasRecibida.ventas[index].clienteId);
                          String usuario = ventasRecibida.ventas[index].usuarioNombre;
                  
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton(
                              autofocus: index==0,  
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Enviado Desde:', textScaler: TextScaler.linear(0.8)),
                                      Text(ventasRecibida.ventas[index].compu),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Vendedor:', textScaler: TextScaler.linear(0.8)),
                                      Text(
                                        usuario.length > 21 
                                            ? '${usuario.substring(0, 21)}...' 
                                            : usuario,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Cliente:', textScaler: TextScaler.linear(0.8)),
                                      Text(
                                        cliente.length > 22
                                            ? '${cliente.substring(0, 22)}...' 
                                            : cliente,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Hora de Envio:', textScaler: TextScaler.linear(0.8)),
                                      Text(formatted),
                                    ],
                                  ),
                                ],
                              ),
                              onPressed: (){
                                Navigator.pop(context, index);
                              }, 
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                  const WindowBar(overlay: true),
                ],
              );
            },
          ); if (seleccion==null) return;
        } else { seleccion = 0;}

        //Mostrar aviso de que se remplazara todo
        if (!context.mounted) return;
        await showDialog( //TODO: Agregar opcion en ajustes para mostrar esta advertencia siempre, o no, solo en caja
          context: context,
          builder: (context) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                AlertDialog(
                  elevation: 6,
                  shadowColor: Colors.black54,
                  backgroundColor: AppTheme.containerColor1,
                  shape: AppTheme.borde,
                  content: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Si continúa, la venta se aplicará a la pestaña de venta actual. Si no desea sobrescribir la pestaña actual, seleccione otra pestaña.',
                          textScaler: TextScaler.linear(1.1),
                          style: AppTheme.subtituloPrimario,
                          textAlign: TextAlign.center
                        ),
                        const Text(
                          '\nNo podras modificar una venta recibida desde otra PC',
                          textScaler: TextScaler.linear(0.9),
                          style: AppTheme.labelStyle,
                          textAlign: TextAlign.center
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            autofocus: true,
                            onPressed: (){
                              Navigator.pop(context, 'continuar');
                            }, 
                            child: const Text('Continuar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const WindowBar(overlay: true),
              ],
            );
          },
        ).then((value) {
          if (value == null) {
            if (kDebugMode) {
              print('Diálogo cancelado');
            }
            continuar = false;
            return; // Cancela la operación
          }
        });

        if (continuar){
          //Cargar Datos
          VentasEnviadas venta = ventasRecibida.ventas[seleccion];
          int index = VentasStates.indexSelected;
          VentasStates.tabs[index].clear();
          if(!context.mounted) return;
          final clientesS = Provider.of<ClientesServices>(context, listen: false);
          final productosS = Provider.of<ProductosServices>(context, listen: false);

          VentasStates.tabs[index].usuarioQueEnvioId = venta.usuarioId;
          VentasStates.tabs[index].usuarioQueEnvioNombre = venta.usuarioNombre;

          //Pasar los Datos a VentaForm
          VentasStates.tabs[index].clienteSelected = clientesS.clientes.firstWhere((element) => element.id == venta.clienteId);
          VentasStates.tabs[index].entregaInmediata = !venta.hasPedido;
          VentasStates.tabs[index].fechaEntrega = venta.fechaEntrega!=null ? DateTime.parse(venta.fechaEntrega!) : null;
          for (var detalle in venta.detalles) {
            VentasStates.tabs[index].productos.add(productosS.productos.firstWhere((element) => element.id == detalle.productoId));
          }
          VentasStates.tabs[index].detallesVenta = venta.detalles;
          VentasStates.tabs[index].pedidosIds = venta.pedidosIds ?? [];
          VentasStates.tabs[index].fromVentaEnviada = true;
          VentasStates.tabs[index].fromVentaEnviadaData = {'id': venta.id!, 'sucursal':venta.sucursalId};
          VentasStates.tabs[index].comentariosController.text = venta.comentariosVenta??'';
          VentasStates.tabs[index].subtotalController.text = Formatos.pesos.format(venta.subTotal.toDouble());
          VentasStates.tabs[index].totalDescuentoController.text = Formatos.pesos.format(venta.descuento.toDouble());
          VentasStates.tabs[index].totalIvaController.text = Formatos.pesos.format(venta.iva.toDouble());
          VentasStates.tabs[index].totalController.text = Formatos.pesos.format(venta.total.toDouble());

          //Eliminar VentaRecibida
          ventasRecibida.ventas.removeWhere((element) => element.id == venta.id);

          //Volver a Renderizar para mostrar Cambios
          rebuild();    
        }  
      }
    );
  }
}


class Pestania extends StatelessWidget {
  const Pestania({
    super.key, required this.last, required this.selected, this.agregarPestania, this.selectedPestania, this.rebuild, required this.index,
  });

  final bool last; 
  final bool selected;
  final Function? agregarPestania;
  final Function? selectedPestania;
  final Function? rebuild;
  final int index;

  void _mostrarMenu(BuildContext context, Offset offset) async {
    
    final seleccion = await showMenu(
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
        const PopupMenuItem(
          value: 'limpiar',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cleaning_services, color: AppTheme.letraClara, size: 17),
              Text('  Limpiar', style: TextStyle(color: AppTheme.letraClara)),
            ],
          ),
        ),
      ],
    );

    if (seleccion != null) {
      if (seleccion == 'limpiar') {
        bool? success = false;
        if (VentasStates.tabs[index].fromVentaEnviada){
          if (!context.mounted) return;
          success = await mostrarDialogoPermiso(context);
          if (success==true){
            if (!context.mounted) return; 
            Provider.of<VentasEnviadasServices>(context, listen: false).eliminarRecibida(VentasStates.tabs[index].fromVentaEnviadaData['id']!, VentasStates.tabs[index].fromVentaEnviadaData['sucursal']!);
            for (var pedidoId in VentasStates.tabs[index].pedidosIds) {
              Provider.of<PedidosService>(context, listen: false).eliminarPedido(pedidoId: pedidoId);
            }
          }
        } else {
          success = true;
        }
        if (success??false){
          rebuild!(index);
          
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 2),
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: DiagonalCornerContainer(
          color: selected == true ? AppTheme.containerColor1 : AppTheme.containerColor2,
          child: last != true ? Padding(
            padding: const EdgeInsets.only(top:8, bottom: 8, left: 8, right: 20),
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                selectedPestania!(index);
                _mostrarMenu(context, details.globalPosition);
              }, 
              child: FeedBackButton(
                onPressed: () {
                  selectedPestania!(index);
                },
                child: Text('Venta ${index+1}', style: AppTheme.tituloPrimario)
              ),
            ),
          ) 
          : Padding(
            padding: const EdgeInsets.only(top:8, bottom: 8, left: 10, right: 16),
            child: FeedBackButton(
              onPressed: () {
                agregarPestania!();
              },
              child: const Icon(Icons.add, color: AppTheme.letraClara, size: 21)
            ),
          ),
        ),
      ),
    );
  }
}