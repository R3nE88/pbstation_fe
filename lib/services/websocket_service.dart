import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/services/services.dart';

/// Singleton WebSocket service con fábrica parametrizada, reconexión automática y handlers dinámicos.
class WebSocketService with ChangeNotifier {
  // Instancia singleton
  static final WebSocketService _instance = WebSocketService._internal();

  /// Constructor de fábrica que inyecta dependencias y configura handlers.
  factory WebSocketService(
    ProductosServices productosService,
    ClientesServices clientesService,
    VentasServices ventasServices,
    VentasEnviadasServices ventasEnviadasServices,
    SucursalesServices sucursalesServices,
    CotizacionesServices cotizacionesServices,
    Configuracion configuracion,
  ) {
    // Guardamos servicios en la única instancia
    _instance._productoSvc     = productosService;
    _instance._clienteSvc      = clientesService;
    _instance._ventaSvc        = ventasServices;
    _instance._ventaEnviadasSvc= ventasEnviadasServices;
    _instance._sucursalSvc     = sucursalesServices;
    _instance._cotizacionesSvc = cotizacionesServices;
    _instance._config          = configuracion;

    // Configuramos handlers según los servicios
    _instance._setupHandlers();
    return _instance;
  }

  WebSocketService._internal();

  final String _socketUrl = 'ws:${Constantes.baseUrl}ws';
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  bool isConnected = false;
  final List<String> mensajesRecibidos = [];

  // Servicios inyectados
  late ProductosServices _productoSvc;
  late ClientesServices _clienteSvc;
  late VentasServices _ventaSvc;
  late VentasEnviadasServices _ventaEnviadasSvc;
  late SucursalesServices _sucursalSvc;
  late CotizacionesServices _cotizacionesSvc;
  late Configuracion _config;

  // Map de comandos a handlers
  final Map<String, void Function(String)> _handlers = {};

  /// Inicializa el mapa de comandos
  void _setupHandlers() {
    _handlers
      ..clear()
      ..addAll({
        'put-configuracion': (_ ) => _config.loadConfiguracion(),
        'post-product':      (id) => _productoSvc.loadAProducto(id),
        'put-product':       (id) => _productoSvc.updateAProducto(id),
        'delete-product':    (id) => _productoSvc.deleteAProducto(id),
        'post-cliente':      (id) => _clienteSvc.loadACliente(id),
        'put-cliente':       (id) => _clienteSvc.updateACliente(id),
        'delete-cliente':    (id) => _clienteSvc.deleteACliente(id),
        'post-sucursal':     (id) => _sucursalSvc.loadASucursal(id),
        'put-sucursal':      (id) => _sucursalSvc.updateASucursal(id),
        'post-cotizacion':   (id) => _cotizacionesSvc.loadACotizacion(id),
        'ventaenviada': (id) {
          if (id == SucursalesServices.sucursalActualID){
            _ventaEnviadasSvc.recibirVenta();
          }
        },
      });
  }

  /// Abre la conexión WebSocket y comienza a escuchar.
/// Abre la conexión WebSocket y comienza a escuchar.
void conectar() {
  try {
    _channel = WebSocketChannel.connect(Uri.parse(_socketUrl));
    isConnected = false; // No marcar como conectado inmediatamente
    notifyListeners();

    _subscription = _channel!.stream.listen(
      _onMessage,
      onDone: () {
        if (kDebugMode) print('WebSocket cerrado por el servidor.');
        _onDisconnected();
      },
      onError: (error, stackTrace) {
        if (kDebugMode) print('Error en WebSocket: $error');
        _onDisconnected();
      },
    );

    if (kDebugMode) print('Intentando conectar WebSocket...');

    // Validar conexión después de un breve retraso
    Future.delayed(Duration(seconds: 2), () {
      if (_channel != null && _channel!.sink != null) {
        isConnected = true;
        notifyListeners();
        if (kDebugMode) print('WebSocket conectado');
      } else {
        if (kDebugMode) print('No se pudo establecer la conexión WebSocket.');
        _onDisconnected();
      }
    });
  } catch (e) {
    if (kDebugMode) print('Error al conectar WebSocket: $e');
    _onDisconnected();
  }
}

  /// Procesa mensajes entrantes usando el mapa de handlers.
  void _onMessage(dynamic raw) {
    final msg = raw.toString();
    if (kDebugMode) print('Mensaje recibido: $msg');
    mensajesRecibidos.add(msg);

    final partes = msg.split(':');
    final cmd = partes[0];
    final arg = partes.length > 1 ? partes.sublist(1).join(':') : '';

    final handler = _handlers[cmd];
    if (handler != null) {
      handler(arg);
    } else if (kDebugMode) {
      print('Comando no reconocido: $cmd');
    }
  }

  /// Maneja la desconexión y programa reconectar.
  void _onDisconnected() {
    if (kDebugMode) print('WebSocket desconectado');
    isConnected = false;
    notifyListeners();
    _subscription?.cancel();
    _scheduleReconnect();
  }

  /// Cierra la conexión y cancela reconexión.
  void desconectar() {
    _subscription?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    isConnected = false;
    notifyListeners();
  }

  /// Envía mensaje si está conectado.
  void enviar(String mensaje) {
    if (isConnected) {
      _channel?.sink.add(mensaje);
    } else if (kDebugMode) {
      print('No está conectado; mensaje no enviado');
    }
  }

  /// Programa reintento de conexión tras un retraso fijo.
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    const delay = 5;
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (kDebugMode) print('Reintentando conexión en \$delay s');
      conectar();
    });
  }

  /// Indica si la app debe bloquearse.
  bool isAppBlocked() => !isConnected;
}
