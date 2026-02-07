import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio singleton para precargar frames de animación.
/// Debe inicializarse temprano en el ciclo de vida de la app para
/// que los frames estén listos cuando se necesite mostrar la animación.
class FramePreloaderService {
  static final FramePreloaderService _instance =
      FramePreloaderService._internal();
  factory FramePreloaderService() => _instance;
  FramePreloaderService._internal();

  // Imágenes decodificadas listas para RawImage (más rápido)
  List<ui.Image> _decodedImages = [];
  int _frameCount = 0;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  /// Lista de imágenes decodificadas listas para usar
  List<ui.Image> get decodedImages => _decodedImages;

  /// Número total de frames
  int get frameCount => _frameCount;

  /// Si los frames están cargados y listos para usar
  bool get isLoaded => _isLoaded;

  /// Si está en proceso de carga
  bool get isLoading => _isLoading;

  /// Error si hubo algún problema durante la carga
  String? get error => _error;

  /// Precarga los frames de animación desde assets/frames/
  /// Esta función es idempotente: si ya está cargado o cargando, no hace nada.
  Future<void> preloadFrames(BuildContext context) async {
    // Si ya está cargado o cargando, no hacer nada
    if (_isLoaded || _isLoading) return;

    _isLoading = true;
    _error = null;

    try {
      // NUEVA API para Flutter 3.38+
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      // Obtener todos los assets
      final allAssets = assetManifest.listAssets();

      // Filtrar solo los frames
      final framePaths =
          allAssets
              .where(
                (String key) =>
                    key.startsWith('assets/frames/') && key.endsWith('.png'),
              )
              .toList()
            ..sort();

      _frameCount = framePaths.length;

      if (_frameCount == 0) {
        debugPrint(
          'FramePreloaderService: No se encontraron frames en assets/frames/',
        );
        _isLoading = false;
        _isLoaded = true; // Marcamos como "cargado" aunque esté vacío
        return;
      }

      debugPrint('FramePreloaderService: Precargando $_frameCount frames...');

      final List<ui.Image> decoded = [];
      for (String path in framePaths) {
        final image = AssetImage(path);

        // Resolver y decodificar la imagen a ui.Image
        final ImageStream stream = image.resolve(const ImageConfiguration());
        final completer = Completer<ui.Image>();

        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            stream.removeListener(listener);
            completer.complete(info.image);
          },
          onError: (exception, stackTrace) {
            stream.removeListener(listener);
            completer.completeError(exception);
          },
        );

        stream.addListener(listener);
        decoded.add(await completer.future);
      }

      _decodedImages = decoded;
      _isLoaded = true;
      debugPrint(
        'FramePreloaderService: $_frameCount frames precargados y decodificados',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('FramePreloaderService: Error al precargar frames: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Reinicia el servicio (útil para testing o hot reload)
  void reset() {
    _decodedImages = [];
    _frameCount = 0;
    _isLoading = false;
    _isLoaded = false;
    _error = null;
  }
}
