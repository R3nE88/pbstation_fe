import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class UsuariosServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}usuarios/';
  List<Usuarios> usuarios = [];
  List<Usuarios> filteredUsuarios = [];
  late Map<String, Usuarios> _usuarioPorId;
  bool isLoading = false;
  bool loaded = false;

  //Esto es para mapear y buscar usuario//
  void cargarUsuarios(List<Usuarios> nuevosUsuarios) {
    usuarios = nuevosUsuarios;
    _usuarioPorId = {
      for (var c in usuarios) c.id!: c
    };
    notifyListeners();
  }
  
  String obtenerNombreUsuarioPorId(String id) {
    return _usuarioPorId[id]?.nombre ?? '¡no se encontró el usuario!';
  } //Aqui termina  para mapear y buscar usuarios//

  Future<Usuarios?> searchUsuario(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final usuario = Usuarios.fromMap(body as Map<String, dynamic>);
        usuario.id = (body as Map)["id"]?.toString();
        isLoading = false;
        return usuario;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el producto!');
        }
      }
    }
    return null;
  }

  //Para SearchField
  void filtrarUsuarios(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      filteredUsuarios = usuarios;
    } else {
      filteredUsuarios = usuarios.where((usuario) {
        return usuario.nombre.toLowerCase().contains(query);
      }).toList();
    }
    notifyListeners();
  }//Aqui termina para SearchField

  //Metodos HTTPs
  Future<List<Usuarios>> loadUsuarios() async { 
    if (loaded) return usuarios;
    isLoading = true;
    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      usuarios = listaJson.map<Usuarios>((jsonElem) {
        final cli = Usuarios.fromMap(jsonElem as Map<String, dynamic>);
        cli.id = (jsonElem as Map)["id"]?.toString();
        return cli;
      }).toList();
      filteredUsuarios = usuarios;

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    loaded = true;
    isLoading = false;
    cargarUsuarios(usuarios);
    return usuarios;
  }

  void loadAUsuario(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final usu = Usuarios.fromMap(body as Map<String, dynamic>);
        usu.id = (body as Map)["id"]?.toString();
        usuarios.add(usu);
        filteredUsuarios = usuarios;

        isLoading = false;
        cargarUsuarios(usuarios);
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar a usuario!');
        }
      }
    }
  }

  Future<String> createUsuario(Usuarios usuario) async {
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
        body: usuario.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Usuarios.fromMap(data);
        nuevo.id = data['id']?.toString();

        usuarios.add(nuevo);
        filteredUsuarios = usuarios;
        if (kDebugMode) {
          print('usuario creado!');
        }
        return 'exito';
      } else {
        debugPrint('Error al crear usuario: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createUsuario: $e');
      return 'Hubo un problema al crear el usuario.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUsuario(String id) async{
    bool exito = false;

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
        url, headers: headers,
      );
      if (resp.statusCode == 204){
        usuarios.removeWhere((usuario) => usuario.id==id);
        filteredUsuarios = usuarios;
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  void deleteAUsuario(String id) {
    usuarios.removeWhere((usuario) => usuario.id==id);
    filteredUsuarios = usuarios;
    notifyListeners();
  }

  Future<String> updateUsuario(Usuarios usuario, String id) async {
    isLoading = true;
    usuario.id = id;

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
        body: usuario.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Usuarios.fromMap(data);
        updated.id = data['id']?.toString();
        usuarios = usuarios.map((cli) => cli.id == updated.id ? updated : cli).toList();

        filteredUsuarios = usuarios;
        notifyListeners();
        return 'exito';
      } else {
        debugPrint('Error al actualizar usuario: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateUsuario: $e');
      return 'Hubo un problema al crear el usuario.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarPsw(String usuarioId, String newPsw) async {
    Map<String, String> datos = {"id": usuarioId, "nueva_psw":newPsw};

    try {
      final url = Uri.parse('${_baseUrl}cambiar-password');
      final resp = await http.patch(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: json.encode(datos),
      );

      if (resp.statusCode==200){
        return true;
      } else {
        return false;
      }
      
    } catch (e){
      debugPrint('catch');
      debugPrint('$e');
      return false;
    }
  }

  void updateAUsuario(String id)async{
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Usuarios.fromMap(data);
        updated.id = data['id']?.toString();
        usuarios = usuarios.map((cli) => cli.id == updated.id ? updated : cli).toList();
        filteredUsuarios = usuarios;

        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema: updateAUsuario!');
        }
      }
    }
  }
}