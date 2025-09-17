import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
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
  int indexResta = 0;
  final int maximoPestanias = 4;
  bool cajaNotFound=false;

  @override
  void initState() {
    super.initState();
    Provider.of<ClientesServices>(context, listen: false).loadClientes();
    Provider.of<ProductosServices>(context, listen: false).loadProductos();
    Provider.of<VentasEnviadasServices>(context, listen: false).ventasRecibidas();
    if (CajasServices.cajaActualId == 'buscando'){ cajaNotFound=true; }
  }

  @override
  Widget build(BuildContext context) {
    final suc = Provider.of<SucursalesServices>(context, listen: false);
    Provider.of<CajasServices>(context); //para escuchar listening

    void agregarPestania() {
      if (VentasStates.pestanias >= maximoPestanias) { return; }
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
      indexResta = 10;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 235));
      setState(() {});
      indexResta = 0;
    }

    void rebuild() async{
      indexResta = 10;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 235));
      setState(() {});
      indexResta = 0;
    }

    
    if (Configuracion.esCaja && (CajasServices.cajaActual==null || CajasServices.corteActual==null)){
      return AbrirCaja();
    }

    return Consumer3<ClientesServices, ProductosServices, VentasEnviadasServices>(
      builder: (context, value, value2, value3, child) {
        if (value.isLoading || value2.isLoading || value3.isLoading){
          return SimpleLoading();
        }
        return body(agregarPestania, selectedPestania, rebuildAndClean, context, rebuild, suc);
      });
  }


  Widget body(void Function() agregarPestania, void Function(int index) selectedPestania, void Function(dynamic index) rebuildAndClean, BuildContext context, void Function() rebuild, SucursalesServices suc) {
    return Padding(
    padding: const EdgeInsets.only(top:8, bottom: 5, left: 54, right: 52),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        suc.sucursalActual!=null ? KeyedSubtree(
          key: ValueKey<int>(VentasStates.indexSelected),
          child: VentaForm(
            key: ValueKey('venta-${VentasStates.indexSelected - indexResta}'),
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

        //Elegir venta
        if (ventasRecibida.ventas.length > 1){
          seleccion = await showDialog(
            context: context, 
            builder: (context) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  AlertDialog(
                    backgroundColor: AppTheme.containerColor1,
                    title: Center(child: Text('Seleccione una venta'),),
                    content: SizedBox(
                      height: 250, 
                      width: 550,
                      child: ListView.builder(
                        itemCount: ventasRecibida.ventas.length,
                        itemBuilder: (context, index) {
                  
                          //fecha
                          DateTime dt = DateTime.parse(ventasRecibida.ventas[index].fechaEnvio);
                          final DateFormat formatter = DateFormat('hh:mm:ss a');
                          final String formatted = formatter.format(dt);
                  
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton(
                              autofocus: index==0,
                              style: AppTheme.botonSecundarioStyle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text('Enviado Desde:', textScaler: TextScaler.linear(0.8)),
                                      Text(ventasRecibida.ventas[index].compu),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Vendedor:', textScaler: TextScaler.linear(0.8)),
                                      Text(
                                        ventasRecibida.ventas[index].usuario.length > 30 
                                            ? '${ventasRecibida.ventas[index].usuario.substring(0, 30)}...' 
                                            : ventasRecibida.ventas[index].usuario,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Hora de Envio:', textScaler: TextScaler.linear(0.8)),
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
                  backgroundColor: AppTheme.containerColor1,
                  content: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Si continúa, la venta se aplicará a la pestaña de venta actual.\nSi no desea sobrescribir la pestaña actual, seleccione otra.",
                          textScaler: TextScaler.linear(1.1),
                          style: TextStyle(color: Colors.white), 
                          textAlign: TextAlign.center
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            style: AppTheme.botonSecundarioStyle,
                            autofocus: true,
                            onPressed: (){
                              Navigator.pop(context, 'continuar');
                            }, 
                            child: Text('Continuar'),
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
              print("Diálogo cancelado");
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

          //Pasar los Datos a VentaForm
          VentasStates.tabs[index].clienteSelected = clientesS.clientes.firstWhere((element) => element.id == venta.clienteId);
          VentasStates.tabs[index].entregaInmediata = !venta.pedidoPendiente;
          VentasStates.tabs[index].fechaEntrega = DateTime.tryParse(venta.fechaEntrega??'');
          for (var detalle in venta.detalles) {
            VentasStates.tabs[index].productos.add(productosS.productos.firstWhere((element) => element.id == detalle.productoId));
          }
          VentasStates.tabs[index].detallesVenta = venta.detalles;
          VentasStates.tabs[index].comentariosController.text = venta.comentariosVenta;
          VentasStates.tabs[index].subtotalController.text = Formatos.pesos.format(venta.subTotal.toDouble());
          VentasStates.tabs[index].totalDescuentoController.text = Formatos.pesos.format(venta.descuento.toDouble());
          VentasStates.tabs[index].totalIvaController.text = Formatos.pesos.format(venta.iva.toDouble());
          VentasStates.tabs[index].totalController.text = Formatos.pesos.format(venta.total.toDouble());

          //Eliminar VentaRecibida
          ventasRecibida.eliminarRecibida(venta.id!, venta.sucursalId);

          //Volver a Renderizar para mostrar Cambios
          rebuild();    
        }  
      }
    );
  }
}
class AdvertenciaSucursal extends StatelessWidget {
  const AdvertenciaSucursal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: AppTheme.containerColor1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Esta terminal aún no tiene una sucursal asignada.",
                  style: AppTheme.tituloClaro,
                  textScaler: TextScaler.linear(1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ), 
            Transform.translate(
              offset: Offset(0, -5),
              child: Text(
                "Asigne una para poder continuar.",
                style: AppTheme.tituloClaro,
                textScaler: TextScaler.linear(1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(text: 'Acceda a  ', style: AppTheme.subtituloPrimario),
                  TextSpan(text: 'Catálogo', style: AppTheme.tituloClaro.copyWith(fontSize: 16)),
                  TextSpan(text: ' > ', style: AppTheme.subtituloPrimario,),
                  TextSpan(text: 'Sucursales', style: AppTheme.tituloClaro.copyWith(fontSize: 16)),
                  TextSpan(text: '  con una cuenta de administradory asigne una sucursal\na esta terminal para continuar.', style: AppTheme.subtituloPrimario),
                ],
              ),
            )
          ],
        ),
      ),
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
      elevation: 2,
      items: [
        PopupMenuItem(
          value: 'limpiar',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cleaning_services, color: AppTheme.letraClara, size: 17),
              Text('  Limpiar', style: TextStyle(color: AppTheme.letraClara)),
            ],
          ),
        ),
        /*PopupMenuItem(
          value: 'cerrar',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear, color: AppTheme.colorError, size: 17),
              Text('  Quitar', style: TextStyle(color: AppTheme.colorError)),
            ],
          ),
        ),*/
      ],
    );

    if (seleccion != null) {
      if (seleccion == 'limpiar') {
        // Lógica para limpiar
        
        rebuild!(index);
      } else if (seleccion == 'cerrar') {
        // Lógica para eliminar

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 2),
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
              child: Icon(Icons.add, color: AppTheme.letraClara, size: 21)
            ),
          ),
        ),
      ),
    );
  }
}
