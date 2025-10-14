import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class ImpresorasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}impresoras/';
  final String _baseUrlContador = 'http:${Constantes.baseUrl}contadores/';
  List<Impresoras> impresoras = [];
  Map<String, Contadores?> ultimosContadores = {};
  bool ultimosContadoresLoaded = false;
  bool isLoading = false;
  bool loaded = false;

  Future<List<Impresoras>> loadImpresoras(bool loadCont, {bool overLoad = false}) async {   
    if (loaded && !overLoad) return [];
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}sucursal/${SucursalesServices.sucursalActualID}');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      impresoras = listaJson.map<Impresoras>((jsonElem) {
        final imp = Impresoras.fromMap(jsonElem as Map<String, dynamic>);
        imp.id = (jsonElem as Map)['id']?.toString();
        return imp;
      }).toList();

      if (loadCont){
        await loadContadores();
      }

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    isLoading = false;
    loaded = true;
    notifyListeners();
    return impresoras;
  }

  void loadAImpresora(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {'tkn': Env.tkn}
        );

        final body = json.decode(resp.body);
        final obj = Impresoras.fromMap(body as Map<String, dynamic>);
        obj.id = (body as Map)['id']?.toString();
        
        impresoras.add(obj);
        //await loadUltimoContador(obj.id!);

        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema en loadAImpreosra!: $e');
        }
      }
    }
  }

  Future<void> loadContadores() async {
    ultimosContadoresLoaded = false;
    for (var impresora in impresoras){
      await loadContador(impresora.id!);
    }
    ultimosContadoresLoaded = true;
  }

  Future<void> loadContador(String impresoraId) async {
    try {
      final url = Uri.parse('$_baseUrlContador$impresoraId');
      final resp = await http.get(url, headers: {'tkn': Env.tkn});
      if (resp.statusCode == 200) {
        ultimosContadores[impresoraId] = Contadores.fromJson(resp.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<String> createImpresora(Impresoras impresora) async {
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
        headers: headers,
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
      final url = Uri.parse('$_baseUrlContador${SucursalesServices.sucursalActualID}');

      final resp = await http.post(
        url,
        headers: headers,
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
      final url = Uri.parse('$_baseUrl$id/${SucursalesServices.sucursalActualID}');
      final resp = await http.delete(
        url, headers: headers
        );
      if (resp.statusCode == 204){
        await deleteContadores(id);
        impresoras.removeWhere((impresora) => impresora.id==id);
        
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  void deleteAImpresora(String id) {
    impresoras.removeWhere((producto) => producto.id==id);
    notifyListeners();
  }

  Future<bool> deleteContadores(String impresoraId) async{
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
      final url = Uri.parse('$_baseUrlContador$impresoraId/${SucursalesServices.sucursalActualID}');
      final resp = await http.delete(
        url, headers: headers
        );
      if (resp.statusCode == 204){
        deleteAContador(impresoraId);
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  void deleteAContador(String impresoraId){
    ultimosContadores.removeWhere((key, value) => key==impresoraId);
  }

  Future<String> updateImpresora(Impresoras impresora, String id) async {
    isLoading = true;
    impresora.id = id;

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
      final resp = await http.put(
        url,
        headers: headers,
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

  void updateAImpresora(String id)async{
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {'tkn': Env.tkn}
        );

        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Impresoras.fromMap(data);
        updated.id = data['id']?.toString();
        impresoras = impresoras.map((prod) => prod.id == updated.id ? updated : prod).toList();
        
        isLoading = false;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el producto!');
        }
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> sumarContadores(List<Map<String, dynamic>> contadores) async{
    for (var contador in contadores) {
      await sumarContador(contador['impresora'], contador['cantidad']);
    }
  }

  Future<void> sumarContador(String impresoraId, int contador) async{
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
      final url = Uri.parse('${_baseUrlContador}sumar/$impresoraId/${SucursalesServices.sucursalActualID}/$contador');
      final resp = await http.put(
        url,
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final actualizado = Contadores.fromMap(data);
        actualizado.id = data['id']?.toString();

        ultimosContadores[impresoraId] = actualizado;
        notifyListeners();
      } else {
        debugPrint('Error al sumar contador: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en actualzarContadorActual: $e');
    }
  }

  Future<void> actualzarContador(String impresoraId, int contador) async{
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
      final url = Uri.parse('$_baseUrlContador$impresoraId/${SucursalesServices.sucursalActualID}/$contador');
      final resp = await http.put(
        url,
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final actualizado = Contadores.fromMap(data);
        actualizado.id = data['id']?.toString();

        ultimosContadores[impresoraId] = actualizado;
        notifyListeners();
      } else {
        debugPrint('Error al actualizar contador: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en actualzarContadorActual: $e');
    } finally {
    }
  }

  void clear(){
    impresoras.clear();
    ultimosContadores.clear();
    ultimosContadoresLoaded = false;
    isLoading = false;
    loaded = false;
  }
}
