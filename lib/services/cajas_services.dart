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
  bool forLogininit = false;
  bool forLoginloaded = false;
  bool isLoading = false;

  static Cortes? corteActual;
  static String? corteActualId;
  List<Cortes> cortesDeCaja = [];
  bool cortesDeCajaIsLoading = false;
  bool cortesDeCajaIsLoaded = false;
  List<MovimientosCajas> movimientos = [];

  Future<void> initCaja() async{
    forLogininit = true;
    //obtener Caja
    final prefs = await SharedPreferences.getInstance();
    cajaActualId = prefs.getString('caja_id');
    if (cajaActualId!=null && cajaActualId!='buscando'){
      loadCaja(cajaActualId!);
    }
    
    forLoginloaded = true;
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
      await loadUltimoCorte();
      await loadMovimientos();
    } catch (e) {
      cajaActualId = 'buscando';
      isLoading = false;
      return null;
    }
    isLoading = false;
    return cajaActual;
  }

  Future<void> loadUltimoCorte() async{
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes/ultimo');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final body = json.decode(resp.body);
      //solo obtener corte que no se a finalizado
      if (Cortes.fromMap(body as Map<String, dynamic>).fechaCorte==null){
        corteActual = Cortes.fromMap(body);
        corteActual!.id = (body as Map)["id"]?.toString();
        corteActualId = corteActual!.id;
      }
    } catch (e) {
      isLoading = false;
    }
    isLoading = false;
  }

  Future<void> loadCortesDeCaja() async{
    if (cajaActualId==null) return;

    if (cortesDeCajaIsLoaded) return;
    cortesDeCajaIsLoading = true;
    await Future.delayed(Duration(milliseconds: 250));
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes/all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      
      final List<dynamic> listaJson = json.decode(resp.body);
      cortesDeCaja = listaJson.map<Cortes>((jsonElem) {
        final cor = Cortes.fromMap(jsonElem as Map<String, dynamic>);
        cor.id = (jsonElem as Map)["id"]?.toString();
        return cor;
      }).toList(); 

    } catch (e) {
      cortesDeCajaIsLoading = false;
    }
    cortesDeCajaIsLoaded = true;
    cortesDeCajaIsLoading = false;
    notifyListeners();
  }

  Future<void> loadMovimientos() async{
    if (corteActualId==null) return;
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$corteActualId/movimientos');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final body = json.decode(resp.body) as List<dynamic>; // <-- Lista
      movimientos = body.map((item) {
        final mov = MovimientosCajas.fromMap(item as Map<String, dynamic>);
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

  Future<void> createCorte(Cortes corte) async {
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: corte.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cortes.fromMap(data);
        nuevo.id = data['id']?.toString();

        //Guardar como caja actual la recien creada.
        corteActual = nuevo;
        corteActualId = corteActual!.id;
        cajaActual!.cortesIds.add(corteActualId!);
        cortesDeCaja.add(nuevo);
        /*final prefs = await SharedPreferences.getInstance();
        prefs.setString('caja_id', cajaActualId!);*/

        if (kDebugMode) {
          print('corte creado!');
        }
      } else {
        debugPrint('Error al crear corte: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en createCorte: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> agregarMovimiento(MovimientosCajas movimiento) async {
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$corteActualId/movimientos');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: movimiento.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = MovimientosCajas.fromMap(data);
        nuevo.id = data['id']?.toString();

        movimientos.add(nuevo);
        corteActual!.movimientoCaja.add(nuevo);
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

  Future<void> cerrarCaja(Cajas caja) async{
    isLoading = true;
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: caja.toJson(),
      );

      if (resp.statusCode == 204) {
        cajaActual = null;
        cajaActualId = null;
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('caja_id');
      } else {
        debugPrint('Error al actualizar caja: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en updateCaja: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarCorte(Cortes corte, String id) async{
    isLoading = true;
    corte.id = id;
    
    try {
      final url = Uri.parse('${_baseUrl}cortes');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: corte.toJson(),
      );

      if (resp.statusCode != 204) {
         debugPrint('Error al actualizar corte: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en updateCaja: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void eliminarCajaActualSoloDePrueba() async{
    cajaActual = null;
    cajaActualId = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('caja_id');
    notifyListeners();
  }
}