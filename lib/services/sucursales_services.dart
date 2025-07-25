import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class SucursalesServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}sucursales/';
  List<Sucursales> sucursales = [];
  Sucursales? sucursalActual;
  static String? sucursalActualID;
  late Map<String, Sucursales> _sucursalesPorId;
  bool isLoading = false;
  bool init = true;

  SucursalesServices(){
    if (init==true){
      init=false;
      obtenerSucursalId();
    }
  }

  //Esto es para mapear y buscar sucursal//
  void cargarSucursales(List<Sucursales> nuevasSucursales) {
    sucursales = nuevasSucursales;
    _sucursalesPorId= {
      for (var c in sucursales) c.id!: c
    };
    notifyListeners();
  }
  String obtenerNombreSucursalPorId(String id) {
    return _sucursalesPorId[id]?.nombre ?? '¡no se encontró la sucursal!';
  } //Aqui termina  para mapear y buscar sucursales//

  Future<void> obtenerSucursalId() async {
    print('obtrener Sucursal Id');
    if (init==true) return;
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/config.json');

      if (!await file.exists()) {
        //TODO: Mostrar mensaje de que hubo un problema con la configuracion para inicializar la 'terminal' o algo asi pro xd
        if (kDebugMode) {
          print('⚠️ El archivo config.json no existe.');
        }
      }

      final contenido = await file.readAsString();
      final config = jsonDecode(contenido) as Map<String, dynamic>;

      if (config.containsKey('sucursal')) {
        sucursalActualID = config['sucursal'].toString();
        loadSucursales();
      } else {
        if (kDebugMode) {
          print('⚠️ El campo \"sucursal\" no existe en el JSON.');
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
    print('Ruta del archivo: ${file.path}');

    Map<String, dynamic> config = {};

    if (await file.exists()) {
      final contenido = await file.readAsString();
      try {
        config = jsonDecode(contenido);
      } catch (e) {
        print('⚠️ Error al decodificar JSON, usando mapa vacío: $e');
      }
    }

    // Actualiza o agrega el campo "sucursal"
    config['sucursal'] = sucursal.id; // o sucursal.idSucursal, según tu modelo

    // Guarda el archivo actualizado
    final jsonActualizado = const JsonEncoder.withIndent('  ').convert(config);
    await file.writeAsString(jsonActualizado);

    print('✅ Sucursal establecida como: ${sucursal.id}');
    print(sucursales.length);

    sucursalActual = sucursales.firstWhere((element) => element.id == sucursal.id);
    sucursalActualID = sucursalActual!.id;
    notifyListeners();
  }


  Future<List<Sucursales>> loadSucursales() async { 
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

    try {
      final url = Uri.parse(_baseUrl);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
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
    //SET ACTIVO EN FALSE
    return false;
  }


  Future<String> updateSucursal(Sucursales sucursal, String id) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final body = json.encode({
          "id": id,
          "nombre": sucursal.nombre,
          "correo": sucursal.correo,
          "telefono": sucursal.telefono,
          "direccion": sucursal.direccion,
          "localidad": sucursal.localidad,
          "activo": sucursal.activo,
        });

      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: body,
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Sucursales.fromMap(data);
        updated.id = data['id']?.toString();

        sucursales = sucursales.map((cli) => cli.id == updated.id ? updated : cli).toList();
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

        final body = json.decode(resp.body);
        final suc = Sucursales.fromMap(body as Map<String, dynamic>);
        suc.id = (body as Map)["id"]?.toString();

        sucursales = sucursales.map((sucursal) {
          if (sucursal.id == suc.id) {
            return suc;
          }
          return sucursal;
        }).toList();
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