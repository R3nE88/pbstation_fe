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
  final String _baseUrl = 'http:${Constantes.baseUrl}cotizaciones/';
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

  Future<List<Cotizaciones>> loadCotizaciones() async {
    if (loaded) return [];
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );

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
      isLoading = false;
      notifyListeners();
      return [];
    }
  }

  void loadACotizacion(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url,
          headers: {...AuthService.getAuthHeaders()},
        );

        final body = json.decode(resp.body);
        final prod = Cotizaciones.fromMap(body as Map<String, dynamic>);
        prod.id = (body as Map)['id']?.toString();

        if (prod.vigente == false) {
          vencidas.add(prod);
        } else {
          cotizaciones.add(prod);
        }
        filteredCotizaciones = obtenerFilter(false);
        filteredVencidas = obtenerFilter(true);

        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar a cotizacion!');
        }
      }
    }
  }

  Future<String> createCotizacion(Cotizaciones cotizacion) async {
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

        cotizaciones.add(nuevo);
        filteredCotizaciones = obtenerFilter(false);
        if (kDebugMode) {
          print('cotizacion creada!');
        }
        if (kDebugMode) {
          print('Folio: ${data['folio']}');
        }
        return data['folio'];
      } else {
        debugPrint(
          'Error al crear cotizacion: ${resp.statusCode} ${resp.body}',
        );
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createCotizacion: $e');
      return 'Hubo un problema al crear la cotizacion.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
