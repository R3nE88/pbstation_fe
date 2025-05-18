import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsuariosServices extends ChangeNotifier{
  final String _baseUrl = 'http://127.0.0.1:8000/login';

    bool isLoading = false;

    
    Future<bool> login(String correo, String psw) async{
      final url = Uri.parse('$_baseUrl?correo=$correo&psw=$psw');
      try {
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          print(resp.body);
          return true;
        } else {
          print('Error en la petición: ${resp.statusCode}');
          return false;
        }
      } catch (e) {
        print('Error: $e');
        return false;
      }

    }

}