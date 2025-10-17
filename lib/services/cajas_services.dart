import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CajasServices extends ChangeNotifier{
  final String _baseUrl = 'http:${Constantes.baseUrl}cajas/';
  static Cajas? cajaActual;
  static String? cajaActualId;
  bool forLogininit = false;
  bool forLoginloaded = false;
  bool isLoading = false;

  //Cortes
  static Cortes? corteActual;
  static String? corteActualId;
  List<Cortes> cortesDeCaja = [];
  bool cortesDeCajaIsLoading = false;
  bool cortesDeCajaIsLoaded = false;
  //List<MovimientosCajas> movimientos = [];

  //Historial de caja y paginacion
  List<Cajas> historialCajas = [];
  PaginacionInfo? paginacionHistorial;
  bool historialIsLoading = false;
  String? historialError;
  String? sucursalFiltroHistorial;

  bool isLoadingHistorial = false;
  static Cajas? cajaHistorial;
  static List<Cortes>? cortesHistorial;

  Future<void> initCaja() async{
    forLogininit = true;
    //obtener Caja
    final prefs = await SharedPreferences.getInstance();
    cajaActualId = prefs.getString(Env.debug ? 'caja_id_debug' : 'caja_id');
    if (cajaActualId!=null && cajaActualId!='buscando'){
      loadCaja(cajaActualId!);
    }
    
    forLoginloaded = true;
    notifyListeners();
  }

  Future<Cajas?> loadCaja(String id) async {    
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$id');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );
      final body = json.decode(resp.body);
      cajaActual = Cajas.fromMap(body as Map<String, dynamic>);
      cajaActual!.id = (body as Map)['id']?.toString();
      await loadUltimoCorte();
      //await loadMovimientos();
    } catch (e) {
      cajaActualId = 'buscando';
      isLoading = false;
      return null;
    }
    isLoading = false;
    return cajaActual;
  }

  Future<void> loadUltimoCorte() async{
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes/ultimo');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );
      final body = json.decode(resp.body);
      //solo obtener corte que no se a finalizado
      if (Cortes.fromMap(body as Map<String, dynamic>).fechaCorte==null){
        corteActual = Cortes.fromMap(body);
        corteActual!.id = (body as Map)['id']?.toString();
        corteActualId = corteActual!.id;
      }
    } catch (e) {
      isLoading = false;
    }
    isLoading = false;
  }

  Future<void> loadCortesDeCaja() async{
    if (cajaActualId==null) return;

    if (cortesDeCajaIsLoaded) return;
    cortesDeCajaIsLoading = true;
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes/all');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );
      
      final List<dynamic> listaJson = json.decode(resp.body);
      cortesDeCaja = listaJson.map<Cortes>((jsonElem) {
        final cor = Cortes.fromMap(jsonElem as Map<String, dynamic>);
        cor.id = (jsonElem as Map)['id']?.toString();
        return cor;
      }).toList(); 

    } catch (e) {
      cortesDeCajaIsLoading = false;
    }
    cortesDeCajaIsLoaded = true;
    cortesDeCajaIsLoading = false;
    notifyListeners();
  }

  Future<void> createCaja(Cajas caja) async {
    isLoading = true;
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: caja.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cajas.fromMap(data);
        nuevo.id = data['id']?.toString();

        //Guardar como caja actual la recien creada.
        cajaActual = nuevo;
        cajaActualId = cajaActual!.id;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(Env.debug ? 'caja_id_debug' : 'caja_id', cajaActualId!);

        if (kDebugMode) {
          print('caja creada!');
        }
      } else {
        debugPrint('Error al crear caja: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en createCaja: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCorte(Cortes corte) async {
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$cajaActualId/cortes');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: corte.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = Cortes.fromMap(data);
        nuevo.id = data['id']?.toString();

        //Guardar como corte actual la recien creada.
        corteActual = nuevo;
        corteActualId = corteActual!.id;
        cajaActual!.cortesIds.add(corteActualId!);
        cortesDeCaja.add(nuevo);

        if (kDebugMode) {
          print('corte creado!');
        }
      } else {
        debugPrint('Error al crear corte: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en createCorte: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> agregarMovimiento(MovimientosCajas movimiento) async {
    isLoading = true;
    try {
      final url = Uri.parse('$_baseUrl$corteActualId/movimientos');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: movimiento.toJson(),   
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final nuevo = MovimientosCajas.fromMap(data);
        nuevo.id = data['id']?.toString();

        //movimientos.add(nuevo);
        corteActual!.movimientosCaja.add(nuevo);
        cortesDeCaja.firstWhere((element) => element.id == corteActualId).movimientosCaja.add(nuevo);

        notifyListeners();

        if (kDebugMode) {
          print('movimiento creado y agregado a caja!');
        }
      } else {
        debugPrint('Error al crear movimiento: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en agregarMovimiento: $e');
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cerrarCaja(Cajas caja) async{
    isLoading = true;
    try {
      final url = Uri.parse(_baseUrl);
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: caja.toJson(),
      );

      if (resp.statusCode == 204) {
        cajaActual = null;
        cajaActualId = null;
        final prefs = await SharedPreferences.getInstance();
        prefs.remove(Env.debug ? 'caja_id_debug' : 'caja_id');
      } else {
        debugPrint('Error al actualizar caja: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en updateCaja: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarDatosCorte(Cortes corte, String id) async {
    isLoading = true;
    corte.id = id;
    
    try {
      final url = Uri.parse('${_baseUrl}cortes');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'tkn': Env.tkn},
        body: corte.toJson(),
      );

      if (resp.statusCode == 204) {
        cortesDeCaja = cortesDeCaja.map((c) => c.id == corte.id ? corte : c).toList();
        if (corteActualId == corte.id) {
          corteActual = corte;
        }
      } else {
        debugPrint('Error al actualizar corte: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exception en actualizarDatosCorte: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void eliminarCajaActualSoloDePrueba() async{
    cajaActual = null;
    cajaActualId = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(Env.debug ? 'caja_id_debug' : 'caja_id');
    notifyListeners();
  }

  Future<void> cargarHistorialCajas({
    int page = 1,
    int pageSize = 60,
    String? sucursalId,
    bool append = false,
  }) async {
    if (historialIsLoading) return;

    historialIsLoading = true;
    historialError = null;
    
    if (!append) {
      historialCajas = [];
    }
    
    notifyListeners();

    try {
      // Construir query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (sucursalId != null && sucursalId.isNotEmpty) 'sucursal_id': sucursalId,
      };

      final url = Uri.parse('${_baseUrl}all').replace(queryParameters: queryParams);
      
      final resp = await http.get(
        url,
        headers: {'tkn': Env.tkn}
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
             
        // Parsear las cajas
        final List<dynamic> cajasJson = data['data'];
        final List<Cajas> nuevasCajas = cajasJson.map((json) {
          final caja = Cajas.fromMap(json as Map<String, dynamic>);
          caja.id = (json as Map)['id']?.toString();
          return caja;
        }).toList();

        // Agregar o reemplazar
        if (append) {
          historialCajas.addAll(nuevasCajas);
        } else {
          historialCajas = nuevasCajas;
        }

        // Guardar info de paginación
        paginacionHistorial = PaginacionInfo.fromJson(data['pagination']);
        sucursalFiltroHistorial = sucursalId;
      } else {
        historialError = 'Error al cargar cajas: ${resp.statusCode}';
      }
    } catch (e) {
      historialError = 'Error: $e';
      if (kDebugMode) {
        print('Error en cargarHistorialCajas: $e');
      }
    } finally {
      historialIsLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasHistorialCajas() async {
    if (paginacionHistorial != null && paginacionHistorial!.hasNext) {
      await cargarHistorialCajas(
        page: paginacionHistorial!.page + 1,
        pageSize: paginacionHistorial!.pageSize,
        sucursalId: sucursalFiltroHistorial,
        append: true,
      );
    }
  }

  void cambiarFiltroSucursalHistorial(String? sucursalId) {
    sucursalFiltroHistorial = sucursalId;
    cargarHistorialCajas(sucursalId: sucursalId);
  }

  Future<void> loadDatosCompletosDeCaja(String cajaId) async{
    isLoadingHistorial = true;
    //TODO: cargar caja seleccionada y cortes
    //TODO: traer movimientos tambien (pero antes, cargar movimientos de otros cortes en misma caja)
    try {
      final url = Uri.parse('$_baseUrl$cajaId');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );
      final body = json.decode(resp.body);
      cajaHistorial = Cajas.fromMap(body as Map<String, dynamic>);
      cajaHistorial!.id = (body as Map)['id']?.toString();
    } catch (e) {
      debugPrint('$e');
      isLoadingHistorial = false;
      notifyListeners();
    }
    try {
      final url = Uri.parse('$_baseUrl$cajaId/cortes/all');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );
      final List<dynamic> listaJson = json.decode(resp.body);
      cortesHistorial = listaJson.map<Cortes>((jsonElem) {
        final cor = Cortes.fromMap(jsonElem as Map<String, dynamic>);
        cor.id = (jsonElem as Map)['id']?.toString();
        return cor;
      }).toList(); 
    } catch (e) {
      debugPrint('$e');
      isLoadingHistorial = false;
      notifyListeners();
    }
    isLoadingHistorial = false;
    notifyListeners();
  }

  Future<double> obtenerTCDeVenta(String ventaId) async {
    try {
      final url = Uri.parse('${_baseUrl}ventas/$ventaId/tipo-cambio');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return data['tipo_cambio'] as double;
      } else if (resp.statusCode == 404) {
        throw Exception('No se encontró el tipo de cambio para esta venta');
      } else {
        throw Exception('Error al obtener tipo de cambio: ${resp.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}