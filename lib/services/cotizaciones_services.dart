import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/auth_service.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:provider/provider.dart';

class CotizacionesServices extends ChangeNotifier {
  final String _baseUrl = '${Constantes.baseUrl}cotizaciones/';
  List<Cotizaciones> cotizaciones = [];
  List<Cotizaciones> filteredCotizaciones = [];
  List<Cotizaciones> vencidas = [];
  List<Cotizaciones> filteredVencidas = [];
  bool todasLasSucursales = false;
  bool isLoading = false;
  bool loaded = false;

  //Para SearchField
  void filtrarCotizaciones(String query, context) {
    final List<Clientes> clientes =
        Provider.of<ClientesServices>(context, listen: false).clientes;
    final sucursalId = SucursalesServices.sucursalActualID;
    query = query.toLowerCase().trim();

    // Base: filtrar por sucursal si es necesario
    List<Cotizaciones> filtradas =
        todasLasSucursales
            ? cotizaciones
            : cotizaciones.where((c) => c.sucursalId == sucursalId).toList();

    if (query.isEmpty) {
      filteredCotizaciones = obtenerFilter(false);
    } else {
      filteredCotizaciones =
          filtradas.where((cotizacion) {
            final folioMatch =
                cotizacion.folio?.toLowerCase().contains(query) ?? false;
            // Buscar cliente correspondiente
            final cliente = clientes.firstWhere(
              (c) => c.id == cotizacion.clienteId,
              orElse: () => Clientes(nombre: 'error', adeudos: []),
            );
            final nombreMatch = cliente.nombre.toLowerCase().contains(query);

            return folioMatch || nombreMatch;
          }).toList();
    }
    notifyListeners();
  }

  void filtrarVencidas(String query, context) {
    final List<Clientes> clientes =
        Provider.of<ClientesServices>(context, listen: false).clientes;
    final sucursalId = SucursalesServices.sucursalActualID;
    query = query.toLowerCase().trim();

    // Base: filtrar por sucursal si es necesario
    List<Cotizaciones> filtradas =
        todasLasSucursales
            ? vencidas
            : vencidas.where((c) => c.sucursalId == sucursalId).toList();

    if (query.isEmpty) {
      filteredVencidas = obtenerFilter(true);
    } else {
      filteredVencidas =
          filtradas.where((cotizacion) {
            final folioMatch =
                cotizacion.folio?.toLowerCase().contains(query) ?? false;
            // Buscar cliente correspondiente
            final cliente = clientes.firstWhere(
              (c) => c.id == cotizacion.clienteId,
              orElse: () => Clientes(nombre: 'error', adeudos: []),
            );
            final nombreMatch = cliente.nombre.toLowerCase().contains(query);

            return folioMatch || nombreMatch;
          }).toList();
    }
    notifyListeners();
  } //Aqui termina para SearchField

  List<Cotizaciones> obtenerFilter(bool isVencidas) {
    if (todasLasSucursales) {
      return isVencidas ? vencidas : cotizaciones;
    } else {
      final sucursalId = SucursalesServices.sucursalActualID;
      return isVencidas
          ? vencidas
              .where((element) => element.sucursalId == sucursalId)
              .toList()
          : cotizaciones
              .where((element) => element.sucursalId == sucursalId)
              .toList();
    }
  }

  void recargarFilters() {
    filteredCotizaciones = obtenerFilter(false);
    filteredVencidas = obtenerFilter(true);
    notifyListeners();
  }

  Future<List<Cotizaciones>> loadCotizaciones({bool force = false}) async {
    if (loaded && !force) return [];
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );

      if (resp.statusCode != 200) {
        debugPrint('Error al cargar cotizaciones: ${resp.statusCode}');
        isLoading = false;
        notifyListeners();
        return [];
      }

      final List<dynamic> listaJson = json.decode(resp.body);

      // Reiniciar listas antes de agregar nuevas
      cotizaciones = [];
      vencidas = [];

      for (var jsonElem in listaJson) {
        final data = jsonElem as Map<String, dynamic>;
        final cotizacion = Cotizaciones.fromMap(data);
        cotizacion.id = data['id']?.toString();

        if (cotizacion.vigente == false) {
          vencidas.add(cotizacion);
        } else {
          cotizaciones.add(cotizacion);
        }
      }
      filteredCotizaciones = obtenerFilter(false);
      filteredVencidas = obtenerFilter(true);

