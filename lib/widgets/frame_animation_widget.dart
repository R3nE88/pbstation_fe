import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  List<ImageProvider> _preloadedImages = [];
  bool _isLoading = true;
  int _currentFrame = 0;
  int _frameCount = 0;
  late Ticker _ticker;
  Duration _startTime = Duration.zero;
  int _completedCycles = 0;
  bool _tickerStarted = false;

  int get _effectiveFrameCount =>
      (_frameCount / widget.frameStep).floor(); // total de frames a mostrar

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    try {
      final manifestContent =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final framePaths = manifestMap.keys
          .where((String key) =>
              key.startsWith('assets/frames/') && key.endsWith('.png'))
          .toList()
        ..sort();

      _frameCount = framePaths.length;

      if (_frameCount == 0) {
        return;
      }

      final List<ImageProvider> images = [];
      for (String path in framePaths) {
        final image = AssetImage(path);
        images.add(image);

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_tickerStarted) {
            _tickerStarted = true;
            _ticker.start();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading frames: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _frameCount == 0) return;

    if (_startTime == Duration.zero) {
      _startTime = elapsed;
    }

    final elapsedTime = elapsed - _startTime;
    final elapsedSeconds = elapsedTime.inMicroseconds / 1000000.0;

    // totalFrames basado en tiempo real
    final totalFrames = elapsedSeconds * widget.fps;
    final newFrameIndex = (totalFrames % _effectiveFrameCount).floor();
    final currentCycle = (totalFrames / _effectiveFrameCount).floor();

    if (currentCycle > _completedCycles) {
      _completedCycles = currentCycle;
      widget.onAnimationComplete?.call();
    }

    if (_currentFrame != newFrameIndex) {
      setState(() {
        _currentFrame = newFrameIndex;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const SizedBox(); }

    if (_preloadedImages.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(child: Text('No frames loaded')),
      );
    }

    // Calcular qué frame real corresponde según el "step"
    final actualFrame = (_currentFrame * widget.frameStep).clamp(0, _frameCount - 1);

    return Image(
      image: _preloadedImages[actualFrame],
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
  }
}
