import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';

class CotizacionesServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}cotizaciones/';
  List<Cotizaciones> cotizaciones = [];
  List<Cotizaciones> vencidas = [];
  

  bool isLoading = false;

  Future<List<Cotizaciones>> loadCotizaciones() async {    
    isLoading = true;

    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {"tkn": Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      // Reiniciar listas antes de agregar nuevas
      cotizaciones = [];
      vencidas = [];

      for (var jsonElem in listaJson) {
        final data = jsonElem as Map<String, dynamic>;
        final cotizacion = Cotizaciones.fromMap(data);
        cotizacion.id = data["id"]?.toString();

        if (cotizacion.vigente == false) {
          vencidas.add(cotizacion);
        } else {
          cotizaciones.add(cotizacion);
        }
      }

      isLoading = false;
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
          url, headers: {"tkn": Env.tkn}
        );

        final body = json.decode(resp.body);
        final prod = Cotizaciones.fromMap(body as Map<String, dynamic>);
        prod.id = (body as Map)["id"]?.toString();
        
        if (prod.vigente==false){
          vencidas.add(prod);
        } else {
          cotizaciones.add(prod);
        }
        
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

    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', "tkn": Env.tkn},
        body: cotizacion.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cotizaciones.fromMap(data);
        nuevo.id = data['id']?.toString();

        cotizaciones.add(nuevo);
        if (kDebugMode) {
          print('cotizacion creada!');
        }
        if (kDebugMode) {
          print('Folio: ${data['folio']}');
        }
        return data['folio'];
      } else {
        debugPrint('Error al crear cotizacion: ${resp.statusCode} ${resp.body}');
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