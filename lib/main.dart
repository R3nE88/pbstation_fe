import 'dart:async';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/routes/routes.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa en paralelo (OPTIMIZACIÓN SEGURA)
  await Future.wait([
    initializeDateFormatting('es_ES'),
    PackageInfo.fromPlatform().then((info) => Constantes.version = info.version),
    themePreferences()
  ]);

  // Tu código original de servicios
  final productosService = ProductosServices();
  final clientesServices = ClientesServices();
  final usuariosServices = UsuariosServices();
  final ventasServices = VentasServices();
  final ventasEnvServices = VentasEnviadasServices();
  final sucursalesServices = SucursalesServices();
  final cotizacionesServices = CotizacionesServices();
  final configuracion = Configuracion();
  final impresoraServices = ImpresorasServices();
  final pedidosServices = PedidosService();
  final websocketService = WebSocketService(
    productosService, 
    clientesServices, 
    usuariosServices,
    ventasServices, 
    ventasEnvServices,
    sucursalesServices,
    cotizacionesServices,
    configuracion, 
    impresoraServices,
    pedidosServices
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: productosService),
        ChangeNotifierProvider.value(value: clientesServices),
        ChangeNotifierProvider.value(value: usuariosServices),
        ChangeNotifierProvider.value(value: ventasServices),
        ChangeNotifierProvider.value(value: ventasEnvServices),
        ChangeNotifierProvider.value(value: sucursalesServices),
        ChangeNotifierProvider.value(value: cotizacionesServices),
        ChangeNotifierProvider.value(value: configuracion),
        ChangeNotifierProvider.value(value: impresoraServices),
        ChangeNotifierProvider.value(value: pedidosServices),
        ChangeNotifierProvider.value(value: websocketService),
        ChangeNotifierProvider(create: (_) => CajasServices()),
        ChangeNotifierProvider(create: (_) => ChangeTheme()),
        ChangeNotifierProvider(create: (_) => ModulosProvider()),
      ],
      child: const MyApp()
    )
  );

  // Ventana después de runApp (OPTIMIZACIÓN SEGURA)
  doWhenWindowReady(() {
    const initialSize = Size(400, 640);
    const maxSize = Size(600, 960);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.maxSize = maxSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

Future<void> themePreferences() async{
  final prefs = await SharedPreferences.getInstance();
  ThemePreferences.isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
    Provider.of<ChangeTheme>(context, listen: false).isDarkTheme = ThemePreferences.isDarkTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeTheme>(
      builder: (context, changeTheme, _) {
        AppTheme.initialize(changeTheme);
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PBStation',
          initialRoute: 'login',
          routes: appRoutes,
          theme: (changeTheme.isDarkTheme 
              ? AppTheme.customThemeDark.copyWith(
                shadowColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              )
              : AppTheme.customTheme).copyWith(
            shadowColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}
          ),
        );
      }
    );
  }
}

class ThemePreferences {
  static bool isDarkTheme = false;
}