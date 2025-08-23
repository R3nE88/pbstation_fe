import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class ProductosServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}productos/';
  List<Productos> productos = [];
  List<Productos> filteredProductos = [];
  late Map<String, Productos> _productosPorId;

  bool isLoading = false;


  void cargarProductos(List<Productos> nuevosProductos) {
    productos = nuevosProductos;
    _productosPorId = {
      for (var p in productos) p.id!: p
    };
    notifyListeners();
  }
  Productos? obtenerProductoPorId(String id) {
    return _productosPorId[id];
  }
  String descripcionConCantidad(DetallesVenta detalles) {
    final producto = _productosPorId[detalles.productoId];
    final descripcion = producto?.descripcion ?? 'Desconocido';
    if (producto!.requiereMedida){
      return '${detalles.cantidad} $descripcion(${detalles.ancho}x${detalles.alto})';
    }
    return '${detalles.cantidad} $descripcion';
  }
  String obtenerDetallesComoTexto(List<DetallesVenta> detalles) {
    return detalles.map((detalle) {
      return descripcionConCantidad(detalle);
    }).join(' - ');
  }

  void filtrarProductos(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      filteredProductos = productos;
    } else {
      filteredProductos = productos.where((producto) {
        return producto.descripcion.toLowerCase().contains(query) ||
              producto.codigo.toString().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<List<Productos>> loadProductos() async {   
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      productos = listaJson.map<Productos>((jsonElem) {
        final prod = Productos.fromMap(jsonElem as Map<String, dynamic>);
        prod.id = (jsonElem as Map)["id"]?.toString();
        return prod;
      }).toList();
      filteredProductos = productos;

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    isLoading = false;
    cargarProductos(productos);
    return productos;
  }

  void loadAProducto(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final prod = Productos.fromMap(body as Map<String, dynamic>);
        prod.id = (body as Map)["id"]?.toString();
        
        productos.add(prod);
        filteredProductos = productos;
        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el producto!');
        }
      }
    }
  }

  Future<String> createProducto(Productos producto) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: producto.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Productos.fromMap(data);
        nuevo.id = data['id']?.toString();

        productos.add(nuevo);
        filteredProductos = productos;
        if (kDebugMode) {
          print('producto creado!');
        }
        return 'exito';
      } else {
        debugPrint('Error al crear producto: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en createProducto: $e');
      return 'Hubo un problema al crear el producto.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProducto(String id) async{
    bool exito = false;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.delete(
        url, headers: {"tkn": Env.tkn}
        );
      if (resp.statusCode == 204){
        productos.removeWhere((producto) => producto.id==id);
        filteredProductos = productos;
        exito = true;
      }
    } catch (e) {
      exito = false;
    } 
    notifyListeners();
    return exito;
  }

  void deleteAProducto(String id) {
    productos.removeWhere((producto) => producto.id==id);
    filteredProductos = productos;
    notifyListeners();
  }

  Future<String> updateProducto(Productos producto, String id) async {
    isLoading = true;

    producto.id = id;

    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: producto.toJson(),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updated = Productos.fromMap(data);
        updated.id = data['id']?.toString();

        productos = productos.map((prod) => prod.id == updated.id ? updated : prod).toList();
        filteredProductos = productos;
        notifyListeners();
        return 'exito';
      } else {
        debugPrint('Error al actualizar producto: ${resp.statusCode} ${resp.body}');
        final body = jsonDecode(resp.body);
        return body['detail'];
      }
    } catch (e) {
      debugPrint('Exception en updateProducto: $e');
      return 'Hubo un problema al crear el producto.\n$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateAProducto(String id)async{
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final prod = Productos.fromMap(body as Map<String, dynamic>);
        prod.id = (body as Map)["id"]?.toString();
        
        productos = productos.map((producto) {
          if (producto.id == prod.id) {
            return prod;
          }
          return producto;
        }).toList();
        filteredProductos = productos;
        notifyListeners();
        isLoading = false;
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el producto!');
        }
      }
    }
  }
}