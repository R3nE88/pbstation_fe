import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/services/frame_preloader_service.dart';

class FrameAnimationWidget extends StatefulWidget {
  final double fps;
  final VoidCallback? onAnimationComplete;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int frameStep;

  const FrameAnimationWidget({
    super.key,
    this.fps = 60,
    this.onAnimationComplete,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.frameStep = 1,
  });

  @override
  State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
}

class _FrameAnimationWidgetState extends State<FrameAnimationWidget>
    with SingleTickerProviderStateMixin {
  // Usar ValueNotifier para evitar setState y rebuilds costosos
  final ValueNotifier<int> _currentFrameNotifier = ValueNotifier<int>(0);

  List<ui.Image> _decodedImages = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _frameCount = 0;
  late Ticker _ticker;
  Duration _startTime = Duration.zero;
  int _completedCycles = 0;
  bool _tickerStarted = false;

  // Precalcular duración por frame para evitar divisiones en cada tick
  late Duration _frameDuration;

  int get _effectiveFrameCount => (_frameCount / widget.frameStep).floor();

  @override
  void initState() {
    super.initState();
    // Precalcular la duración de cada frame
    _frameDuration = Duration(microseconds: (1000000 / widget.fps).round());
    _ticker = createTicker(_onTick);
    _initializeFrames();
  }

  void _initializeFrames() {
    final preloader = FramePreloaderService();

    // Si los frames ya están precargados y decodificados, usarlos inmediatamente
    if (preloader.isLoaded && preloader.decodedImages.isNotEmpty) {
      _decodedImages = preloader.decodedImages;
      _frameCount = preloader.frameCount;
      _isLoading = false;

      // Iniciar el ticker inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_tickerStarted) {
          _tickerStarted = true;
          _ticker.start();
        }
      });
    } else {
      // Fallback: cargar frames localmente si no están precargados
      _loadFramesFallback();
    }
  }

  /// Decodifica ImageProvider a ui.Image para renderizado directo (más rápido)
  Future<void> _decodeImages(List<ImageProvider> providers) async {
    try {
      final List<ui.Image> decoded = [];

      for (final provider in providers) {
        final ImageStream stream = provider.resolve(const ImageConfiguration());
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

      if (mounted) {
        setState(() {
          _decodedImages = decoded;
          _isLoading = false;
        });
        _startTicker();
      }
    } catch (e) {
      debugPrint('Error decoding images: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startTicker() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tickerStarted) {
        _tickerStarted = true;
        _ticker.start();
      }
    });
  }

  Future<void> _loadFramesFallback() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = assetManifest.listAssets();

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
        debugPrint('No se encontraron frames en assets/frames/');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      debugPrint('Cargando $_frameCount frames (fallback)...');

      final List<ImageProvider> providers =
          framePaths.map((path) => AssetImage(path) as ImageProvider).toList();

      await _decodeImages(providers);
    } catch (e) {
      debugPrint('Error loading frames: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _frameCount == 0 || _decodedImages.isEmpty) return;

    if (_startTime == Duration.zero) {
      _startTime = elapsed;
    }

    final elapsedTime = elapsed - _startTime;

    // Usar aritmética de enteros para mayor precisión
    final elapsedMicros = elapsedTime.inMicroseconds;
    final frameDurationMicros = _frameDuration.inMicroseconds;

    // Calcular frame actual usando división de enteros
    final totalFramesElapsed = elapsedMicros ~/ frameDurationMicros;
    final effectiveCount = _effectiveFrameCount;

    final newFrameIndex = totalFramesElapsed % effectiveCount;
    final currentCycle = totalFramesElapsed ~/ effectiveCount;

    // Verificar ciclo completado
    if (currentCycle > _completedCycles) {
      _completedCycles = currentCycle;
      widget.onAnimationComplete?.call();
    }

    // Solo actualizar si el frame cambió (usando ValueNotifier, no setState)
    if (_currentFrameNotifier.value != newFrameIndex) {
      _currentFrameNotifier.value = newFrameIndex;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _currentFrameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    if (_hasError || _decodedImages.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48),
              SizedBox(height: 8),
              Text('No frames loaded'),
              Text('Verifica assets/frames/ en pubspec.yaml'),
            ],
          ),
        ),
      );
    }

    // Usar RepaintBoundary para aislar los repaints de la animación
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: _currentFrameNotifier,
        builder: (context, currentFrame, _) {
          final actualFrame = (currentFrame * widget.frameStep).clamp(
            0,
            _frameCount - 1,
          );

          // Usar RawImage directamente en lugar de Image widget
          // Esto evita la creación de widgets intermedios
          return RawImage(
            image: _decodedImages[actualFrame],
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.contain,
            filterQuality: FilterQuality.low, // Más rápido para animaciones
          );
        },
      ),
    );
  }
}
