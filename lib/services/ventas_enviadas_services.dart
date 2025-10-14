import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class VentasEnviadasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}ventas_enviadas/';
  List<VentasEnviadas> ventas = [];
  bool isLoading = false;
  bool loaded = false;

  Future<List<VentasEnviadas>> ventasRecibidas() async { 
    if (!Configuracion.esCaja || loaded) return [];

    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventas = listaJson.map<VentasEnviadas>((jsonElem) {
        final x = VentasEnviadas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)['id']?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    loaded = true;
    isLoading = false;
    notifyListeners();
    return ventas;
  }

  void recibirVenta() async{
    ventas.clear();
    loaded=false;
    await ventasRecibidas();
  }

  Future<String> enviarVenta(VentasEnviadas venta) async {
    isLoading = true;
    
    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json', 
      'tkn': Env.tkn
    };
    //Para notificar a los demas, menos a mi mismo (websocket)
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }

    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: venta.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (kDebugMode) {
          print('venta enviada!');
        }
        return 'Exito';
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

  Future<bool> eliminarRecibida(String id, String sucursal) async{
    bool exito = false;

    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json', 
      'tkn': Env.tkn
    };
    //Para notificar a los demas, menos a mi mismo (websocket)
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }

    try {
      final url = Uri.parse('$_baseUrl$id?sucursal=$sucursal');
      final resp = await http.delete(
        url, headers: headers
        );
      if (resp.statusCode == 204){
        ventas.removeWhere((venta) => venta.id==id);
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }
}