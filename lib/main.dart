import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/routes/routes.dart';
import 'package:pbstation_frontend/services/usuarios_services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();  

  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(400, 640);
    appWindow.size = initialSize;
    appWindow.minSize = initialSize;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ( _ ) => UsuariosServices()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
         
        title: 'SASTI',
        initialRoute: 'login',
        routes: appRoutes,
        theme: AppTheme.customTheme,
        scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
      ),
    );
  }
}
