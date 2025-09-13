import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';

class VentasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}ventas/';
  List<Ventas> ventasDeCaja = [];
  List<Ventas> ventasDeCorteActual = [];
  List<VentasPorProducto> ventasPorProducto = [];
  bool isLoading = false;
  bool ventasDeCorteLoading = false;

  Future<void> loadVentasDeCaja(String cajaId) async {
    isLoading = true;

    await Future.delayed(Duration(milliseconds: 500));

    try {
      final url = Uri.parse('${_baseUrl}caja/$cajaId');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasDeCaja.clear();
      ventasDeCaja = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadVentasDeCorteActual(bool loadPorProducto) async {
    isLoading = true;
    if (loadPorProducto) ventasDeCorteLoading = true;
    
    try {
      final url = Uri.parse('${_baseUrl}corte/${CajasServices.corteActualId}');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);
      
      ventasDeCorteActual.clear();
      ventasDeCorteActual = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }

    if (loadPorProducto) consolidarVentasPorProducto(ventasDeCorteActual);
    
    isLoading = false;
    notifyListeners();
  }

  Future<List<Ventas>?> loadVentasDeCorte(String corteId) async {
    isLoading = true;
    //await Future.delayed(const Duration(seconds: 2));
    late final List<Ventas> vts;
    try {
      final url = Uri.parse('${_baseUrl}corte/$corteId');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );
      final List<dynamic> listaJson = json.decode(resp.body);
      vts = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }    
    isLoading = false;
    notifyListeners();
    return vts;
  }

  List<VentasPorProducto> consolidarVentasPorProducto(List<Ventas> ventas) {
    // Mapa de acumulación: clave es productoId, valor es el objeto VentasPorProducto consolidado
    final Map<String, VentasPorProducto> acumulador = {};

    // Iteramos sobre cada objeto de venta en la lista
    for (final venta in ventas) {
      // Iteramos sobre cada detalle de venta dentro de la venta actual
      for (final detalle in venta.detalles) {
        final productoId = detalle.productoId;

        // Verificamos si ya existe una entrada para este producto
        if (acumulador.containsKey(productoId)) {
          // Si existe, actualizamos los valores sumándolos
          final productoExistente = acumulador[productoId]!;
          productoExistente.cantidad += detalle.cantidad;
          productoExistente.subTotal += detalle.subtotal - detalle.iva;
          productoExistente.iva += detalle.iva;
          productoExistente.total += detalle.subtotal;
        } else {
          // Si no existe, creamos una nueva entrada
          final nuevaVentaPorProducto = VentasPorProducto(
            productoId: productoId,
            cantidad: detalle.cantidad,
            subTotal: detalle.subtotal - detalle.iva,
            iva: detalle.iva,
            total: detalle.subtotal // El total inicial
          );
          acumulador[productoId] = nuevaVentaPorProducto;
        }
      }
    }

    // Convertimos los valores del mapa a una lista y la devolvemos
    ventasPorProducto = acumulador.values.toList();
    ventasDeCorteLoading = false;
    return ventasPorProducto;
  }

  /*void loadVentasDeCortePorProducto() {
    /*isLoading = true;

    await Future.delayed(Duration(seconds: 1));

    try {
      final url = Uri.parse('${_baseUrl}corte/$corteId/por-producto');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasPorProducto = listaJson.map<VentasPorProducto>((jsonElem) {
        final x = VentasPorProducto.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
    
    isLoading = false;
    notifyListeners();*/
  }*/

  Future<String> createVenta(Ventas venta) async {
    isLoading = true;

    try {
      final url = Uri.parse('$_baseUrl${CajasServices.corteActualId}');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: venta.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Ventas.fromMap(data);
        nuevo.id = data['id']?.toString();

        ventasDeCaja.add(nuevo);
        ventasDeCorteActual.add(nuevo);

        //Añadir venta a corte actual
        CajasServices.corteActual!.ventasIds.add(nuevo.id!);

        if (kDebugMode) {
          print('venta creada!');
        }
        return data['folio'];
      } else {
        debugPrint('Error al crear venta: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createVenta: $e');
      return 'Hubo un problema al crear la venta.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}