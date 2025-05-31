import 'package:flutter/foundation.dart';
import 'package:pbstation_frontend/services/productos_services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService with ChangeNotifier {
  final String _socketUrl = 'ws://127.0.0.1:8000/ws'; // Cambia a tu IP si es necesario
  WebSocketChannel? _channel;

  bool isConnected = false;
  List<String> mensajesRecibidos = [];

  final ProductosServices productosService;
  WebSocketService(this.productosService);

  void conectar() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_socketUrl));
      isConnected = true;
      print('WebSocket conectado');

      _channel!.stream.listen(
        (message) {
          print('Mensaje recibido: $message');
          mensajesRecibidos.add(message);
          //notifyListeners();
          _procesarMensaje(message);
        },
        onDone: () {
          print('Conexión cerrada');
          isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          print('Error en WebSocket: $error');
          isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error al conectar WebSocket: $e');
    }
  }

  void desconectar() {
    _channel?.sink.close();
    isConnected = false;
    notifyListeners();
  }

  void enviar(String mensaje) {
    _channel?.sink.add(mensaje);
  }


  void _procesarMensaje(String mensaje) {
    if (mensaje.startsWith('post-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        print('→ Petición de recargar productos porque cambió el producto $id');
        productosService.loadProductos();
      } else {
        print('Error: mensaje WS mal formado: $mensaje');
      }
    } else if (mensaje.startsWith('delete-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        print('→ Petición de recargar productos porque cambió el producto $id');
        productosService.loadProductos();
      } else {
        print('Error: mensaje WS mal formado: $mensaje');
      }
    } else if (mensaje.startsWith('puy-product:')) {
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        print('→ Petición de recargar productos porque cambió el producto $id');
        productosService.loadProductos();
      } else {
        print('Error: mensaje WS mal formado: $mensaje');
      }
    } 
    else if (mensaje.startsWith('update-usuario:')) {
      // Si en el futuro quieres notificar algo de usuarios...
      final partes = mensaje.split(':');
      if (partes.length > 1) {
        final id = partes[1];
        print('→ Usuario $id actualizado (aquí podrías notificar a UsuariosServices)');
      }
    } else {
      print('Mensaje WS no reconocido: $mensaje');
    }
  }
}
