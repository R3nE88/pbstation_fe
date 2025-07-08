import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService with ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService(ProductosServices productosService, ClientesServices clientesService, VentasServices ventasServices) {
    _instance.productosService = productosService;
    _instance.clientesService = clientesService;
    _instance.ventasServices = ventasServices;
    return _instance;
  }

  WebSocketService._internal();

  final String _socketUrl = 'ws:${Constantes.baseUrl}ws'; // Cambia a tu IP si es necesario
  WebSocketChannel? _channel;

  bool isConnected = false;
  List<String> mensajesRecibidos = [];

  late ProductosServices productosService;
  late ClientesServices clientesService;
  late VentasServices ventasServices;

  Timer? _reconnectTimer;

  void conectar() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_socketUrl));
      isConnected = true;
      Future.microtask(() => notifyListeners());
      if (kDebugMode) {
        print('WebSocket conectado');
      }

      _channel!.stream.listen(
        (message) {
          if (kDebugMode) {
            print('Mensaje recibido: $message');
          }
          mensajesRecibidos.add(message);
          _procesarMensaje(message);
        },
        onDone: () {
          if (kDebugMode) {
            print('Conexión cerrada');
          }
          isConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error en WebSocket: $error');
          }
          isConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al conectar WebSocket: $e');
      }
      isConnected = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void desconectar() {
    _channel?.sink.close();
    isConnected = false;
    notifyListeners();
    _reconnectTimer?.cancel();
  }

  void enviar(String mensaje) {
    if (isConnected) {
      _channel?.sink.add(mensaje);
    } else {
      if (kDebugMode) {
        print('No se puede enviar el mensaje, WebSocket no está conectado');
      }
    }
  }

  void _procesarMensaje(String mensaje) {
    if (mensaje.startsWith('post-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de cargar el nuevo producto: $id');
        }
        productosService.loadAProducto(id);
      }
    } else if (mensaje.startsWith('delete-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de eliminar el producto: $id');
        }
        productosService.deleteAProducto(id);
      }
    } else if (mensaje.startsWith('put-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de recargar el productos: $id');
        }
        productosService.updateAProducto(id);
      }
    } else if (mensaje.startsWith('post-cliente:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de cargar el cliente nuevo: $id');
        }
        clientesService.loadACliente(id);
      }
    } else if (mensaje.startsWith('delete-cliente:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de eliminar el cliente: $id');
        }
        clientesService.deleteACliente(id);
      }
    } else if (mensaje.startsWith('put-cliente:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de recargar el cliente: $id');
        }
        clientesService.updateACliente(id);
      }
    } else if (mensaje.startsWith('post-venta:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de cargar venta nueva: $id');
        }
        //TODO: clientesService.loadAVenta(id); 
      }
    } else if (mensaje.startsWith('delete-venta:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        if (kDebugMode) {
          print('→ Petición de eliminar venta: $id');
        }
        //TODO: clientesService.deleteAVenta(id);
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        if (kDebugMode) {
          print('Intentando reconectar WebSocket...');
        }
        conectar();
      });
    }
  }

  bool isAppBlocked() {
    return !isConnected;
  }
}
