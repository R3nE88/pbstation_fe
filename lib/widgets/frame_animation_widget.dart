import 'dart:async';
import 'package:flutter/material.dart';

class FrameAnimationWidget extends StatefulWidget {
  final List<String> framePaths;
  final double fps;
  final bool loop;
  final VoidCallback? onAnimationComplete;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool preloadFrames;

  const FrameAnimationWidget({
    super.key,
    required this.framePaths,
    this.fps = 50.0,
    this.loop = false,
    this.onAnimationComplete,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.preloadFrames = true,
  });

  @override
  State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
}

class _FrameAnimationWidgetState extends State<FrameAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _frameAnimation;
  List<ImageProvider> _preloadedImages = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentFrame = 0;
  bool _shouldAutoPlay = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadFrames) {
      _preloadImages();
    } else {
      _setupAnimation();
      _isLoading = false;
      // Para el caso sin precarga, iniciar inmediatamente si autoPlay está en el padre
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shouldAutoPlay) {
          play();
        }
      });
    }
  }

  // Método para que el padre indique que debe hacer autoplay
  void setAutoPlay(bool autoPlay) {
    _shouldAutoPlay = autoPlay;
    if (!_isLoading && autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          play();
        }
      });
    }
  }

  Future<void> _preloadImages() async {
    try {
      final List<ImageProvider> images = [];
      
      for (String path in widget.framePaths) {
        final image = AssetImage(path);
        images.add(image);
        
        // Precargar imagen en el cache de Flutter
        final ImageStream stream = image.resolve(const ImageConfiguration());
        final completer = Completer<void>();
        
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            stream.removeListener(listener);
            completer.complete();
          },
          onError: (exception, stackTrace) {
            stream.removeListener(listener);
            completer.completeError(exception);
          },
        );
        
        stream.addListener(listener);
        await completer.future;
      }
      
      if (mounted) {
        setState(() {
          _preloadedImages = images;
          _isLoading = false;
        });
        _setupAnimation();
        
        // Auto-iniciar si está configurado para autoplay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _shouldAutoPlay) {
            play();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _setupAnimation();
      }
    }
  }

  void _setupAnimation() {
    final duration = Duration(
      milliseconds: ((widget.framePaths.length / widget.fps) * 1000).round(),
    );

    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _frameAnimation = IntTween(
      begin: 0,
      end: widget.framePaths.length - 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _frameAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _currentFrame = _frameAnimation.value;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Llamar callback SIEMPRE que termine un ciclo
        widget.onAnimationComplete?.call();
        
        if (widget.loop) {
          _controller.reset();
          _controller.forward();
        } else {
          _isPlaying = false;
        }
      }
    });
  }

  @override
  void didUpdateWidget(FrameAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.framePaths.length != widget.framePaths.length ||
        oldWidget.fps != widget.fps) {
      _controller.dispose();
      if (widget.preloadFrames) {
        _preloadImages();
      } else {
        _setupAnimation();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void play() {
    if (!_isPlaying && !_isLoading) {
      _isPlaying = true;
      _controller.reset();
      _controller.forward();
    }
  }

  void stop() {
    _isPlaying = false;
    _controller.stop();
    _controller.reset();
    if (mounted) {
      setState(() {
        _currentFrame = 0;
      });
    }
  }

  void pause() {
    _controller.stop();
  }

  void resume() {
    if (_isPlaying) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox();
    }

    if (widget.preloadFrames && _preloadedImages.isNotEmpty) {
      return Image(
        image: _preloadedImages[_currentFrame],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    } else {
      return Image.asset(
        widget.framePaths[_currentFrame],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        cacheWidth: widget.width?.toInt(),
        cacheHeight: widget.height?.toInt(),
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }
}

// Widget de conveniencia para usar con assets numerados con startIndex inteligente
class NumberedFrameAnimation extends StatefulWidget {
  final String basePath;
  final String extension;
  final int frameCount;
  final int startIndex; // Solo aplica en la primera vuelta
  final double fps;
  final bool loop;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool preloadFrames;

  const NumberedFrameAnimation({
    super.key,
    required this.basePath,
    this.extension = '.png',
    required this.frameCount,
    this.startIndex = 1,
    this.fps = 50.0,
    this.loop = false,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.preloadFrames = true,
  });

  @override
  State<NumberedFrameAnimation> createState() => _NumberedFrameAnimationState();
}

class _NumberedFrameAnimationState extends State<NumberedFrameAnimation> {
  final GlobalKey<_FrameAnimationWidgetState> _animationKey =
      GlobalKey<_FrameAnimationWidgetState>();
  bool _isFirstLoop = true;
  int _currentCycle = 0;

  List<String> _generateFramePaths({required bool isFirstLoop}) {
    if (isFirstLoop && widget.startIndex > 1) {
      // Primera vuelta: desde startIndex hasta frameCount, luego del 1 hasta startIndex-1
      List<String> paths = [];
      
      // Parte 1: desde startIndex hasta frameCount
      for (int i = widget.startIndex; i <= widget.frameCount; i++) {
        final frameNumber = i.toString().padLeft(4, '0');
        paths.add('${widget.basePath}$frameNumber${widget.extension}');
      }
      
      // Parte 2: desde 1 hasta startIndex-1
      for (int i = 1; i < widget.startIndex; i++) {
        final frameNumber = i.toString().padLeft(4, '0');
        paths.add('${widget.basePath}$frameNumber${widget.extension}');
      }
      
      return paths;
    } else {
      // Vueltas normales: del 1 al frameCount
      return List.generate(widget.frameCount, (index) {
        final frameNumber = (1 + index).toString().padLeft(4, '0');
        return '${widget.basePath}$frameNumber${widget.extension}';
      });
    }
  }

  void _onAnimationComplete() {
    _currentCycle++;
    
    // Llamar callback del usuario
    widget.onAnimationComplete?.call();
    
    if (widget.loop) {
      if (_isFirstLoop) {
        // Cambiar a modo normal después de la primera vuelta
        setState(() {
          _isFirstLoop = false;
        });
      }
      
      // Continuar con siguiente vuelta (esto lo manejará el FrameAnimationWidget)
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationWidget = FrameAnimationWidget(
      key: _animationKey,
      framePaths: _generateFramePaths(isFirstLoop: _isFirstLoop),
      fps: widget.fps,
      loop: widget.loop,
      onAnimationComplete: _onAnimationComplete,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      preloadFrames: widget.preloadFrames,
    );

    // Configurar autoplay después de que el widget se construya
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationKey.currentState?.setAutoPlay(true);
      });
    }

    return animationWidget;
  }

  // Métodos públicos para controlar la animación
  void play() {
    _isFirstLoop = true;
    _currentCycle = 0;
    _animationKey.currentState?.play();
  }
  
  void stop() {
    _isFirstLoop = true;
    _currentCycle = 0;
    _animationKey.currentState?.stop();
  }
  
  void pause() => _animationKey.currentState?.pause();
  void resume() => _animationKey.currentState?.resume();
  
  // Getter para saber en qué ciclo va
  int get currentCycle => _currentCycle;
  bool get isFirstLoop => _isFirstLoop;
} //el bueno :v