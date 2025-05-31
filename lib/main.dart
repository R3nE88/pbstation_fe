import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/routes/routes.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  

  // 1️⃣ Creamos UNA instancia de ProductosServices
  final productosService = ProductosServices();

  // 2️⃣ Creamos el WebSocketService inyectándole esa misma instancia
  final websocketService = WebSocketService(productosService);

  runApp(
    MultiProvider(
      providers: [
        // Registramos la instancia de ProductosServices
        ChangeNotifierProvider.value(value: productosService),

        // Ahora creamos el WebSocketService pasándole la misma instancia
        ChangeNotifierProvider.value(value: websocketService),

        // Resto de providers
        ChangeNotifierProvider(create: (_) => UsuariosServices()),
        ChangeNotifierProvider(create: (_) => ChangeTheme()),
      ],
      child: const MyApp()
    )
  );

  doWhenWindowReady(() {
    //const initialSize = Size(400, 640);
    //appWindow.size = initialSize;
    //appWindow.minSize = initialSize;
    appWindow.show();
  });
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

    final websocketService = Provider.of<WebSocketService>(context, listen: false);
    websocketService.conectar(); // Conecta al arrancar la app
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
          initialRoute: 'home',//'login',
          routes: appRoutes,
          theme: changeTheme.isDarkTheme ? AppTheme.customThemeDark : AppTheme.customTheme, //AppTheme.customTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
        );
      }
    );
  }
}
