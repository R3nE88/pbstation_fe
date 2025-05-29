import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/models/usuario.dart';

class Login {
  final String _baseUrl = 'http://127.0.0.1:8000/login';
  static Usuario? usuarioLogeado;

  bool isLoading = false;
    
  Future<bool> login(String correo, String psw) async {
    isLoading = true;
    final url = Uri.parse(_baseUrl);
    bool success = false;

    try {
      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "correo": correo,
          "psw": psw,
        }),
      );

      if (resp.statusCode == 200) {
        try {
          usuarioLogeado = Usuario.fromJson(resp.body);
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

}