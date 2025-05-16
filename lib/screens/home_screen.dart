import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/custom_navigation_button.dart';
import 'package:pbstation_frontend/widgets/hover_side_menu.dart';
import 'package:pbstation_frontend/widgets/window_buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double barraHeight = 35;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - barraHeight;

    BoxDecoration gradianteL = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.1,0.9],
        colors: [
          AppTheme.azulPrimario2,
          AppTheme.azulPrimario1,
        ]
      )
    );
    
    BoxDecoration gradianteR = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.1,0.9],
        colors: [
          AppTheme.azulSecundario1,
          AppTheme.azulSecundario2,
        ]
      ),
    );

    
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              children: [

                Container(///////////////barra de windows /////////////////////
                  height: barraHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.azulSecundario1, //Color.fromARGB(255, 18, 85, 187),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
                  ),
                  child: WindowTitleBarBox(
                    child: Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              MoveWindow(),
                            ],
                          )
                        ),
                        WindowButtons()
                      ],
                    ),
                  ),
                ),

                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    child: screen(),
                  )
                )

              ],
            )
          ),
        ),
        HoverSideMenu(
          side: MenuSide.left,
          height: height + barraHeight,
          boxDecoration: gradianteL,
          enabled: true,
          menuContent: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/images/logo.png'),
              ),

              Flexible(
                child: ListView.builder(
                  itemCount: Modulos.modulos.length,
                  itemBuilder: (context, index) {
                    String modulo = Modulos.modulos.keys.elementAt(index);
                
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            Modulos.moduloSelected = modulo;
                            Modulos.subModuloSelected = 0;
                          });
                        },
                        child: CustomNavigationButton(
                          icon: Modulos.modulosIconos[modulo] ?? Icons.folder,
                          label: modulo[0].toUpperCase() + modulo.substring(1),
                          selected: Modulos.moduloSelected == modulo ? true : false
                        )
                      ),
                    );
                  
                  }
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('Version Alpha 0.0001v')),
              ),

/*
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Modulos.moduloSelected = 'caja';
                    Modulos.subModuloSelected = 0;
                  });
                },
                child: CustomNavigationButton(
                  icon: Icons.sell, label: 'Caja',
                  selected:
                   Modulos.moduloSelected == 'caja' ? true : false
                )
              ),
            ),

            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Modulos.moduloSelected = 'catalogo';
                    Modulos.subModuloSelected = 0;
                  });
                },
                child: CustomNavigationButton(
                  icon: Icons.add_chart, label: 'Catalogo',
                  selected: Modulos.moduloSelected == 'catalogo' ? true : false
                )
              ),
            ),

            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Modulos.moduloSelected = 'cotizaciones';
                    Modulos.subModuloSelected = 0;
                  });
                },
                child: CustomNavigationButton(
                  icon: Icons.price_check, label: 'Cotizaciones',
                  selected: Modulos.moduloSelected == 'cotizaciones' ? true : false
                )
              ),
            ),*/

            ],
          ),
        ),
        

        HoverSideMenu(
          side: MenuSide.right,
          height: height+1,
          enabled: 
          Modulos.modulos[Modulos.moduloSelected] != null 
          ? Modulos.modulos[Modulos.moduloSelected]!.length > 1 
          ? true : false : false,
          boxDecoration: gradianteR,
          menuContent: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 40, 
                width: 50,
                color: Colors.red,
              ),
              ElevatedButton(
                onPressed: (){}, 
                child: Text(
                  'Soy un botón xd',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              )

            ],
          ),
        )

      ],
    );
  }

  Widget screen() {

    for (MapEntry<String, List<String>> modulo in Modulos.modulos.entries) {
      if (Modulos.moduloSelected==modulo.key){
        print('Modulo seleccionado! ${modulo.key}');
        return Modulos.modulosScreens[modulo.key]?[Modulos.subModuloSelected] 
        ?? Text('No se encontro xd');
      }
      
    }


    return Container( //Este puede ser el Login 
      color: Colors.blueGrey,
    );
  }
}