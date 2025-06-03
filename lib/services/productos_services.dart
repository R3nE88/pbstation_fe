import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/models/models.dart';

class ProductosServices extends ChangeNotifier{
  final String _baseUrl = 'http://127.0.0.1:8000/productos/';
  List<Producto> productos = [];
  List<Producto> filteredProductos = [];

  bool isLoading = false;

  Future<List<Producto>> loadProductos() async { 
    if (isLoading) {
      return productos;
    }
    
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(url);

      final List<dynamic> listaJson = json.decode(resp.body);

      productos = listaJson.map<Producto>((jsonElem) {
        final prod = Producto.fromMap(jsonElem as Map<String, dynamic>);
        prod.id = (jsonElem as Map)["id"]?.toString();
        return prod;
      }).toList();
      filteredProductos = productos;

    } catch (e) {
      // Manejo de error
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    isLoading = false;
    notifyListeners();
    return productos;
  }

  void loadAProducto(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(url);

        final body = json.decode(resp.body);
        final prod = Producto.fromMap(body as Map<String, dynamic>);
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

  Future<String> createProducto(Producto producto) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: producto.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        producto.id = data['id']?.toString();
        final nuevo = Producto.fromMap(data);
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
      final resp = await http.delete(url);
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

  Future<String> updateProducto(Producto producto, String id) async {
    isLoading = true;

    try {
      final url = Uri.parse(_baseUrl);

      final body = json.encode({
          "id": id,
          "codigo": producto.codigo,
          "descripcion": producto.descripcion,
          "tipo": producto.tipo,
          "categoria": producto.categoria,
          "precio": producto.precio,
          "inventariable": producto.inventariable,
          "imprimible": producto.imprimible,
          "valor_impresion": producto.valorImpresion,
        });

      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final updatedProducto = Producto.fromMap(data);
        updatedProducto.id = data['id']?.toString();

        productos = productos.map((prod) => prod.id == updatedProducto.id ? updatedProducto : prod).toList();
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
        final resp = await http.get(url);

        final body = json.decode(resp.body);
        final prod = Producto.fromMap(body as Map<String, dynamic>);
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