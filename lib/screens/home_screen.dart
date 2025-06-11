import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key ?? homeScreenKey);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final double barraHeight = 35;



  @override
  void initState() {
    super.initState;

    const size = Size(1024, 720);
    appWindow.minSize = size;
    appWindow.maximize();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - barraHeight;
    if (kDebugMode) {
      print('HomeBuild');
    }
    
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
                    color: AppTheme.secundario1,
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

        HoverSideMenu( //Izquierdo
          side: MenuSide.left,
          height: height + barraHeight,
          //boxDecoration: gradianteL,
          enabled: true,
          menuContentColapsed: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 94),
              Expanded(
                child: ListView.builder(
                  itemCount: Modulos.modulos.length,
                  itemBuilder: (context, index) {
                    if (index == Modulos.modulos.length-1){
                      return SizedBox();
                    }

                    String modulo = Modulos.modulos.keys.elementAt(index);
                    bool selected = Modulos.moduloSelected == modulo;
                
                    return Padding(
                      padding: const EdgeInsets.only(top: 15, left: 13),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.letraClara : Colors.transparent,
                              border: Border.all(color: AppTheme.letra70),
                              borderRadius: const BorderRadius.all(Radius.circular(8))
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Modulos.modulosIconos[modulo]?.elementAt(0) ?? Icons.folder, 
                                color: selected 
                                  ? AppTheme.primario1
                                  : AppTheme.letra70, 
                                size: 25
                              ),
                            )
                          ),
                          SizedBox(width: 0)
                        ],
                      ),
                    );
                  
                  }
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Modulos.moduloSelected ==  Modulos.modulos.keys.elementAt(Modulos.modulos.length-1) ? AppTheme.letraClara : Colors.transparent,
                        border: Border.all(color: AppTheme.letra70),
                        borderRadius: const BorderRadius.all(Radius.circular(8))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Modulos.modulosIconos[Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1)]?.elementAt(0) ?? Icons.folder, color: Modulos.moduloSelected ==  Modulos.modulos.keys.elementAt(Modulos.modulos.length-1) ? AppTheme.primario1 : AppTheme.letra70, size: 25),
                      )
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('0.0001v', style: AppTheme.subtituloPrimario)),
              ),
            ],
          ),
          menuContent: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12), 
                child: Image.asset(
                  'assets/images/logo2.png', 
                  height: 70, 
                  color: AppTheme.colorContraste), //LOGO
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: Modulos.modulos.length,
                  itemBuilder: (context, index) {
                    if (index == Modulos.modulos.length-1){
                      return SizedBox();
                    }

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


              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      Modulos.moduloSelected = Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1);
                      Modulos.subModuloSelected = 0;
                    });
                  },
                  child: CustomNavigationButton(
                    icon: Modulos.modulosIconos[Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1)]?.elementAt(0) ?? Icons.folder,
                    label: Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1)[0].toUpperCase() + Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1).substring(1),
                    selected: Modulos.moduloSelected == Modulos.modulos.keys.elementAt(Modulos.modulos.keys.length-1) ? true : false
                  )
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('Version Alpha 0.0001v', style: AppTheme.subtituloPrimario)),
              ),
            ],
          ),
        ),
        

        HoverSideMenu( //Menu derecho
          side: MenuSide.right,
          height: height+1,
          enabled: 
          Modulos.modulos[Modulos.moduloSelected] != null 
          ? Modulos.modulos[Modulos.moduloSelected]!.length > 1 
          ? true : false : false,
          //boxDecoration: gradianteR,
          collapsedWidth: Modulos.modulos[Modulos.moduloSelected]!=null 
            ? Modulos.modulos[Modulos.moduloSelected]!.length > 1 
            ? 66 
            : 15 
            : 15,
            menuContentColapsed: Modulos.modulos[Modulos.moduloSelected]!=null 
            ? Modulos.modulos[Modulos.moduloSelected]!.length > 1
            ? ListView.builder(
            itemCount: Modulos.modulos[Modulos.moduloSelected]?.length??0,
            itemBuilder: (context, index) {
          
              if (Modulos.modulos[Modulos.moduloSelected]?.length!=null){
                if (Modulos.modulos[Modulos.moduloSelected]!.length > 1){
                  bool selected = Modulos.subModuloSelected == index;
                  return Padding(
                    padding: const EdgeInsets.only(top: 15, left: 13),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.letraClara : Colors.transparent,
                            border: Border.all(color: AppTheme.letra70),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Modulos.modulosIconos[Modulos.moduloSelected]?.elementAt(index+1) ?? Icons.folder, 
                            color: selected 
                              ? AppTheme.primario1 
                              : AppTheme.letra70, 
                            size: 25),
                          )
                        ),
                      ],
                    ),
                  );
                }
              }
              return null;

            }
          ) : null : null,
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
        ),
      
        Consumer<WebSocketService>( //Bloqueo
          builder: (context, webSocketService, child) {
            if (!webSocketService.isConnected){
              return Scaffold( 
                backgroundColor: Colors.transparent,
                body: Stack( 
                  children: [
                    Container(
                      color: Colors.black45,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Conexion perdida con el Servidor'), SizedBox(height: 25),
                            CircularProgressIndicator(color: Colors.white), SizedBox(height: 25),
                            Text('Reconectando...'),
                          ],
                        )),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: barraHeight,
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
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox();
            }
          }
        ),
        
                
      ],
    );
  }

  Widget screen() {

    for (MapEntry<String, List<String>> modulo in Modulos.modulos.entries) {
      if (Modulos.moduloSelected==modulo.key){
        try {
          return Modulos.modulosScreens[modulo.key]![Modulos.subModuloSelected];
        } catch (e) {
          return Center(child: Text('No se encontro xd', style: AppTheme.subtituloConstraste));
        }
      }
      
    }


    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo2.png', height: 200, color: AppTheme.colorContraste.withAlpha(150)),
        SizedBox(height: 15),
        Text('¡Bienvenido a PrinterBoyStation!\n¿Qué haremos hoy?', 
          textScaler: TextScaler.linear(1.5), 
          style: TextStyle(color: AppTheme.colorContraste.withAlpha(150)),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}