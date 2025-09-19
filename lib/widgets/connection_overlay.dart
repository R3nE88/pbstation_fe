import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class ConnectionOverlay extends StatefulWidget {
  const ConnectionOverlay({super.key});

  @override
  State<ConnectionOverlay> createState() => _ConnectionOverlayState();
}

class _ConnectionOverlayState extends State<ConnectionOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  Map<ShortcutActivator, Intent> _buildBlockingShortcuts() {
    final Map<ShortcutActivator, Intent> shortcuts = {};
    
    // Bloquear teclas individuales comunes
    final keysToBlock = [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.backspace,
      LogicalKeyboardKey.delete,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown,
      // Números
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
      // Letras
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.keyH,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyP,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyU,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyY,
      LogicalKeyboardKey.keyZ,
    ];

    // Agregar teclas individuales
    for (final key in keysToBlock) {
      shortcuts[SingleActivator(key)] = const DoNothingAndStopPropagationIntent();
      // También con modificadores
      shortcuts[SingleActivator(key, control: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, shift: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, alt: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, meta: true)] = const DoNothingAndStopPropagationIntent();
    }

    return shortcuts;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Shortcuts(
          shortcuts: _buildBlockingShortcuts(),
          child: Actions(
            actions: {
              DoNothingAndStopPropagationIntent: CallbackAction<DoNothingAndStopPropagationIntent>(
                onInvoke: (intent) => null, // No hacer nada
              ),
            },
            child: KeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                // Consumir todos los eventos de teclado sin procesarlos
                // No hacer nada aquí bloquea efectivamente el evento
              },
              child: Focus(
                autofocus: true,
                canRequestFocus: true,
                onKeyEvent: (node, event) {
                  // Bloquear TODOS los eventos de teclado
                  return KeyEventResult.handled;
                },
                child: GestureDetector(
                  onTap: () {}, // Capturar taps
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Conexión perdida con el servidor',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        const Text(
                          'Reconectando...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Insertar en el overlay raíz con la máxima prioridad
    final navigatorState = Navigator.of(context, rootNavigator: true);
    final overlay = navigatorState.overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (context, webSocketService, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (webSocketService.isConnected) {
            _hideOverlay();
          } else {
            // Quitar el foco de cualquier campo de texto activo
            FocusScope.of(context).unfocus();
            // Ocultar el teclado si está abierto
            FocusManager.instance.primaryFocus?.unfocus();
            _showOverlay();
          }
        });

        return const SizedBox.shrink();
      },
    );
  }
}