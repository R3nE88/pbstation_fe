// ignore_for_file: prefer_const_constructors

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/home_state.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/loading_overlay.dart';
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
  int _ultimaPaginaNavegada = -1;
  bool _navegacionEnProgreso = false;

  Future<void> esperarParaMostrar() async {
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _showScreenInit = true);
  }

  @override
  void initState() {
    super.initState();
    final modProv = context.read<ModulosProvider>();
    _pageController = PageController(initialPage: modProv.subModuloSeleccionado);
    _ultimaPaginaNavegada = modProv.subModuloSeleccionado;

    // Escuchar cambios del provider
    modProv.addListener(_onModuloChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final websocketService = Provider.of<WebSocketService>(
        context,
        listen: false,
      );
      websocketService.conectar();
    });

    esperarParaMostrar();
  }

  void _onModuloChanged() {
    if (_navegacionEnProgreso) return; // Evitar navegaciones simultáneas
    
    final modProv = context.read<ModulosProvider>();
    final nuevaPagina = modProv.subModuloSeleccionado;
    
    // Solo navegar si realmente cambió y el controller está listo
    if (_pageController.hasClients && 
        nuevaPagina != _ultimaPaginaNavegada &&
        nuevaPagina >= 0 &&
        nuevaPagina < modProv.subModulosActuales.length) {
      
      _navegacionEnProgreso = true;
      _ultimaPaginaNavegada = nuevaPagina;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(nuevaPagina);
          _navegacionEnProgreso = false;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mantener vacío
  }

  @override
  void dispose() {
    final modProv = context.read<ModulosProvider>();
    modProv.removeListener(_onModuloChanged);
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
    
    final subModulos = modProv.subModulosActuales;
    final screens = subModulos.map((sub) => sub.pantalla).toList();

    if (!_showScreenInit) {
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
                  WindowBar(overlay: false),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 30),
                      child: screens.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (index) {

                                if (!_navegacionEnProgreso && 
                                    modProv.subModuloSeleccionado != index) {
                                  _navegacionEnProgreso = true;
                                  _ultimaPaginaNavegada = index;
                                  
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    modProv.seleccionarSubModulo(index);
                                    _navegacionEnProgreso = false;
                                  });
                                }
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
                                    textScaler: TextScaler.linear(1.5),
                                    style: TextStyle(
                                      color: AppTheme.colorContraste
                                          .withAlpha(150),
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

            SideMenuLeft(),
            SideMenuRight(height: height + 1),
            UsuarioOverlay(),
            ConnectionOverlay(),
            LoadingOverlay()
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
            constraints: const BoxConstraints(minWidth: 200),
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.secundario1,
              border: Border(
                top: BorderSide(
                  color: AppTheme.secundario1,
                  width: 5,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
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
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    Login.usuarioLogeado.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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