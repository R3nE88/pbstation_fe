import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/provider/loading_state.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/widgets/widgets.dart'; // Importa tu WindowBar

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  OverlayEntry? _overlayEntry;
  bool _show = false;

  Future<void> esperarParaMostrar() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _show = true);
  }

  @override
  void initState() {
    super.initState();
    esperarParaMostrar();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  Map<ShortcutActivator, Intent> _buildBlockingShortcuts() {
    final Map<ShortcutActivator, Intent> shortcuts = {};
    
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

    for (final key in keysToBlock) {
      shortcuts[SingleActivator(key)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, control: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, shift: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, alt: true)] = const DoNothingAndStopPropagationIntent();
      shortcuts[SingleActivator(key, meta: true)] = const DoNothingAndStopPropagationIntent();
    }

    return shortcuts;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    if (_show == false) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Shortcuts(
          shortcuts: _buildBlockingShortcuts(),
          child: Actions(
            actions: {
              DoNothingAndStopPropagationIntent: CallbackAction<DoNothingAndStopPropagationIntent>(
                onInvoke: (intent) => null,
              ),
            },
            child: KeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                // Bloquear eventos de teclado
              },
              child: Focus(
                autofocus: true,
                canRequestFocus: true,
                onKeyEvent: (node, event) {
                  return KeyEventResult.handled;
                },
                child: Stack(
                  children: [
                    // Contenido principal del overlay (bloqueador)
                    GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black45,
                        alignment: Alignment.center,
                        // ignore: prefer_const_constructors
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [

                            /*Text(
                              'Espere un momento',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),*/
                            
                            CircularProgressIndicator()

                          ],
                        ),
                      ),
                    ),
                    
                    // WindowBar en la parte superior
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: WindowBar(overlay: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

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
    return Consumer<LoadingProvider>(
      builder: (context, loadingProvider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!loadingProvider.isLoading) {
            _hideOverlay();
          } else {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            _showOverlay();
          }
        });
    
        return const SizedBox.shrink();
      },
    );
  }
}