      isLoading = false;
      loaded = true;
      notifyListeners();
      return [...cotizaciones, ...vencidas];
    } catch (e) {
      debugPrint('Exception en loadCotizaciones: $e');
      isLoading = false;
      notifyListeners();
      return [];
    }
  }

  void loadACotizacion(id) async {
    if (isLoading) return;
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );

      if (resp.statusCode != 200) {
        debugPrint('Error al cargar cotizacion: ${resp.statusCode}');
        isLoading = false;
        notifyListeners();
        return;
      }

      final body = json.decode(resp.body);
      final cot = Cotizaciones.fromMap(body as Map<String, dynamic>);
      cot.id = (body as Map)['id']?.toString();

      // Prevenir duplicados
      if (cotizaciones.any((c) => c.id == cot.id) ||
          vencidas.any((c) => c.id == cot.id)) {
        isLoading = false;
        return;
      }

      if (cot.vigente == false) {
        vencidas.add(cot);
      } else {
        cotizaciones.add(cot);
      }
      filteredCotizaciones = obtenerFilter(false);
      filteredVencidas = obtenerFilter(true);

      notifyListeners();
    } catch (e) {
      debugPrint('Exception en loadACotizacion: $e');
    } finally {
      isLoading = false;
    }
  }

  void deleteACotizacion(String id) {
    cotizaciones.removeWhere((c) => c.id == id);
    vencidas.removeWhere((c) => c.id == id);
    filteredCotizaciones = obtenerFilter(false);
    filteredVencidas = obtenerFilter(true);
    notifyListeners();
  }

  void updateACotizacion(String id) async {
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );

      if (resp.statusCode != 200) return;

      final body = json.decode(resp.body);
      final cot = Cotizaciones.fromMap(body as Map<String, dynamic>);
      cot.id = (body as Map)['id']?.toString();

      // Eliminar la versión anterior
      cotizaciones.removeWhere((c) => c.id == cot.id);
      vencidas.removeWhere((c) => c.id == cot.id);

      // Agregar la versión actualizada
      if (cot.vigente == false) {
        vencidas.add(cot);
      } else {
        cotizaciones.add(cot);
      }
      filteredCotizaciones = obtenerFilter(false);
      filteredVencidas = obtenerFilter(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Exception en updateACotizacion: $e');
    }
  }

  Future<Cotizaciones?> createCotizacion(Cotizaciones cotizacion) async {
    isLoading = true;

    final connectionId = WebSocketService.connectionId;
    final headers = {
      'Content-Type': 'application/json',
      ...AuthService.getAuthHeaders(),
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
        body: cotizacion.toJson(),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cotizaciones.fromMap(data);
        nuevo.id = data['id']?.toString();
        nuevo.folio = data['folio']?.toString();

        cotizaciones.add(nuevo);
        filteredCotizaciones = obtenerFilter(false);
        if (kDebugMode) {
          print('cotizacion creada!');
        }
        if (kDebugMode) {
          print('Folio: ${data['folio']}');
        }
        return nuevo;
      } else {
        /*debugPrint(
          'Error al crear cotizacion: ${resp.statusCode} ${resp.body}',
        );
        final body = jsonDecode(resp.body);
        final detail = body['detail'];
        if (detail is List) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        return detail?.toString() ?? 'Error desconocido';*/
        throw Exception(resp.body);
      }
    } catch (e) {
      debugPrint('Exception en createCotizacion: $e');
      //return 'Hubo un problema al crear la cotizacion.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> deleteCotizacion(String id) async {
    final connectionId = WebSocketService.connectionId;
    final headers = {...AuthService.getAuthHeaders()};
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }

    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(url, headers: headers);

      if (resp.statusCode == 204 || resp.statusCode == 200) {
        deleteACotizacion(id);
        return true;
      } else {
        debugPrint(
          'Error al eliminar cotizacion: ${resp.statusCode} ${resp.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Exception en deleteCotizacion: $e');
      return false;
    }
  }

  Future<bool> renovarCotizacion(String id) async {
    final connectionId = WebSocketService.connectionId;
    final headers = {...AuthService.getAuthHeaders()};
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }

    try {
      final url = Uri.parse('$_baseUrl$id/renovar');
      final resp = await http.patch(url, headers: headers);

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final cot = Cotizaciones.fromMap(body as Map<String, dynamic>);
        cot.id = (body as Map)['id']?.toString();

        // Mover de vencidas a vigentes
        vencidas.removeWhere((c) => c.id == cot.id);
        cotizaciones.removeWhere((c) => c.id == cot.id);
        cotizaciones.add(cot);
        filteredCotizaciones = obtenerFilter(false);
        filteredVencidas = obtenerFilter(true);
        notifyListeners();
        return true;
      } else {
        debugPrint(
          'Error al renovar cotizacion: ${resp.statusCode} ${resp.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Exception en renovarCotizacion: $e');
      return false;
    }
  }
}
