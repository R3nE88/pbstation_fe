import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/routes/routes.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  

  runApp(const MyApp());

  doWhenWindowReady(() {
    //const initialSize = Size(400, 640);
    //appWindow.size = initialSize;
    //appWindow.minSize = initialSize;
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
        ChangeNotifierProvider(create: ( _ ) => ChangeTheme()),
        ChangeNotifierProvider(create: ( _ ) => ProductosServices()),
      ],
      child: Builder(
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
      ),
    );
  }
}
