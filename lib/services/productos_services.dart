import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/models/models.dart';

class ProductosServices extends ChangeNotifier{
  final String _baseUrl = 'http://127.0.0.1:8000/productos/';
  List<Producto> productos = [];

  bool isLoading = false;

  Future<List<Producto>> loadProductos() async {
    // 🔒 Si ya se está cargando, no hacemos nada:
    if (isLoading) {
      print('loadProductos: ya se está ejecutando, ignorando llamada duplicada.');
      return productos;
    }
    
    print('ejecutando loadProductos!');
    isLoading = true;
    //notifyListeners();

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(url);

      // 1) Decodifica como lista
      final List<dynamic> listaJson = json.decode(resp.body);

      // 2) Transforma cada elemento en Producto
      productos = listaJson.map<Producto>((jsonElem) {
        final prod = Producto.fromMap(jsonElem as Map<String, dynamic>);
        // Si quieres asignar el id (viene dentro del JSON):
        prod.id = (jsonElem as Map)["id"]?.toString();
        return prod;
      }).toList();
    } catch (e) {
      // Manejo de error
      isLoading = false;
      notifyListeners();
      return [];
    }

    print('finalizando loadProductos!');

    isLoading = false;
    notifyListeners();
    return productos;
  }

  Future<String> createProducto(Producto producto) async {
    isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(_baseUrl); // o el endpoint donde aceptes POST
      // 1) Serializa con json.encode y pon la cabecera adecuada
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: producto.toJson(),      // toJson() usa json.encode(toMap())
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // 2) Lee la respuesta: suponiendo que tu servidor devuelve el objeto creado
        final Map<String, dynamic> data = json.decode(resp.body);
        // 3) Asigna el id que venga del servidor
        producto.id = data['id']?.toString();
        // 4) Opcional: reconstruir desde Map para asegurar consistencia
        final nuevo = Producto.fromMap(data);
        productos.add(nuevo);
        if (kDebugMode) {
          print('producto creado!');
        }
        return 'exito';
      } else {
        // Maneja errores del servidor
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
}