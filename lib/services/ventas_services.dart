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
  List<Ventas> ventasConDeuda = [];
  bool isLoading = false;
  bool adeudoLoading = false;
  bool loaded = false;
  bool ventasCorteActualLoaded = false;
  bool ventasDeCorteLoading = false;

  Future<void> loadVentasDeCaja() async {
    if (CajasServices.cajaActualId==null) return;
    
    if (loaded) return;
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}caja/${CajasServices.cajaActualId}');
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
    
    loaded = true;
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadVentasDeCorteActual() async {
    if (CajasServices.corteActualId==null) return;

    if (ventasCorteActualLoaded) return;
    ventasDeCorteLoading = true;
    isLoading = true;
    
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
    
    ventasCorteActualLoaded = true;
    isLoading = false;
    ventasDeCorteLoading = false;
    notifyListeners();
  }

  Future<List<Ventas>> loadVentasDeCortes(List<String> ventasIds) async {
    final ventasMap = {
      for (var venta in ventasDeCaja) venta.id: venta,
    };
    return ventasIds.map((id) => ventasMap[id]).whereType<Ventas>().toList();
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
    final ventasPorProducto = acumulador.values.toList();
    ventasDeCorteLoading = false;
    return ventasPorProducto;
  }

  Future<Ventas?> createVenta(Ventas venta) async {
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

        isLoading = false;
        notifyListeners();
        return nuevo;
      } else {
        debugPrint('Error al crear venta: ${resp.statusCode} ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Exception en createVenta: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Ventas?> pagarDeuda(Ventas venta, String id) async {
    isLoading = true;
    venta.id = id;

    try {
      final url = Uri.parse('${_baseUrl}deuda');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: venta.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updatedVenta = Ventas.fromMap(data);
        updatedVenta.id = data['id']?.toString();

        // Actualizar en ventasDeCaja y ventasDeCorteActual
        final listasToUpdate = [ventasDeCaja, ventasDeCorteActual];
        for (final lista in listasToUpdate) {
          final index = lista.indexWhere((venta) => venta.id == updatedVenta.id);
          if (index != -1) {
            lista[index] = updatedVenta;
          }
        }

        // Remover de ventasConDeuda si existe
        ventasConDeuda.removeWhere((venta) => venta.id == updatedVenta.id);

        notifyListeners();
        return updatedVenta;
      }else {
        debugPrint('Error al actualizar venta: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateVenta: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void removeAVentaDeuda(String id)async{
    ventasConDeuda.removeWhere((venta) => venta.id==id);
    notifyListeners();
  }

  Future<void> loadAdeudos(List<Clientes> adeudados, String? sucursalId) async{
    adeudoLoading = true;
    ventasConDeuda.clear();
    List<String> ventasIds = [];
    for (var adeudado in adeudados) {
      for (var adeudo in adeudado.adeudos) {
        ventasIds.add(adeudo.ventaId);
      }
    }
     try {
      late final Uri url;
      if (sucursalId==null){
        url = Uri.parse('${_baseUrl}por-id');
      } else {
        url = Uri.parse('${_baseUrl}por-id?sucursal_id=$sucursalId');
      }
       
      final resp = await http.post(
        url, 
        headers: {
          "tkn": Env.tkn, 
          "Content-Type": "application/json",
        }, 
        body: json.encode(ventasIds)
      );
      final List<dynamic> listaJson = json.decode(resp.body);
      ventasConDeuda = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)["id"]?.toString();
        return x;
      }).toList();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }

    adeudoLoading = false;
    notifyListeners();
  }
}