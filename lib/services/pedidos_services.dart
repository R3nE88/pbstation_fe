import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbstation_frontend/env.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/sucursales_services.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/widgets/loading.dart';

class PedidosService extends ChangeNotifier {
  final String _baseUrl = 'http:${Constantes.baseUrl}pedidos/';
  bool isLoading = false;
  bool loaded = false;
  double uploadProgress = 0.0;
  List<Pedidos> pedidosNotReady = [];
  List<Pedidos> pedidosReady = [];
  List<Pedidos> filteredPedidosReady = [];
  bool isDownloading = false;
  double downloadProgress = 0.0;

  void organizar() {
    // Combinar ambas listas antes de reorganizar
    final todosPedidos = [...pedidosReady, ...pedidosNotReady];
    
    if (Login.usuarioLogeado.rol == TipoUsuario.vendedor && 
        (Login.usuarioLogeado.permisos.nivel == 1 || Login.usuarioLogeado.permisos.nivel == 2)) {
      // Filtrar pedidos por sucursal del vendedor
      final sucursalId = SucursalesServices.sucursalActualID;
      
      // Filtrar pedidos "en espera" que pertenecen a la sucursal del vendedor
      pedidosNotReady = todosPedidos
          .where((pedido) => 
              pedido.estado.name == 'enEspera' && 
              pedido.ventaId != 'esperando' &&
              pedido.sucursalId == sucursalId)
          .toList();
      
      // Mantener solo los pedidos que NO están "en espera" y pertenecen a la sucursal del vendedor
      pedidosReady = todosPedidos
          .where((pedido) => 
              pedido.estado.name != 'enEspera' && 
              pedido.ventaId != 'esperando' &&
              pedido.sucursalId == sucursalId)
          .toList();
    } else {
      // Filtrar pedidos "en espera" y moverlos a pedidosNotReady
      pedidosNotReady = todosPedidos
          .where((pedido) => 
              pedido.estado.name == 'enEspera' && 
              pedido.ventaId != 'esperando')
          .toList();
      
      // Mantener solo los pedidos que NO están "en espera" en pedidosReady
      pedidosReady = todosPedidos
          .where((pedido) => 
              pedido.estado.name != 'enEspera' && 
              pedido.ventaId != 'esperando')
          .toList();
    }

    filteredPedidosReady = pedidosReady;
  }

