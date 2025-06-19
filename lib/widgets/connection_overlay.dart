import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/services/websocket_service.dart';

class ConnectionOverlay extends StatelessWidget {
  const ConnectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Consumer<WebSocketService>(
        builder: (context, webSocketService, child) {
          // Si está conectado, no muestra nada y permite interacción
          if (webSocketService.isConnected) {
            return const SizedBox.shrink();
          }
          // Muestra un overlay full-screen sin usar Positioned
          return IgnorePointer(
            // Bloquea interacción debajo del overlay
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black45,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Conexión perdida con el servidor',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Reconectando...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}