import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class VentasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}ventas/';
  List<Ventas> ventasDeCaja = [];
  List<Ventas> ventasDeCorteActual = [];
  List<Ventas> ventasConDeuda = [];
  List<Ventas> ventasDePedidos = [];
  List<Ventas> ventasConDeudaFiltered = [];
  bool isLoading = false;
  bool adeudoLoading = false;
  bool loaded = false;
  bool ventasCorteActualLoaded = false;
  bool ventasDeCorteLoading = false;

  //VentasDeCajaHistorial
  bool isLoadingHistorial = false;
  List<Ventas> ventasDeCajaHistorial = [];

  void filtrarDeudas(String query){
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      ventasConDeudaFiltered = ventasConDeuda;
    } else {
      ventasConDeudaFiltered = ventasConDeuda.where((pedido) {
        return pedido.folio?.toLowerCase().contains(query)??false;
      }).toList();
    }
    notifyListeners();
  }

  Future<Ventas?> searchVenta(String ventaId) async {
    if (ventasDePedidos.any((element) => element.id == ventaId)){
      return ventasDePedidos.firstWhere((element) => element.id == ventaId);
    }

    isLoading = true;
    notifyListeners();
    
    try {
      final url = Uri.parse('$_baseUrl$ventaId');
      final resp = await http.get(
        url,
        headers: {'tkn': Env.tkn},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final venta = Ventas.fromMap(data);
        venta.id = data['id']?.toString();
        
        isLoading = false;
        ventasDePedidos.add(venta);
        notifyListeners();
        return venta;
      } else if (resp.statusCode == 404) {
        debugPrint('Venta no encontrada: $ventaId');
        isLoading = false;
        notifyListeners();
        return null;
      } else if (resp.statusCode == 400) {
        debugPrint('Formato de ID inválido: $ventaId');
        isLoading = false;
        notifyListeners();
        return null;
      } else {
        debugPrint('Error al buscar venta: ${resp.statusCode} ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Exception en searchVenta: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadVentasDeCaja() async {
    if (CajasServices.cajaActualId==null) return;
    
    if (loaded) return;
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}caja/${CajasServices.cajaActualId}');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasDeCaja.clear();
      ventasDeCaja = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)['id']?.toString();
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

  Future<void> loadVentasDeCajaHistorial(String cajaId) async {
    isLoadingHistorial = true;

    try {
      final url = Uri.parse('${_baseUrl}caja/$cajaId');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      ventasDeCajaHistorial.clear();
      ventasDeCajaHistorial = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)['id']?.toString();
        return x;
      }).toList();

    } catch (e) {
      isLoadingHistorial = false;
      notifyListeners();
    }
    
    isLoadingHistorial = false;
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
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);
      
      ventasDeCorteActual.clear();
      ventasDeCorteActual = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)['id']?.toString();
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
    final Map<String, VentasPorProducto> acumulador = {};

    for (final venta in ventas) {
      if (venta.cancelado){ continue; }
      if (venta.liquidado && venta.wasDeuda){ continue; }
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
      final url = Uri.parse('$_baseUrl${CajasServices.corteActualId}?is_deuda=false');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: venta.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final venta = Ventas.fromMap(data);
        venta.id = data['id']?.toString();

        ventasDeCaja.add(venta);
        ventasDeCorteActual.add(venta);
        CajasServices.corteActual!.ventasIds.add(venta.id!);

        isLoading = false;
        notifyListeners();
        return venta;
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

  Future<Ventas?> pagarDeuda(Ventas venta, String ventaOriginalID) async {
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
      final url = Uri.parse('$_baseUrl${CajasServices.corteActualId}?is_deuda=true');
      final resp = await http.post(
        url,
        headers: headers,
        body: venta.toJson(),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final ventaPagada = Ventas.fromMap(data);
        ventaPagada.id = data['id']?.toString();

        ventasDeCaja.add(ventaPagada);
        ventasDeCorteActual.add(ventaPagada);
        CajasServices.corteActual!.ventasIds.add(ventaPagada.id!);
        ventasConDeuda.removeWhere((ventaDeuda) => ventaDeuda.id == ventaOriginalID);
        ventasConDeudaFiltered.removeWhere((ventaDeuda) => ventaDeuda.id == ventaOriginalID);

        marcarDeudaComoPagada(ventaOriginalID);
        notifyListeners();
        return ventaPagada;
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
    ventasConDeudaFiltered.removeWhere((venta) => venta.id==id);
    notifyListeners();
  }

  Future<void> loadAdeudos(List<Clientes> adeudados, String? sucursalId) async{
    adeudoLoading = true;
    ventasConDeuda.clear();
    ventasConDeudaFiltered.clear();
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
          'tkn': Env.tkn, 
          'Content-Type': 'application/json',
        }, 
        body: json.encode(ventasIds)
      );
      final List<dynamic> listaJson = json.decode(resp.body);
      ventasConDeuda = listaJson.map<Ventas>((jsonElem) {
        final x = Ventas.fromMap(jsonElem as Map<String, dynamic>);
        x.id = (jsonElem as Map)['id']?.toString();
        return x;
      }).toList();
      ventasConDeudaFiltered = ventasConDeuda;
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }

    adeudoLoading = false;
    notifyListeners();
  }

  Future<Ventas?> marcarDeudaComoPagada(String ventaId) async {
    isLoading = true;
    
    try {
      final url = Uri.parse('$_baseUrl$ventaId/marcar-deuda');
      final resp = await http.patch(
        url,
        headers: {'tkn': Env.tkn},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final ventaActualizada = Ventas.fromMap(data);
        ventaActualizada.id = data['id']?.toString();

        // Actualizar la venta en las listas locales si existe
        _actualizarVentaEnListas(ventaActualizada);

        isLoading = false;
        notifyListeners();
        return ventaActualizada;
      } else {
        debugPrint('Error al marcar venta como deuda: ${resp.statusCode} ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Exception en marcarVentaComoDeuda: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Ventas?> cancelarVenta(String ventaId, String motivo) async {
    isLoading = true;
    
    try {
      final url = Uri.parse('$_baseUrl$ventaId/cancelar?motivo_cancelacion=$motivo');
      final resp = await http.patch(
        url,
        headers: {'tkn': Env.tkn},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final ventaActualizada = Ventas.fromMap(data);
        ventaActualizada.id = data['id']?.toString();

        // Actualizar la venta en las listas locales si existe
        _actualizarVentaEnListas(ventaActualizada);

        isLoading = false;
        notifyListeners();
        return ventaActualizada;
      } else {
        debugPrint('Error al cancelar venta: ${resp.statusCode} ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Exception en cancelarVenta: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<Ventas>?> marcarVentasEntregadasPorFolio(String folio) async {
    isLoading = true;
    
    final connectionId = WebSocketService.connectionId;
    final headers = {'tkn': Env.tkn};
    
    // Para notificar a los demás, menos a mi mismo (websocket)
    if (connectionId != null) {
      headers['X-Connection-Id'] = connectionId;
    }
    
    try {
      final url = Uri.parse('${_baseUrl}marcar-entregada/$folio');
      final resp = await http.patch(
        url,
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final List<dynamic> listaJson = json.decode(resp.body);
        
        // Convertir la lista a objetos Ventas
        final ventasActualizadas = listaJson.map<Ventas>((jsonElem) {
          final venta = Ventas.fromMap(jsonElem as Map<String, dynamic>);
          venta.id = (jsonElem as Map)['id']?.toString();
          return venta;
        }).toList();

        // Actualizar cada venta en las listas locales
        for (var ventaActualizada in ventasActualizadas) {
          _actualizarVentaEnListas(ventaActualizada);
        }

        isLoading = false;
        notifyListeners();
        return ventasActualizadas;
      } else if (resp.statusCode == 400) {
        debugPrint('Ventas ya entregadas o error: ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      } else if (resp.statusCode == 404) {
        debugPrint('No se encontraron ventas con el folio: $folio');
        isLoading = false;
        notifyListeners();
        return null;
      } else {
        debugPrint('Error al marcar ventas como entregadas: ${resp.statusCode} ${resp.body}');
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Exception en marcarVentasEntregadasPorFolio: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void updateAVenta(String id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {'tkn': Env.tkn}
        );

        if (resp.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(resp.body);
          final ventaActualizada = Ventas.fromMap(data);
          ventaActualizada.id = data['id']?.toString();

          // Buscar y actualizar en todas las listas
          _actualizarVentaEnListas(ventaActualizada);
        } else {
          debugPrint('Error al actualizar venta: ${resp.statusCode} ${resp.body}');
        }

        isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Exception en updateAVenta: $e');
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Método helper para actualizar la venta en todas las listas
  void _actualizarVentaEnListas(Ventas ventaActualizada) {
    // Actualizar en ventasDeCaja
    final indexCaja = ventasDeCaja.indexWhere((v) => v.id == ventaActualizada.id);
    if (indexCaja != -1) {
      ventasDeCaja[indexCaja] = ventaActualizada;
    }

    // Actualizar en ventasDeCorteActual
    final indexCorte = ventasDeCorteActual.indexWhere((v) => v.id == ventaActualizada.id);
    if (indexCorte != -1) {
      ventasDeCorteActual[indexCorte] = ventaActualizada;
    }

    // Actualizar en ventasConDeuda
    final indexDeuda = ventasConDeuda.indexWhere((v) => v.id == ventaActualizada.id);
    if (indexDeuda != -1) {
      ventasConDeuda[indexDeuda] = ventaActualizada;
      ventasConDeudaFiltered[indexDeuda] = ventaActualizada;
    }

    // Actualizar en ventasDeCajaHistorial
    final indexHistorial = ventasDeCajaHistorial.indexWhere((v) => v.id == ventaActualizada.id);
    if (indexHistorial != -1) {
      ventasDeCajaHistorial[indexHistorial] = ventaActualizada;
    }

    // Actualizar en ventasDePedidos
    final indexPedidos = ventasDePedidos.indexWhere((v) => v.id == ventaActualizada.id);
    if (indexPedidos != -1) {
      ventasDePedidos[indexPedidos] = ventaActualizada;
    }
  }
}