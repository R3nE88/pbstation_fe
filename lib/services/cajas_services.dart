import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CajasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}cajas/';
  static Cajas? cajaActual;
  static String? cajaActualId;
  List<MovimientoCajas> movimientos = [];
  bool init = false;
  bool loaded = false;
  bool isLoading = false;

  Future<void> initCaja() async{
    init = true;
    //obtener Caja
    final prefs = await SharedPreferences.getInstance();
    cajaActualId = prefs.getString('caja_id');
    if (cajaActualId!=null){
      loadCaja(cajaActualId!);
    }
    
    loaded = true;
    notifyListeners();
  }

  Future<Cajas?> loadCaja(String id) async {    
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final body = json.decode(resp.body);
      cajaActual = Cajas.fromMap(body as Map<String, dynamic>);
      cajaActual!.id = (body as Map)["id"]?.toString();
      await loadMovimientos();
    } catch (e) {
      isLoading = false;
      return null;
    }
    isLoading = false;
    return cajaActual;
  }

  Future<void> loadMovimientos() async{
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/movimientos');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final body = json.decode(resp.body) as List<dynamic>; // <-- Lista
      movimientos = body.map((item) {
        final mov = MovimientoCajas.fromMap(item as Map<String, dynamic>);
        mov.id = item["id"]?.toString();
        return mov;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoading = false;
    }
    isLoading = false;
  }

  Future<void> createCaja(Cajas caja) async {
    isLoading = true;
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: caja.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cajas.fromMap(data);
        nuevo.id = data['id']?.toString();

        //Guardar como caja actual la recien creada.
        cajaActual = nuevo;
        cajaActualId = cajaActual!.id;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('caja_id', cajaActualId!);

        if (kDebugMode) {
          print('caja creada!');
        }
      } else {
        debugPrint('Error al crear caja: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en createCaja: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> agregarMovimiento(MovimientoCajas movimiento) async {
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/movimientos');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: movimiento.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = MovimientoCajas.fromMap(data);
        nuevo.id = data['id']?.toString();

        movimientos.add(nuevo);
        notifyListeners();

        if (kDebugMode) {
          print('movimiento creado y agregado a caja!');
        }
      } else {
        debugPrint('Error al crear movimiento: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en agregarMovimiento: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /*Future<List<MovimientoCajas>> loadMovimientos() async{
    return [];
  }*/

  /*Future<void> actualizarCaja(Cajas caja) async{
    isLoading = true;
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: caja.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Cajas.fromMap(data);
        updated.id = data['id']?.toString();

        cajaActual = updated;

        notifyListeners();
      } else {
        debugPrint('Error al actualizar caja: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en updateCaja: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }*/

  void eliminarCajaActualSoloDePrueba() async{
    cajaActual = null;
    cajaActualId = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('caja_id');
    notifyListeners();
  }
}
