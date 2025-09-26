import 'dart:async';
import 'dart:io' show WebSocket;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
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
    UsuariosServices usuariosServices,
    VentasServices ventasServices,
    VentasEnviadasServices ventasEnviadasServices,
    SucursalesServices sucursalesServices,
    CotizacionesServices cotizacionesServices,
    Configuracion configuracion,
    ImpresorasServices impresoraService
  ) {
    // Guardamos servicios en la única instancia
    _instance._productoSvc     = productosService;
    _instance._clienteSvc      = clientesService;
    _instance._usuariosSvc     = usuariosServices;
    _instance._ventaSvc        = ventasServices;
    _instance._ventaEnviadasSvc= ventasEnviadasServices;
    _instance._sucursalSvc     = sucursalesServices;
    _instance._cotizacionesSvc = cotizacionesServices;
    _instance._config          = configuracion;
    _instance._impresoraSvc    = impresoraService;

    // Configuramos handlers según los servicios
    _instance._setupHandlers();
    return _instance;
  }

  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool isConnected = false;
  final List<String> mensajesRecibidos = [];

  // Servicios inyectados
  late ProductosServices _productoSvc;
  late ClientesServices _clienteSvc;
  late UsuariosServices _usuariosSvc;
  late VentasServices _ventaSvc;
  late VentasEnviadasServices _ventaEnviadasSvc;
  late SucursalesServices _sucursalSvc;
  late CotizacionesServices _cotizacionesSvc;
  late Configuracion _config;
  late ImpresorasServices _impresoraSvc;

  // Map de comandos a handlers
  final Map<String, void Function(String)> _handlers = {};

  static bool reconectandoSucursal = false;

  /// Construye la URL del WebSocket con o sin sucursal
  String _buildSocketUrl() {
    String baseUrl = 'ws:${Constantes.baseUrl}ws';
    
    // Obtener sucursal actual
    String? sucursalId = SucursalesServices.sucursalActualID;
    
    if (sucursalId != null && sucursalId.isNotEmpty) {
      // Agregar sucursal como query parameter
      baseUrl = '$baseUrl?sucursal_id=$sucursalId';
      if (kDebugMode) print('WebSocket conectando con sucursal: $sucursalId');
    } else {
      if (kDebugMode) print('WebSocket conectando sin sucursal específica');
    }
    
    return baseUrl;
  }

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
        'post-usuario':      (id) => _usuariosSvc.loadAUsuario(id),
        'put-usuario':       (id) => _usuariosSvc.updateAUsuario(id),
        'delete-usuario':    (id) => _usuariosSvc.deleteAUsuario(id),
        'post-sucursal':     (id) => _sucursalSvc.loadASucursal(id),
        'put-sucursal':      (id) => _sucursalSvc.updateASucursal(id),
        'delete-sucursal':   (id) => _sucursalSvc.deleteASucursal(id),
        'post-cotizacion':   (id) => _cotizacionesSvc.loadACotizacion(id),
        //'put-cotizacion':    (id) => _cotizacionesSvc.updateACotizacion(id),
        //'delete-cotizacion': (id) => _cotizacionesSvc.deleteACotizacion(id),
        
        // Estos ahora solo llegarán a la sucursal correspondiente automáticamente
        'post-impresora':    (id) => _impresoraSvc.loadAImpresora(id), //Tambien carga el contador
        'put-impresora':     (id) => _impresoraSvc.updateAImpresora(id),
        'delete-impresora':  (id) => _impresoraSvc.deleteAImpresora(id),
        'post-contadores':   (id) => _impresoraSvc.loadUltimoContador(id),
        'put-contadores':    (id) => _impresoraSvc.loadUltimoContador(id),
        'delete-contadores': (id) => _impresoraSvc.deleteAContador(id),
        'delete-venta-deuda':   (id) => _ventaSvc.removeAVentaDeuda(id),
        /*'post-venta':        (id) => _ventaSvc.loadAVenta(id),
        'put-venta':         (id) => _ventaSvc.updateAVenta(id),*/
        
        'ventaenviada':      (id) {
          if (id == SucursalesServices.sucursalActualID){
            _ventaEnviadasSvc.recibirVenta();
          }
        },
      });
  }

  /// Abre la conexión WebSocket y comienza a escuchar.
  Future<void> conectar({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      // Limpieza previa
      _subscription?.cancel();
      _subscription = null;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Aseguramos estado inicial
      _channel = null;
      isConnected = false;
      notifyListeners();

      // Construir URL con sucursal
      final socketUrl = _buildSocketUrl();
      
      if (kDebugMode) print('Intentando conectar WebSocket a $socketUrl ...');

      // Esperamos al handshake. Timeout para evitar espera infinita.
      final socket = await WebSocket.connect(socketUrl).timeout(timeout);

      // Si llegamos aquí, el handshake tuvo éxito: convertimos a IOWebSocketChannel
      _channel = IOWebSocketChannel(socket);

      // Listener: recibe mensajes y detecta cierre/errores.
      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: () {
          if (kDebugMode) print('WebSocket cerrado por el servidor (onDone).');
          _onDisconnected();
        },
        onError: (error, stackTrace) {
          if (kDebugMode) print('Error en WebSocket (onError): $error');
          _onDisconnected();
        },
        cancelOnError: true,
      );

      // Ya confirmado handshake, marcamos conectado
      isConnected = true;
      notifyListeners();
      if (kDebugMode) print('WebSocket conectado (handshake ok).');
    } on TimeoutException catch (te) {
      if (kDebugMode) print('Timeout al conectar WebSocket: $te');
      _onDisconnected();
    } catch (e, st) {
      if (kDebugMode) {
        print('Error al conectar WebSocket (catch): $e');
        print(st);
      }
      _onDisconnected();
    }
  }

  /// Reconectar con nueva sucursal (útil cuando cambia la sucursal activa)
  Future<void> _reconectarConSucursal() async {
    if (kDebugMode) print('Reconectando WebSocket con nueva sucursal...');
    reconectandoSucursal = true;
    desconectar();
    await Future.delayed(Duration(milliseconds: 500)); // Pequeña pausa
    await conectar();
    reconectandoSucursal = false;
  }

  Future<void> _reconectarSinSucursal() async {
    if (kDebugMode) print('Reconectando WebSocket...');
    reconectandoSucursal = true;
    desconectar();
    await Future.delayed(Duration(milliseconds: 500)); // Pequeña pausa
    await conectar();
    reconectandoSucursal = false;
  }

  /// Método estático para reconectar desde fuera de la clase
  static Future<void> reconectarConSucursal() async {
    return _instance._reconectarConSucursal();
  }
  static Future<void> reconectarSinSucursal() async {
    return _instance._reconectarSinSucursal();
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
      try {
        handler(arg);
      } catch (e) {
        if (kDebugMode) print('Error en handler $cmd: $e');
      }
    } else if (kDebugMode) {
      print('Comando no reconocido: $cmd');
    }
  }

  /// Maneja la desconexión y programa reconectar.
  void _onDisconnected() {
    if (kDebugMode) print('WebSocket desconectado');
    // Aseguramos cerrar recursos
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    isConnected = false;
    notifyListeners();

    _scheduleReconnect();
  }

  /// Cierra la conexión y cancela reconexión.
  void desconectar() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    isConnected = false;
    notifyListeners();
  }

  /// Envía mensaje si está conectado.
  void enviar(String mensaje) {
    if (isConnected && _channel != null) {
      try {
        _channel!.sink.add(mensaje);
      } catch (e) {
        if (kDebugMode) print('Error al enviar mensaje: $e');
        // Forzar reconexión si ocurre error al enviar
        _onDisconnected();
      }
    } else if (kDebugMode) {
      print('No está conectado; mensaje no enviado');
    }
  }

  /// Programa reintento de conexión tras un retraso fijo.
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    const delay = 5;
    if (kDebugMode) print('Reintentando conexión en $delay s');
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      conectar();
    });
  }

  /// Indica si la app debe bloquearse.
  bool isAppBlocked() => !isConnected;

  /// Opcional: cuando el servicio ya no se use.
  void disposeService() {
    desconectar();
    // no llames super.dispose() porque no es StatefullWidget, pero si lo usas como provider,
    // podrías llamar notifyListeners() si hace falta.
  }
}