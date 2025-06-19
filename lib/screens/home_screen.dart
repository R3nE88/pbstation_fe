import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
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
    const size = Size(1024, 720);
    appWindow.minSize = size;
    appWindow.maximize();

    final double barraHeight = 35;
    final modProv = context.watch<ModulosProvider>();
    final height = MediaQuery.of(context).size.height - barraHeight;
    final screens = Modulos.modulosScreens[modProv.moduloSeleccionado] ?? <Widget>[];

    return Stack(
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
                        Image.asset(
                          'assets/images/logo2.png',
                          height: 200,
                          color: AppTheme.colorContraste.withAlpha(150),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '¡Bienvenido a PrinterBoyStation!\n¿Qué haremos hoy?',
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

        // Connection Overlay
        const ConnectionOverlay(),
      ],
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