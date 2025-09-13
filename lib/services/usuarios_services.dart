import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class UsuariosServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}usuarios/';
  List<Usuarios> usuarios = [];
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

}