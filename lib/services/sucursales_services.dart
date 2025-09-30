import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class SucursalesServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}sucursales/';
  List<Sucursales> sucursales = [];
  Sucursales? sucursalActual;
  static String? sucursalActualID;
  Map<String, Sucursales> _sucursalesPorId = {};
  bool isLoading = false;
  bool loaded = false;
  bool init = false;
  bool sucursalError = false;

  SucursalesServices(){
    if (init==false){
      init=true;
      obtenerSucursalId();
    }
  }

  //Esto es para mapear y buscar sucursal//
  void cargarSucursales(List<Sucursales> nuevasSucursales) {
    sucursales = nuevasSucursales;
    _sucursalesPorId = {
      for (var c in sucursales) c.id!: c
    };
    notifyListeners();
  }
  
  String obtenerNombreSucursalPorId(String id) {
    return _sucursalesPorId[id]?.nombre ?? '¡no se encontró la sucursal!';
  } //Aqui termina  para mapear y buscar sucursales//

  Future<void> obtenerSucursalId() async {
    if (init==false) return;
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/config.json');

      if (!await file.exists()) {
        sucursalError = true;
        notifyListeners();
        if (kDebugMode) {
          print('⚠️ El archivo config.json no existe.');
        }
        return;
      }

      final contenido = await file.readAsString();
      final config = jsonDecode(contenido) as Map<String, dynamic>;

      if (config.containsKey('sucursal')) {
        sucursalActualID = config['sucursal'].toString();
        loadSucursales();
      } else {
        if (kDebugMode) {
          print('⚠️ El campo "sucursal" no existe en el JSON.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al leer sucursal: $e');
      }
    }
  }

  Future<void> establecerSucursal(Sucursales sucursal) async{
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/config.json');
    if (kDebugMode) {
      print('Ruta del archivo: ${file.path}');
    }

    Map<String, dynamic> config = {};

    if (await file.exists()) {
      final contenido = await file.readAsString();
      try {
        config = jsonDecode(contenido);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error al decodificar JSON, usando mapa vacío: $e');
        }
      }
    }

    // Actualiza o agrega el campo "sucursal"
    config['sucursal'] = sucursal.id;

    // Guarda el archivo actualizado
    final jsonActualizado = const JsonEncoder.withIndent('  ').convert(config);
    await file.writeAsString(jsonActualizado);

    if (kDebugMode) {
      print('✅ Sucursal establecida como: ${sucursal.id}');
    }

    sucursalActual = sucursales.firstWhere((element) => element.id == sucursal.id);
    sucursalActualID = sucursalActual!.id;
    WebSocketService.reconectarConSucursal();
    notifyListeners();
  }

  Future<void> desvincularSucursal(bool miSucursal) async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/config.json');
    if (kDebugMode) {
      print('Ruta del archivo: ${file.path}');
    }

    Map<String, dynamic> config = {};

    if (await file.exists()) {
      final contenido = await file.readAsString();
      try {
        config = jsonDecode(contenido);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error al decodificar JSON, usando mapa vacío: $e');
        }
      }
    }

    // Elimina el campo "sucursal" si existe
    config.remove('sucursal');

    // Guarda el archivo actualizado
    final jsonActualizado = const JsonEncoder.withIndent('  ').convert(config);
    await file.writeAsString(jsonActualizado);

    if (kDebugMode) {
      print('✅ Sucursal eliminada del archivo config.json');
    }
    
    // Si es mi sucursal, limpiar
    if (miSucursal){
      sucursalActual = null;
      sucursalActualID = null;
      WebSocketService.reconectarSinSucursal();
    }
    
    notifyListeners();
  }

  Future<List<Sucursales>> loadSucursales() async { 
    if (loaded) return [];
    isLoading = true;
    
    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      sucursales = listaJson.map<Sucursales>((jsonElem) {
        final suc = Sucursales.fromMap(jsonElem as Map<String, dynamic>);
        suc.id = (jsonElem as Map)["id"]?.toString();
        return suc;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }

    if (sucursalActualID!=null && sucursalActual==null){
      try {
        sucursalActual = sucursales.firstWhere((element) => element.id == sucursalActualID);
      } catch (e) { sucursalActual = null; }
    }
    
    isLoading = false;
    loaded = true;
    cargarSucursales(sucursales);
    notifyListeners();
    return sucursales;
  }

  void loadASucursal(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final suc = Sucursales.fromMap(body as Map<String, dynamic>);
        suc.id = (body as Map)["id"]?.toString();
        sucursales.add(suc);
        isLoading = false;
        cargarSucursales(sucursales);

      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar a sucursal!');
        }
      }
    }
  }

  Future<String> createSucursal(Sucursales sucursal) async {
    isLoading = true;

    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json', 
      "tkn": Env.tkn
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
        body: sucursal.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Sucursales.fromMap(data);
        nuevo.id = data['id']?.toString();

        sucursales.add(nuevo);
        if (kDebugMode) {
          print('sucursal creada!');
        }
        return 'exito';
      } else {
        debugPrint('Error al crear sucursal: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createSucursal: $e');
      return 'Hubo un problema al crear sucursal.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSucursal(String id) async{
    Sucursales sucursal = sucursales.firstWhere((element) => element.id == id);
    sucursal.id = id;

    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json', 
      "tkn": Env.tkn
    };
    //Para notificar a los demas, menos a mi mismo (websocket)
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }

    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(
        url,
        headers: headers,
        body: sucursal.toJson(),
      );
      if (resp.statusCode == 204){
        deleteASucursal(id);
        desvincularSucursal(id == sucursalActualID);
      }
    }
    catch (e){
      debugPrint('error en deleteSucursal: $e');
      return false;
    }
    return true;
  }

  void deleteASucursal(String id) {
    sucursales.removeWhere((sucursal) => sucursal.id==id);
    desvincularSucursal(id == sucursalActualID);
    notifyListeners();
  }

  Future<String> updateSucursal(Sucursales sucursal, String id) async {
    isLoading = true;
    sucursal.id = id;

    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json', 
      "tkn": Env.tkn
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
        body: sucursal.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Sucursales.fromMap(data);
        updated.id = data['id']?.toString();
        sucursales = sucursales.map((cli) => cli.id == updated.id ? updated : cli).toList();

        //Si es mi sucursal actualizar mis datos
        if (sucursalActualID!=null){
          if (sucursalActualID! == id){
            sucursalActual = updated;
            sucursalActualID = id;
            sucursalActual!.id = sucursalActualID;
          }
        }
        notifyListeners();

        return 'exito';
      } else {
        debugPrint('Error al actualizar sucursal: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateSucursal: $e');
      return 'Hubo un problema al actualizar sucursal.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateASucursal(String id)async{
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Sucursales.fromMap(data);
        updated.id = data['id']?.toString();
        sucursales = sucursales.map((cli) => cli.id == updated.id ? updated : cli).toList();

        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al actualizar a sucursal');
        }
      }
    }
  }
}