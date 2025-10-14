import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class ClientesServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}clientes/';
  List<Clientes> clientes = [];
  List<Clientes> filteredClientes = [];
  List<Clientes> clientesConAdeudo = [];
  late Map<String, Clientes> _clientesPorId;
  bool isLoading = false;
  bool loaded = false;

  //Esto es para mapear y buscar clientes//
  void cargarClientes(List<Clientes> nuevosClientes) {
    clientes = nuevosClientes;
    _clientesPorId = {
      for (var c in clientes) c.id!: c
    };
    notifyListeners();
  }

  String obtenerNombreClientePorId(String id) {
    return _clientesPorId[id]?.nombre ?? '¡no se encontró el cliente!';
  } //Aqui termina  para mapear y buscar clientes//

  //Para SearchField
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
  }//Aqui termina para SearchField

  //Metodos HTTPs
  Future<List<Clientes>> loadClientes() async { 
    if (loaded) return clientes;
    isLoading = true;
    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      clientes = listaJson.map<Clientes>((jsonElem) {
        final cli = Clientes.fromMap(jsonElem as Map<String, dynamic>);
        cli.id = (jsonElem as Map)['id']?.toString();
        return cli;
      }).toList();
      filteredClientes = clientes;

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    loaded = true;
    isLoading = false;
    cargarClientes(clientes);
    return clientes;
  }

  void loadACliente(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {'tkn': Env.tkn}
        );

        final body = json.decode(resp.body);
        final cli = Clientes.fromMap(body as Map<String, dynamic>);
        cli.id = (body as Map)['id']?.toString();
        clientes.add(cli);
        filteredClientes = clientes;

        isLoading = false;
        cargarClientes(clientes);
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el cliente!');
        }
      }
    }
  }

  Future<String?> createCliente(Clientes cliente) async {
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

        cargarClientes(clientes);
        return nuevo.id;
      } else {
        debugPrint('Error al crear cliente: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return 'error: ${body['detail']}';
      }
    } catch (e) {
      debugPrint('Exception en createCliente: $e');
      return 'error: Hubo un problema al crear el cliente.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCliente(String id) async{
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
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(
        url, headers: headers
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
    cliente.id = id;

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
        body: cliente.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Clientes.fromMap(data);
        updated.id = data['id']?.toString();
        clientes = clientes.map((cli) => cli.id == updated.id ? updated : cli).toList();

        filteredClientes = clientes;
        cargarClientes(clientes);
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
          url, headers: {'tkn': Env.tkn}
        );

        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Clientes.fromMap(data);
        updated.id = data['id']?.toString();
        clientes = clientes.map((cli) => cli.id == updated.id ? updated : cli).toList();
        filteredClientes = clientes;
        cargarClientes(clientes);
        
        isLoading = false;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el cliente!');
        }
        isLoading = false;
        notifyListeners();
      }
    }
  }

  List<Clientes> loadAdeudos(){
    clientesConAdeudo.clear();
    for (var cliente in clientes) {
      if (cliente.adeudos.isNotEmpty){
        clientesConAdeudo.add(cliente);
      }
    }
    return clientesConAdeudo;
  }

  Future<void> adeudarCliente (String clienteId, Adeudos adeudo) async {
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
      final url = Uri.parse('$_baseUrl$clienteId/adeudos');
      final resp = await http.post(
        url,
        headers: headers,
        body: adeudo.toJson(),   
      );

      if (resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Clientes.fromMap(data);
        updated.id = data['id']?.toString();
        clientes = clientes.map((cli) => cli.id == updated.id ? updated : cli).toList();
        filteredClientes = clientes;
      } else {
        debugPrint('Error al crear adeudo: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en adeudarCliente: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> quitarDeuda(String ventaId, String clienteId) async {
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
      final url = Uri.parse('$_baseUrl$clienteId/adeudos/$ventaId');
      final resp = await http.delete(
        url, 
        headers: headers
      );
      
      if (resp.statusCode == 202) {      
        // Función auxiliar para quitar adeudo de un cliente
        void quitarAdeudoDeCliente(List<Clientes> lista) {
          try {
            final cliente = lista.firstWhere((c) => c.id == clienteId);
            cliente.adeudos.removeWhere((adeudo) => adeudo.ventaId == ventaId);
          } catch (e) {
            // Cliente no encontrado en esta lista
          }
        }
        
        // Actualizar en todas las listas
        quitarAdeudoDeCliente(clientes);
        quitarAdeudoDeCliente(filteredClientes);
        quitarAdeudoDeCliente(clientesConAdeudo);
        
        // Solo eliminar de clientesConAdeudo si ya no tiene adeudos
        clientesConAdeudo.removeWhere((c) => 
          c.id == clienteId && c.adeudos.isEmpty
        );
      }
    } catch (e) {
      debugPrint('$e');
    } 
    notifyListeners();
  }
}