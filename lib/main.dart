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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  await initializeDateFormatting('es_ES');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  Constantes.version = packageInfo.version;

  final productosService = ProductosServices();
  final clientesServices = ClientesServices();
  final ventasServices = VentasServices();
  final ventasEnvServices = VentasEnviadasServices();
  final sucursalesServices = SucursalesServices();
  final cotizacionesServices = CotizacionesServices();
  final impresoraServices = ImpresorasServices();
  final configuracion = Configuracion();
  final websocketService = WebSocketService(
    productosService, 
    clientesServices, 
    ventasServices, 
    ventasEnvServices,
    sucursalesServices,
    cotizacionesServices,
    configuracion, 
    impresoraServices,
  );

  doWhenWindowReady(() {
    const initialSize = Size(400, 640);
    appWindow.size = initialSize;
    appWindow.minSize = initialSize;
    appWindow.show();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: productosService),
        ChangeNotifierProvider.value(value: clientesServices),
        ChangeNotifierProvider.value(value: ventasServices),
        ChangeNotifierProvider.value(value: ventasEnvServices),
        ChangeNotifierProvider.value(value: sucursalesServices),
        ChangeNotifierProvider.value(value: cotizacionesServices),
        ChangeNotifierProvider.value(value: configuracion),
        ChangeNotifierProvider.value(value: impresoraServices),
        ChangeNotifierProvider.value(value: websocketService),
        ChangeNotifierProvider(create: (_) => UsuariosServices()),
        ChangeNotifierProvider(create: (_) => CajasServices()),
        ChangeNotifierProvider(create: (_) => ChangeTheme()),
        ChangeNotifierProvider(create: (_) => ModulosProvider()),
      ],
      child: const MyApp()
    )
  );
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

    /*WidgetsBinding.instance.addPostFrameCallback((_) {

    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final changeTheme = Provider.of<ChangeTheme>(context);
        AppTheme.initialize(changeTheme);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PBStation',
          initialRoute: 'login',
          routes: appRoutes,
          theme: changeTheme.isDarkTheme ? AppTheme.customThemeDark : AppTheme.customTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
        );
      }
    );
  }
}