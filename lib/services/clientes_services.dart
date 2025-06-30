import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class ClientesServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}clientes/';
  List<Clientes> clientes = [];
  List<Clientes> filteredClientes = [];

  bool isLoading = false;

  void filtrarClientes(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      filteredClientes = clientes;
    } else {
      filteredClientes = clientes.where((cliente) {
        return cliente.nombre.toLowerCase().contains(query) ||
              (cliente.rfc ?? '').toLowerCase().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<List<Clientes>> loadClientes() async { 
    if (isLoading) { return clientes; }
    
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      clientes = listaJson.map<Clientes>((jsonElem) {
        final cli = Clientes.fromMap(jsonElem as Map<String, dynamic>);
        cli.id = (jsonElem as Map)["id"]?.toString();
        return cli;
      }).toList();
      filteredClientes = clientes;

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    isLoading = false;
    notifyListeners();
    return clientes;
  }

  void loadACliente(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final cli = Clientes.fromMap(body as Map<String, dynamic>);
        cli.id = (body as Map)["id"]?.toString();
        
        clientes.add(cli);
        filteredClientes = clientes;
        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el cliente!');
        }
      }
    }
  }

  Future<String> createCliente(Clientes cliente) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: cliente.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Clientes.fromMap(data);
        nuevo.id = data['id']?.toString();

        clientes.add(nuevo);
        filteredClientes = clientes;
        if (kDebugMode) {
          print('cliente creado!');
        }
        return 'exito';
      } else {
        debugPrint('Error al crear cliente: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createCliente: $e');
      return 'Hubo un problema al crear el cliente.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCliente(String id) async{
    bool exito = false;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(
        url, headers: {"tkn": Env.tkn}
      );
      if (resp.statusCode == 204){
        clientes.removeWhere((cliente) => cliente.id==id);
        filteredClientes = clientes;
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  void deleteACliente(String id) {
    clientes.removeWhere((cliente) => cliente.id==id);
    filteredClientes = clientes;
    notifyListeners();
  }

  Future<String> updateCliente(Clientes cliente, String id) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final body = json.encode({
          "id": id,
          "nombre": cliente.nombre,
          "correo": cliente.correo,
          "telefono": cliente.telefono,
          "razon_social": cliente.razonSocial,
          "rfc": cliente.rfc,
          "codigo_postal": cliente.codigoPostal,
          "direccion": cliente.direccion,
          "regimen_fiscal": cliente.regimenFiscal,
          "no_ext": cliente.noExt,
          "no_int": cliente.noInt,
          "colonia": cliente.colonia,
          "localidad": cliente.localidad
        });

      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: body,
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Clientes.fromMap(data);
        updated.id = data['id']?.toString();

        clientes = clientes.map((cli) => cli.id == updated.id ? updated : cli).toList();
        filteredClientes = clientes;
        notifyListeners();
        return 'exito';
      } else {
        debugPrint('Error al actualizar cliente: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateCliente: $e');
      return 'Hubo un problema al crear el cliente.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateACliente(String id)async{
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final cli = Clientes.fromMap(body as Map<String, dynamic>);
        cli.id = (body as Map)["id"]?.toString();

        clientes = clientes.map((cliente) {
          if (cliente.id == cli.id) {
            return cli;
          }
          return cliente;
        }).toList();
        filteredClientes = clientes;
        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el cliente!');
        }
      }
    }
  }
}