  void filtrarPedidos(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      filteredPedidosReady = pedidosReady;
    } else {
      filteredPedidosReady = pedidosReady.where((pedido) {
        return pedido.folio?.toLowerCase().contains(query)??false;
      }).toList();
    }
    notifyListeners();
  }

  Future<List<Pedidos>> loadPedidos({bool force = false}) async { 
    if (loaded && !force) return pedidosReady;

    pedidosNotReady.clear();
    pedidosReady.clear();

    isLoading = true;
    try {
      final url = Uri.parse('${_baseUrl}all');
      final resp = await http.get(
        url, headers: {'tkn': Env.tkn}
      );

      final List<dynamic> listaJson = json.decode(resp.body);

      pedidosReady = listaJson.map<Pedidos>((jsonElem) {
        final cli = Pedidos.fromMap(jsonElem as Map<String, dynamic>);
        cli.id = (jsonElem as Map)['id']?.toString();
        return cli;
      }).toList();

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return [];
    }
    
    organizar();
    loaded = true;
    isLoading = false;
    notifyListeners();
    return pedidosReady;
  }

  void loadAPedido(id) async {
    if (!isLoading) {
      isLoading = true;
      try {
        final url = Uri.parse('$_baseUrl$id');
        final resp = await http.get(
          url, headers: {'tkn': Env.tkn}
        );
        if (resp.statusCode == 200){
          final body = json.decode(resp.body);
          final cli = Pedidos.fromMap(body as Map<String, dynamic>);
          cli.id = (body as Map)['id']?.toString();
          pedidosReady.add(cli);
          organizar();
          isLoading = false;
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('hubo un problema al cargar el pedido!');
        }
      }
    }
  }

  /// Crear pedido (con o sin archivos según el estado)
  Future<String> createPedido({
    required Pedidos pedido,
    List<File>? archivos,
  }) async {
    isLoading = true;
    uploadProgress = 0;
    notifyListeners();

    if ((archivos == null || archivos.isEmpty) && pedido.estado != Estado.enEspera) {
      isLoading = false;
      notifyListeners();
      return 'Error: Los pedidos deben tener archivos o estar en estado "en espera"';
    }

    final formDataMap = <String, dynamic>{
      'pedido': pedido.toJson(),
    };

    if (archivos != null && archivos.isNotEmpty) {
      formDataMap['archivos'] = [
        for (var f in archivos)
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.isWindows ? '\\' : '/').last,
          )
      ];
    }

    final headers = {
      'tkn': Env.tkn,
      if (WebSocketService.connectionId != null) 
        'X-Connection-Id': WebSocketService.connectionId!,
    };

    try {
      final dio = Dio(BaseOptions(
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        _baseUrl,
        data: FormData.fromMap(formDataMap),
        onSendProgress: (count, total) {
          uploadProgress = total != 0 ? count / total : 0;
          notifyListeners();
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadProgress = 1;
        final nuevoPedido = Pedidos.fromMap(response.data as Map<String, dynamic>);
        if (nuevoPedido.ventaId!='esperando'){
          if (nuevoPedido.estado==Estado.enEspera){
            pedidosNotReady.add(nuevoPedido);
          } else {
            pedidosReady.add(nuevoPedido);
          }
          notifyListeners();
        }
        return nuevoPedido.id!;
      } else {
        debugPrint('Error: ${response.statusCode} ${response.data}');
        return 'Error: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Error: Tiempo de conexión agotado';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return 'Error: Tiempo de respuesta agotado';
      } else if (e.response?.statusCode == 413) {
        return 'Error: Archivo demasiado grande';
      }
      debugPrint('DioException: ${e.message}');
      return 'Error de conexión';
    } catch (e) {
      debugPrint('Error: $e');
      return 'Error desconocido';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> addArchivosToPedido({
    required String pedidoId,
    required List<File> archivos,
  }) async {
    if (archivos.isEmpty) {
      return 'Error: Debes seleccionar al menos un archivo';
    }

    isLoading = true;
    uploadProgress = 0;
    notifyListeners();

    final formDataMap = <String, dynamic>{
      'archivos': [
        for (var f in archivos)
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.isWindows ? '\\' : '/').last,
          )
      ],
    };

    final headers = {
      'tkn': Env.tkn,
      if (WebSocketService.connectionId != null)
        'X-Connection-Id': WebSocketService.connectionId!,
    };

    try {
      final dio = Dio(BaseOptions(
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.patch(
        '$_baseUrl$pedidoId/archivos',
        data: FormData.fromMap(formDataMap),
        onSendProgress: (count, total) {
          uploadProgress = total != 0 ? count / total : 0;
          notifyListeners();
        },
      );

      if (response.statusCode == 200) {
        uploadProgress = 1;
        final pedidoActualizado = Pedidos.fromMap(response.data as Map<String, dynamic>);
        final index = pedidosNotReady.indexWhere((p) => p.id == pedidoId);
        if (index != -1) {
          pedidosNotReady.removeAt(index);
          pedidosReady.add(pedidoActualizado);
        }
        return pedidoActualizado.id!;
      } else {
        debugPrint('Error: ${response.statusCode} ${response.data}');
        return 'Error: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Error: Tiempo de conexión agotado';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return 'Error: Tiempo de respuesta agotado';
      } else if (e.response?.statusCode == 413) {
        return 'Error: Archivo demasiado grande';
      }
      debugPrint('DioException: ${e.message}');
      return 'Error de conexión';
    } catch (e) {
      debugPrint('Error: $e');
      return 'Error desconocido';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmarPedido({
    required String pedidoId,
    required String ventaId,
    required String ventaFolio,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final connectionId = WebSocketService.connectionId;

      final headers = {
        'tkn': Env.tkn,
        if (connectionId != null) 'X-Connection-Id': connectionId,
      };

      final url = Uri.parse('$_baseUrl$pedidoId/venta');

      final response = await http.patch(
        url,
        headers: headers,
        body: {'venta_id': ventaId, 'venta_folio': ventaFolio},
      );

      if (response.statusCode == 200) {
        // Actualizar el pedido en la lista local
        final pedidoActualizado = Pedidos.fromJson(response.body);
        
        final index = pedidosNotReady.indexWhere((p) => p.id == pedidoId);
        if (index != -1) {
          pedidosNotReady[index] = pedidoActualizado;
          notifyListeners();
        }

        loaded = false;
        return true;
      } else {
        debugPrint('Error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error al actualizar venta_id: o venta_folio $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> descargarArchivoIndividual({
    required String pedidoId,
    required String nombreArchivo,
    required BuildContext context,
    bool elegirCarpeta = true,
  }) async {
    try {
      Directory dirDestino;
      Loading.displaySpinLoading(context);
      
      if (elegirCarpeta) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          lockParentWindow: true,
          dialogTitle: 'Selecciona dónde guardar el archivo',
        );
        
        if (selectedDirectory == null) {
          isDownloading = false;
          notifyListeners();
          if (!context.mounted) return null;
          Navigator.pop(context);
          return null;
        }
        
        dirDestino = Directory(selectedDirectory);
      } else {
        final userProfile = Platform.environment['USERPROFILE'];
        dirDestino = Directory('$userProfile\\Downloads');
      }
      
      if (!context.mounted) return null;
      Navigator.pop(context);

      isDownloading = true;
      downloadProgress = 0.0;
      notifyListeners();

      final dio = Dio(BaseOptions(
        headers: {'tkn': Env.tkn},
        responseType: ResponseType.stream,
      ));

      final url = '$_baseUrl$pedidoId/archivo/$nombreArchivo';

      final response = await dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );

      final filePath = '${dirDestino.path}\\$nombreArchivo';
      final file = File(filePath);

      final total = response.headers.value(HttpHeaders.contentLengthHeader) != null
          ? int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!)
          : 0;

      final sink = file.openWrite();
      int received = 0;

      await for (var chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total != 0) {
          downloadProgress = received / total;
          notifyListeners();
        }
      }

      await sink.close();

      downloadProgress = 1.0;
      isDownloading = false;
      notifyListeners();

      return file;
    } catch (e) {
      debugPrint('Error en descarga: $e');
      isDownloading = false;
      downloadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  /// Descargar todos los archivos de un pedido como ZIP
  Future<File?> descargarArchivosZIP({
    required String pedidoId,
    required BuildContext context,
    bool elegirCarpeta = true,
  }) async {
      isDownloading = true;
      downloadProgress = 0.0;
      

    try {
      // 1️⃣ Elegir carpeta de destino
      Directory dirDestino;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Loading.displaySpinLoading(context);
      });
      if (elegirCarpeta) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          lockParentWindow: true,
          dialogTitle: 'Selecciona dónde guardar el archivo ZIP',
        );
        
        if (selectedDirectory == null) {
          isDownloading = false;
          notifyListeners();
          if (!context.mounted) return null;
          Navigator.pop(context);
          return null;
        }
        
        dirDestino = Directory(selectedDirectory);
      } else {
        final userProfile = Platform.environment['USERPROFILE'];
        dirDestino = Directory('$userProfile\\Downloads');
      }
      if (!context.mounted) return null;
      Navigator.pop(context);

      notifyListeners();

      // 2️⃣ Descargar el ZIP
      final dio = Dio(BaseOptions(
        headers: {'tkn': Env.tkn},
        responseType: ResponseType.stream,
      ));

      final url = '$_baseUrl$pedidoId/archivos';

      final response = await dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );

      // 3️⃣ Obtener nombre del archivo ZIP
      String fileName = 'pedido_$pedidoId.zip';
      
      final contentDisposition = response.headers.value('content-disposition');
      if (contentDisposition != null) {
        final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          fileName = filenameMatch.group(1)!;
        }
      }

      final filePath = '${dirDestino.path}\\$fileName';
      final file = File(filePath);

      // 4️⃣ Guardar el archivo con progreso
      final total = response.headers.value(HttpHeaders.contentLengthHeader) != null
          ? int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!)
          : 0;

      final sink = file.openWrite();
      int received = 0;

      await for (var chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total != 0) {
          downloadProgress = received / total;
          notifyListeners();
        }
      }

      await sink.close();

      downloadProgress = 1.0;
      isDownloading = false;
      notifyListeners();

      return file;
    } catch (e) {
      debugPrint('Error en descarga: $e');
      isDownloading = false;
      downloadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  Future<bool> actualizarEstadoPedido({
    required String pedidoId,
    required String estado,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final connectionId = WebSocketService.connectionId;

      final headers = {
        'tkn': Env.tkn,
        if (connectionId != null) 'X-Connection-Id': connectionId,
      };

      final url = Uri.parse('$_baseUrl$pedidoId/estado');

      final response = await http.patch(
        url,
        headers: headers,
        body: {'estado': estado},
      );

      if (response.statusCode == 200) {
        if (estado == 'entregado'){
          pedidosNotReady.removeWhere((element) => element.id == pedidoId);
          pedidosReady.removeWhere((element) => element.id == pedidoId);
          notifyListeners();
          return true;
        }

        // Actualizar el pedido en la lista local
        final pedidoActualizado = Pedidos.fromJson(response.body);
        
        // Buscar en pedidosReady
        int index = pedidosReady.indexWhere((p) => p.id == pedidoId);
        if (index != -1) {
          pedidosReady[index] = pedidoActualizado;
        }
        
        // Buscar en pedidosNotReady
        index = pedidosNotReady.indexWhere((p) => p.id == pedidoId);
        if (index != -1) {
          pedidosNotReady[index] = pedidoActualizado;
        }
        
        // Reorganizar las listas según el nuevo estado
        organizar();
        notifyListeners();
        return true;
      } else {
        debugPrint('Error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}