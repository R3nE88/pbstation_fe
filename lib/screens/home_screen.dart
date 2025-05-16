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

              Expanded(
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
                          icon: Modulos.modulosIconos[modulo]?.elementAt(0) ?? Icons.folder,
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
                child: Center(child: Text('Version Alpha 0.0001v', style: AppTheme.subtituloPrimario)),
              ),
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
          menuContent: ListView.builder(
            itemCount: Modulos.modulos[Modulos.moduloSelected]?.length??0,
            itemBuilder: (context, index) {
              List<String>? subModulos = Modulos.modulos[Modulos.moduloSelected];

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      Modulos.moduloSelected = Modulos.moduloSelected;
                      Modulos.subModuloSelected = index;
                    });
                  },
                  child: CustomNavigationButton(
                    icon: Modulos.modulosIconos[Modulos.moduloSelected]?.elementAt(index+1) ?? Icons.folder,
                    label: subModulos?[index] ?? 'na', 
                    selected: Modulos.subModuloSelected == index ? true : false
                  )
                ),
              );
            }
          )   
        )
      ],
    );
  }

  Widget screen() {

    for (MapEntry<String, List<String>> modulo in Modulos.modulos.entries) {
      if (Modulos.moduloSelected==modulo.key){
        print('Modulo seleccionado! ${modulo.key}');
        try {
          return Modulos.modulosScreens[modulo.key]![Modulos.subModuloSelected];
        } catch (e) {
          return Center(child: Text('No se encontro xd'));
        }
      }
      
    }


    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo.png', height: 200, color: Colors.black54),
        SizedBox(height: 15),
        Text('¡Bienvenido a PrinterBoyStation!\n¿Qué haremos hoy?', 
          textScaler: TextScaler.linear(1.5), 
          style: TextStyle(color: Colors.black45),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}