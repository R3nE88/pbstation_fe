import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';

class VentasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}ventas/';
  List<Ventas> ventasDeCaja = [];
  List<Ventas> ventasDeCorteActual = [];
  List<VentasPorProducto> ventasPorProducto = [];

  bool isLoading = false;

  Future<void> loadVentasDeCaja(String cajaId) async {
    isLoading = true;

    await Future.delayed(Duration(milliseconds: 500));

    try {
      final url = Uri.parse('${_baseUrl}caja/$cajaId');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasDeCaja = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadVentasDeCorte(String corteId) async {
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}corte/$corteId');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasDeCorteActual.clear();
      ventasDeCorteActual = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadVentasDeCortePorProducto(String corteId) async { //TODO:
    isLoading = true;

    await Future.delayed(Duration(seconds: 1));

    try {
      final url = Uri.parse('${_baseUrl}corte/$corteId/por-producto');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasPorProducto = listaJson.map<VentasPorProducto>((jsonElem) {
        final x = VentasPorProducto.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<String> createVenta(Ventas venta) async {
    isLoading = true;

    try {
      final url = Uri.parse('$_baseUrl${CajasServices.corteActualId}');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: venta.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Ventas.fromMap(data);
        nuevo.id = data['id']?.toString();

        //ventas.add(nuevo);
        if (kDebugMode) {
          print('venta creada!');
        }
        return data['folio'];
      } else {
        debugPrint('Error al crear venta: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createVenta: $e');
      return 'Hubo un problema al crear la venta.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



}