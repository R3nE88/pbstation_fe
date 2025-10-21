import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/usuarios.dart';

class Login {
  final String _baseUrl = 'http:${Constantes.baseUrl}login';
  static late Usuarios usuarioLogeado;
  static late final bool isVendedor;
  static late final bool isAdmin;
  static late final bool isMaquila;
  static late final bool isSuper;
  bool isLoading = false;
    
  Future<bool> login(String correo, String psw) async {
    isLoading = true;
    final url = Uri.parse(_baseUrl);
    bool success = false;

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'tkn': Env.tkn
        },
        body: jsonEncode({
          'correo': correo,
          'psw': psw,
        }),
      );

      if (resp.statusCode == 200) {
        try {
          usuarioLogeado = Usuarios.fromJson(resp.body);
          usuarioLogeado.id = json.decode(resp.body)['id'];

          if (usuarioLogeado.rol == 'admin'){
            isVendedor = true;
            isMaquila = false;
            isAdmin = true;
            isSuper = false;
          } else if (usuarioLogeado.rol == 'maquila') {
            isVendedor = false;
            isMaquila = true;
            isAdmin = false;
            isSuper = false;
          } else if (usuarioLogeado.rol == 'super'){
            isVendedor = true;
            isMaquila = true;
            isAdmin = true;
            isSuper = true;
          } else {
            isVendedor = true;
            isMaquila = false;
            isAdmin = false;
            isSuper = false;
          }

          success = true;
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing JSON: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('Request failed with status: ${resp.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during HTTP request: $e');
      }
    } finally {
      isLoading = false;
    }

    return success;
  }

  Future<bool> permisoDeAdmin(String correo, String psw) async {
    final url = Uri.parse(_baseUrl);
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'tkn': Env.tkn
        },
        body: jsonEncode({
          'correo': correo,
          'psw': psw,
        }),
      );

      if (resp.statusCode == 200) {
        try {
          Usuarios user = Usuarios.fromJson(resp.body);
          if (user.rol=='admin' || user.rol=='super'){
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing JSON: $e');
          }
        }
      } 
    } catch (e) {
      if (kDebugMode) {
        print('Error during HTTP request: $e');
      }
    }
    return false;
  }
}