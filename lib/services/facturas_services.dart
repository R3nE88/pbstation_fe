import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/auth_service.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class FacturasServices extends ChangeNotifier {
  final String _baseUrl = 'http:${Constantes.baseUrl}facturacion/';
  //List<Facturas> facturas = [];
  bool isLoading = false;

  //Historial de facturas con paginación
  List<Facturas> historialFacturas = [];
  PaginacionInfo? paginacionHistorial;
  bool historialIsLoading = false;
  String? historialError;
  String? sucursalFiltroHistorial;
  String? rfcFiltroHistorial;

  Future<String> facturarVenta(Cfdi cfdi) async {
    try {
      final url = Uri.parse('${_baseUrl}crear');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cfdi.toJson()),
      );

      final Map<String, dynamic> body = jsonDecode(resp.body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Si trae mensaje de error aunque sea 200
        if (body.containsKey('Message')) {
        } else {
          body.addEntries({'exito': 'true'}.entries);
        }
      }

      return jsonEncode(body);
    } catch (e) {
      return jsonEncode({
        'Message': 'Hubo un problema al crear la factura.\n$e',
      });
    }
  }

  List<String> extraerErrores(dynamic errorJson) {
    final List<String> mensajes = [];

    // Caso A: trae ModelState
    if (errorJson is Map && errorJson.containsKey('ModelState')) {
      final modelState = errorJson['ModelState'];

      if (modelState is Map) {
        modelState.forEach((key, value) {
          if (value is List) {
            for (var msg in value) {
              mensajes.add(msg.toString());
            }
          } else {
            mensajes.add(value.toString());
          }
        });
      }
    }

    // Caso B: trae Message directo
    if (errorJson is Map &&
        errorJson.containsKey('Message') &&
        (errorJson['Message'] as String).isNotEmpty) {
      mensajes.add(errorJson['Message']);
    }

    return mensajes;
  }

  Future<String?> createFactura(Facturas factura) async {
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
        body: factura.toJson(),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Facturas.fromMap(data);
        nuevo.id = data['id']?.toString();

        historialFacturas.insert(0, nuevo);

        if (kDebugMode) {
          print('factura creada en be!');
        }
        return nuevo.id!;
      } else {
        debugPrint('Error al crear factura: ${resp.statusCode} ${resp.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception en createFactura: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarHistorialFacturas({
    int page = 1,
    int pageSize = 60,
    String? sucursalId,
    String? rfc,
    bool append = false,
  }) async {
    if (historialIsLoading) return;

    historialIsLoading = true;
    historialError = null;
    rfcFiltroHistorial = rfc;

    if (!append) {
      historialFacturas = [];
    }

    notifyListeners();

    try {
      // Construir query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (sucursalId != null && sucursalId.isNotEmpty)
          'sucursal_id': sucursalId,
        if (rfc != null && rfc.isNotEmpty) 'rfc': rfc,
      };

      final url = Uri.parse(
        '${_baseUrl}all',
      ).replace(queryParameters: queryParams);

      final resp = await http.get(
        url,
        headers: {...AuthService.getAuthHeaders()},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        // Parsear las facturas
        final List<dynamic> facturasJson = data['data'];
        final List<Facturas> nuevasFacturas =
            facturasJson.map((json) {
              final factura = Facturas.fromMap(json as Map<String, dynamic>);
              factura.id = (json as Map)['id']?.toString();
              return factura;
            }).toList();

        // Agregar o reemplazar
        if (append) {
          historialFacturas.addAll(nuevasFacturas);
        } else {
          historialFacturas = nuevasFacturas;
        }

        // Guardar info de paginación
        paginacionHistorial = PaginacionInfo.fromJson(data['pagination']);
        sucursalFiltroHistorial = sucursalId;
      } else {
        historialError = 'Error al cargar facturas: ${resp.statusCode}';
      }
    } catch (e) {
      historialError = 'Error: $e';
      if (kDebugMode) {
        print('Error en cargarHistorialFacturas: $e');
      }
    } finally {
      historialIsLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasHistorialFacturas() async {
    if (paginacionHistorial != null && paginacionHistorial!.hasNext) {
      await cargarHistorialFacturas(
        page: paginacionHistorial!.page + 1,
        pageSize: paginacionHistorial!.pageSize,
        sucursalId: sucursalFiltroHistorial,
        rfc: rfcFiltroHistorial,
        append: true,
      );
    }
  }

  void cambiarFiltroSucursalHistorial(String? sucursalId) {
    sucursalFiltroHistorial = sucursalId;
    cargarHistorialFacturas(sucursalId: sucursalId);
  }
}
