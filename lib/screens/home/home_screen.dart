import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/home_state.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    if (!HomeState.init){
      HomeState.init = true;
      const size = Size(1024, 720);
      appWindow.minSize = size;
      appWindow.maximize();
    }

    const double barraHeight = 35;
    final modProv = context.watch<ModulosProvider>();
    final height = MediaQuery.of(context).size.height - barraHeight;
    final screens = Modulos.modulosScreens[modProv.moduloSeleccionado] ?? <Widget>[];

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              // Custom Window Bar
              WindowBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  child: screens.isNotEmpty
                  ? IndexedStack(
                    index: modProv.subModuloSeleccionado,
                    children: screens, // List<Widget>
                  )
                  : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¡Bienvenido a PrinterBoy Punto De Venta!\n¿Qué haremos hoy?',
                          textScaler: TextScaler.linear(1.5),
                          style: TextStyle(
                            color: AppTheme.colorContraste.withAlpha(150),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Left and Right Menus
        SideMenuLeft(),
        SideMenuRight(height: height + 1),

        UsuarioOverlay(),

        // Connection Overlay
        const ConnectionOverlay(),
      ],
    );
  }
}

class UsuarioOverlay extends StatelessWidget {
  const UsuarioOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 200
            ),
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.secundario1,
              border: Border(
                top: BorderSide(
                  color: AppTheme.secundario1,
                  width: 5,
                  strokeAlign: BorderSide.strokeAlignOutside
                )
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(15),
                bottomRight: const Radius.circular(15)
              )
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'Sesión de ', 
                    textScaler: TextScaler.linear(0.8), 
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70
                    )
                  ),
                  Text(
                    Login.usuarioLogeado.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// WindowBar Widget
class WindowBar extends StatelessWidget {
  const WindowBar({super.key});

  @override
  Widget build(BuildContext context) {
    const double height = 35;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.secundario1,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
      ),
      child: WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  //Center(child: Text('                                  Login: {Usuario} ${Login.usuarioLogeado?.nombre ?? 'nA'}   <texto de prueba>', style: TextStyle(color: const Color.fromARGB(129, 255, 255, 255)))),
                  MoveWindow(),
                ],
              )
            ),
            WindowButtons(),
          ],
        ),
      ),
    );
  }
}