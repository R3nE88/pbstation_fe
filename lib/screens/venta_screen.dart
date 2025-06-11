import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/venta.dart';
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
  int indexSelected = 0;
  int pestanias = 2;
  int maximoPestanias = 4;
  

  @override
  void initState() {
    super.initState();
    final clientesServices = Provider.of<ClientesServices>(context, listen: false);
    clientesServices.loadClientes();
  }

  @override
  Widget build(BuildContext context) {
    final clientesServices = Provider.of<ClientesServices>(context);

    void agregarPestania() {
      if (pestanias >= maximoPestanias) {
        return;
      }
      setState(() {
        pestanias++;
      });
    }

    void selectedPestania(int index) {
      setState(() {
        indexSelected = index;
      });
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
                  itemCount: pestanias,
                  itemBuilder: (context, index) {
              
                    if (index == pestanias - 1) {
                      return Pestania(last: true, selected: false, agregarPestania: agregarPestania, index: index);
                    }
                    return Pestania(last: false, selected: index == indexSelected, selectedPestania: selectedPestania, index: index);
              
                  },
                ),
              ),
              Transform.translate(
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
              ),
            ],
          ),
          Venta(clientesServices: clientesServices, index: indexSelected)
        ],
      ),
    );
  }
}

class Pestania extends StatelessWidget {
  const Pestania({
    super.key, required this.last, required this.selected, this.agregarPestania, this.selectedPestania, required this.index,
  });

  final bool last; 
  final bool selected;
  final Function? agregarPestania;
  final Function? selectedPestania;
  final int index;

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
            child: FeedBackButton(
              onPressed: () {
                selectedPestania!(index);
              },
              child: Text('Venta Nueva', style: AppTheme.tituloPrimario)
            ),
          ) 
          : Padding(
            padding: const EdgeInsets.only(top:8, bottom: 8, left: 10, right: 16),
            child: FeedBackButton(
              onPressed: () {
                //Agregar una pestaña en VentaScreen
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
