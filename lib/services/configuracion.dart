import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Configuracion extends ChangeNotifier {
  final String _baseUrl = 'http:${Constantes.baseUrl}configuracion/';
  static late double dolar;
  static late int iva;
  static String lastVersion = '0.0.0';
  static late bool esCaja;
  static late String nombrePC;
  static late String? impresora;
  static late String? size;
  static late String cajaActual;
  static late Cortes? memoryCorte;
  bool init = false;
  bool loaded = false;
  bool configLoaded = false;

  Future<void> loadConfiguracion() async {
    init = true;

    //Obtener dolar e iva.
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );
      final archivo = json.decode(resp.body);
      dolar = (archivo['precio_dolar'] as num).toDouble();
      iva = (archivo['iva'] as num).toInt();
      lastVersion = archivo['last_version'];

      //Obtener Configuracion de PC
      if (configLoaded == false) {
        final directory = await getApplicationSupportDirectory();
        final String fileName = Env.debug ? 'config_debug' : 'config';
        final file = File('${directory.path}/$fileName.json');
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
          impresora = prefs.getString('selectedUsbDevice');
          size = prefs.getString('selectedSize') ?? '58mm';
          final String? mc = prefs.getString('memory_corte');
          memoryCorte = mc != null ? Cortes.fromJson(mc) : null;
          //impresora = archivo['impresora'];
        } catch (e) {
          loaded = false;
          return;
        }
        configLoaded = true;
      }
      loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  /// Actualiza el precio del dólar
  Future<bool> actualizarPrecioDolar(double nuevoPrecio) async {
    try {
      final url = Uri.parse('${_baseUrl}precio-dolar');
      final resp = await http.put(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({'precio_dolar': nuevoPrecio}),
      );

      if (resp.statusCode == 200) {
        dolar = nuevoPrecio;
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          print('Error al actualizar precio dólar: ${resp.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar precio dólar: $e');
      }
      return false;
    }
  }

  /// Actualiza el porcentaje de IVA
  Future<bool> actualizarIva(int nuevoIva) async {
    try {
      final url = Uri.parse('${_baseUrl}iva');
      final resp = await http.put(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({'iva': nuevoIva}),
      );

      if (resp.statusCode == 200) {
        iva = nuevoIva;
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          print('Error al actualizar IVA: ${resp.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar IVA: $e');
      }
      return false;
    }
  }

  /// Actualiza la versión del sistema
  Future<bool> actualizarVersion(String nuevaVersion) async {
    try {
      final url = Uri.parse('${_baseUrl}version');
      final resp = await http.put(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({'last_version': nuevaVersion}),
      );

      if (resp.statusCode == 200) {
        lastVersion = nuevaVersion;
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          print('Error al actualizar versión: ${resp.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar versión: $e');
      }
      return false;
    }
  }
}
