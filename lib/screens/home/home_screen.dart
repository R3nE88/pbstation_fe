// ignore_for_file: prefer_const_constructors

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/home_state.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double barraHeight = 35;
  late PageController _pageController;
  bool _showScreenInit = false;

  Future<void> esperarParaMostrar() async{
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _showScreenInit = true );
  }

  @override
  void initState() {
    super.initState();
    final modProv = context.read<ModulosProvider>();
    _pageController = PageController(initialPage: modProv.subModuloSeleccionado);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final websocketService = Provider.of<WebSocketService>(
        context,
        listen: false,
      );
      websocketService.conectar();

      if (_pageController.hasClients) {
        _pageController.jumpToPage(modProv.subModuloSeleccionado);
      }
    });

    esperarParaMostrar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modProv = context.watch<ModulosProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(modProv.subModuloSeleccionado);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HomeState.init) {
      HomeState.init = true;
      appWindow.minSize = const Size(1024, 720);
      appWindow.maxSize = const Size(1920, 1080);
      appWindow.maximize();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appWindow.maximize();
      });
    }
    
    final modProv = context.watch<ModulosProvider>();
    final height = MediaQuery.of(context).size.height - barraHeight;
    final screens = Modulos.modulosScreens[modProv.moduloSeleccionado] ?? <Widget>[];

    if (!_showScreenInit){
      return Scaffold(backgroundColor: AppTheme.backgroundColor);
    }

    return Consumer<ChangeTheme>(
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            
            Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Column(
                children: [
                  // Custom Window Bar
                  WindowBar(overlay: false),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      child: screens.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            modProv.seleccionarSubModulo(index); // Actualiza el índice seleccionado
                          },
                          itemCount: screens.length,
                          itemBuilder: (context, index) {
                            return screens[index];
                          },
                        )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¡Bienvenido a PrinterBoy Punto De Venta!\n¿Qué haremos hoy?',
                              textScaler:  TextScaler.linear(1.5),
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
            ConnectionOverlay()
          ],
        );
      },
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
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15)
              )
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sesión de ', 
                    textScaler: TextScaler.linear(0.8), 
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70
                    )
                  ),
                  Text(
                    Login.usuarioLogeado.nombre,
                    style: const TextStyle(
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

