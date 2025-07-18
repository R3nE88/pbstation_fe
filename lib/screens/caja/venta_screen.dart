import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
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

  @override
  void initState() {
    super.initState();
    final clientesServices = Provider.of<ClientesServices>(context, listen: false);
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    clientesServices.loadClientes();
    productosServices.loadProductos();
  }

  @override
  Widget build(BuildContext context) {
    final suc = Provider.of<SucursalesServices>(context, listen: false);


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

    void rebuild(index) async{
      VentasStates.clearTab(index);
      indexResta = 10;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 235));
      setState(() {});
      indexResta = 0;
    }

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
                    return Pestania(last: false, selected: index == VentasStates.indexSelected, selectedPestania: selectedPestania, rebuild: rebuild, index: index);
                  },
                ),
              ),

              /*Transform.translate(
                offset: const Offset(0, -8),
                child: ElevatedButton(
                  onPressed: (){}, 
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-8, 1),
                        child: Icon(Icons.search, color: AppTheme.containerColor1, size: 26)
                      ),
                      Text('Leer Corizacion', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700) ),
                      Text('   F11', style: TextStyle(color: AppTheme.containerColor1.withAlpha(180), fontWeight: FontWeight.w700) ),
                    ],
                  ),
                ),
              ),*/

            ],
          ),
          suc.sucursalActual!=null ? KeyedSubtree(
            key: ValueKey<int>(VentasStates.indexSelected),
            child: VentaForm(
              key: ValueKey('venta-${VentasStates.indexSelected - indexResta}'),
              index: VentasStates.indexSelected, 
              rebuild: rebuild,
            ),
          ) 
          : 
          const AdvertenciaSucursal(),
        ],
      ),
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
                child: Text('Venta ${index+1}', style: AppTheme.tituloPrimario) //TODO: nombre de pestaña
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
