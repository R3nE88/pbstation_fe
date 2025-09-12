import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';

class ImpresorasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}impresoras/';
  final String _baseUrlContador = 'http:${Constantes.baseUrl}contadores/';
  List<Impresoras> impresoras = [];
  Map<String, Contadores?> ultimosContadores = {};
  bool ultimosContadoresLoaded = false;
  bool isLoading = false;


  Future<List<Impresoras>> loadImpresoras(bool loadContadores) async {   
    isLoading = true;

    try {
      final url = Uri.parse('$_baseUrl${SucursalesServices.sucursalActualID}');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      impresoras = listaJson.map<Impresoras>((jsonElem) {
        final imp = Impresoras.fromMap(jsonElem as Map<String, dynamic>);
        imp.id = (jsonElem as Map)["id"]?.toString();
        return imp;
      }).toList();

      if (loadContadores){
        await loadUltimosContadores();
      }

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    isLoading = false;
    notifyListeners();
    return impresoras;
  }

  Future<void> loadUltimosContadores() async {
    ultimosContadoresLoaded = false;
    for (var impresora in impresoras){
      await loadUltimoContador(impresora.id!);
    }
    ultimosContadoresLoaded = true;
    //notifyListeners();
  }

  Future<void> loadUltimoContador(String impresoraId) async {
    try {
      final url = Uri.parse('${_baseUrlContador}ultimo/$impresoraId');
      final resp = await http.get(url, headers: {"tkn": Env.tkn});
      if (resp.statusCode == 200) {
        ultimosContadores[impresoraId] = Contadores.fromJson(resp.body);
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  //Retorna el ID
  Future<String> createImpresora(Impresoras impresora) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: impresora.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Impresoras.fromMap(data);
        nuevo.id = data['id']?.toString();

        impresoras.add(nuevo);
        if (kDebugMode) {
          print('impresora creada!');
        }
        return nuevo.id!;
      } else {
        debugPrint('Error al crear impresora: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createImpresora: $e');
      return 'Hubo un problema al crear la impresora.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createContador(Contadores contador) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrlContador);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: contador.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Contadores.fromMap(data);
        nuevo.id = data['id']?.toString();

        ultimosContadores[contador.impresoraId] =  nuevo;

        if (kDebugMode) {
          print('contador creada!');
        }
        return 'exito';
      } else {
        debugPrint('Error al crear contador: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createContador: $e');
      return 'Hubo un problema al crear el contador.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteImpresora(String id) async{
    bool exito = false;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(
        url, headers: {"tkn": Env.tkn}
        );
      if (resp.statusCode == 204){
        await deleteContadores(id);
        impresoras.removeWhere((impresora) => impresora.id==id);
        ultimosContadores.removeWhere((key, value) => key==id);
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  Future<bool> deleteContadores(String id) async{
    bool exito = false;
    try {
      final url = Uri.parse('$_baseUrlContador$id');
      final resp = await http.delete(
        url, headers: {"tkn": Env.tkn}
        );
      if (resp.statusCode == 204){

        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  Future<String> updateImpresora(Impresoras impresora, String id) async {
    isLoading = true;
    impresora.id = id;

    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: impresora.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Impresoras.fromMap(data);
        updated.id = data['id']?.toString();

        impresoras = impresoras.map((imp) => imp.id == updated.id ? updated : imp).toList();
        notifyListeners();
        return 'exito';
      } else {
        debugPrint('Error al actualizar impresora: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateImpresora: $e');
      return 'Hubo un problema al crear la impresora.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sumarContadores(List<Map<String, dynamic>> contadores) async{
    for (var contador in contadores) {
      await sumarContadorActual(contador['impresora'], contador['cantidad']);
    }
  }

  Future<void> sumarContadorActual(String impresoraId, int contador) async{
    try {
      final url = Uri.parse('${_baseUrlContador}actual/$impresoraId/$contador');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
      );
      debugPrint(resp.body);
    } catch (e) {
      debugPrint('Exception en actualzarContadorActual: $e');
    } finally {
    }
  }

  Future<void> actualzarContador(String impresoraId, int contador) async{
    try {
      final url = Uri.parse('$_baseUrlContador$impresoraId/$contador');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
      );
      debugPrint(resp.body);
    } catch (e) {
      debugPrint('Exception en actualzarContadorActual: $e');
    } finally {
    }
  }
}