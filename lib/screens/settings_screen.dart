import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:pbstation_frontend/services/configuracion.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final changeTheme = Provider.of<ChangeTheme>(context);

    Future<String> getConfigFilePath() async {
      final directory = await getApplicationSupportDirectory();
      //final file = File('${directory.path}/config.json');
      return directory.path;//file.path;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Switch(value: changeTheme.isDarkTheme, onChanged: ( value ){
          changeTheme.isDarkTheme = value;
        }),
        ElevatedButton(
          onPressed: () async{
            String ruta = await getConfigFilePath();
            if (kDebugMode) {
              print(ruta);
            }
          }, 
          child: Text('Ruta de datos')
        ),
        ElevatedButton(
          onPressed: () async{
            final config = Provider.of<Configuracion>(context, listen: false);
            config.loadConfiguracion();
          }, 
          child: Text('Leer datos de Configuracion')
        )
      ],
    );
  }
}