import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Configuracion extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}configuracion/';
  static late double dolar;
  static late int iva;
  static late bool esCaja;
  static late String nombrePC;
  static late String impresora;
  static late String cajaActual;
  bool init = false;
  bool loaded = false;
  bool configLoaded = false;

  
  Future<void> loadConfiguracion() async{
    init = true;

    //Obtener dolar e iva.
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final archivo = json.decode(resp.body);
      dolar = (archivo['precio_dolar'] as num).toDouble();
      iva = (archivo['iva'] as num).toInt();
      if (kDebugMode) {
        print('dolar e iva: $dolar & $iva');
      }
      
      //Obtener Configuracion de PC
      if (configLoaded==false){
        final directory = await getApplicationSupportDirectory();
        final file = File('${directory.path}/config.json');
        if (!file.existsSync()) {
          loaded = false;
          return;
        }
        final contents = await file.readAsString();
        final archivo = jsonDecode(contents);
        try {
          esCaja = archivo['es_caja'];
          nombrePC = archivo['nombre_pc'];
          final prefs = await SharedPreferences.getInstance();
          impresora = prefs.getString('selectedUsbDevice') ?? 'null';
          //impresora = archivo['impresora'];
        } catch (e) {
          loaded = false;
          return;
        }
        configLoaded=true;
      }
      loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}