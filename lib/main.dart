import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/routes/routes.dart';
import 'package:pbstation_frontend/theme/theme.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();  

  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1024, 720);
    appWindow.minSize = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.maximize();
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       
      title: 'SASTI',
      initialRoute: 'home',
      routes: appRoutes,
      theme: AppTheme.customTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
    );
  }
}
