import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class UsuariosServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}usuarios/';
  bool isLoading = false;

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

}