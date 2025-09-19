import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';

class VoucherBoard extends StatefulWidget {
  const VoucherBoard({super.key, this.onControllersChanged, required this.callback, required this.focusButton});
  final Function callback;
  final Function(List<TextEditingController>, List<TextEditingController>, List<TextEditingController>)? onControllersChanged;
  final FocusNode focusButton;

  @override
  State<VoucherBoard> createState() => _VoucherBoardState();
}

class _VoucherBoardState extends State<VoucherBoard> {
  final FocusNode _boardFocus = FocusNode();
  final GlobalKey<_VoucherSectionState> _debitoKey = GlobalKey();
  final GlobalKey<_VoucherSectionState> _creditoKey = GlobalKey();
  final GlobalKey<_VoucherSectionState> _transferenciasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Darle focus al contenedor global
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_boardFocus);

      // Agregar el handler de teclado
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    });
  }

  @override
  void dispose() {
    // Eliminar el handler de teclado al destruir el widget
    _boardFocus.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && widget.focusButton.hasFocus) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
        // Bloquear las flechas horizontales cuando focusButton está activo
        return true; // Devuelve true para indicar que el evento fue manejado
      }
    }
    return false; // Devuelve false para que el evento siga su curso normal
  }

  void _notifyControllers() {
    final debitoControllers = _debitoKey.currentState?._controllers ?? [];
    final creditoControllers = _creditoKey.currentState?._controllers ?? [];
    final transferenciaControllers = _transferenciasKey.currentState?._controllers ?? [];
    widget.onControllersChanged?.call(debitoControllers, creditoControllers, transferenciaControllers);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionIntent('up'),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionIntent('down'),
          LogicalKeySet(LogicalKeyboardKey.enter): const DirectionIntent('enter'),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionIntent('left'),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionIntent('right'),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DirectionIntent: CallbackAction<DirectionIntent>(
              onInvoke: (intent) {
                if (widget.focusButton.hasFocus) {
                  if (intent.direction == 'left' || intent.direction == 'right') {
                    // Bloquear las flechas izquierda y derecha cuando focusButton está activo
                    return null;
                  }
                  if (intent.direction == 'enter'){
                    siguiente();
                  }
                }
                if (intent.direction == 'down' || (intent.direction == 'enter' && !widget.focusButton.hasFocus)) {
                  if (_debitoKey.currentState?.hasFocus() == true) {
                    _creditoKey.currentState?.focusCurrent();
                  } else if (_creditoKey.currentState?.hasFocus() == true) {
                    _transferenciasKey.currentState?.focusCurrent();
                  } else if (_transferenciasKey.currentState?.hasFocus() == true) {
                    FocusScope.of(context).requestFocus(widget.focusButton);
                  } else {
                    _debitoKey.currentState?.focusCurrent();
                  }
                } else if (intent.direction == 'up') {
                  if (_transferenciasKey.currentState?.hasFocus() == true) {
                    _creditoKey.currentState?.focusCurrent();
                  } else if (_creditoKey.currentState?.hasFocus() == true) {
                    _debitoKey.currentState?.focusCurrent();
                  } else if (_debitoKey.currentState?.hasFocus() == true) {
                    FocusScope.of(context).requestFocus(widget.focusButton);
                  } else {
                    _transferenciasKey.currentState?.focusCurrent();
                  }
                }
                return null;
              },
            ),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VoucherSection(key: _debitoKey, title: "Débito", autoFocus: true),
              _VoucherSection(key: _creditoKey, title: "Crédito", autoFocus: false),
              _VoucherSection(key: _transferenciasKey, title: "Transferencias", autoFocus: false),
              ElevatedButton(
                focusNode: widget.focusButton,
                onPressed: () {
                  siguiente();
                },
                child: Text('Continuar')
              )
            ],
          ),
        ),
      ),
    );
  }

  void siguiente() {
    _notifyControllers();
    widget.callback();
  }
}

class DirectionIntent extends Intent {
  final String direction;
  const DirectionIntent(this.direction);
}


/// Sección con título y un carrusel de vouchers
class _VoucherSection extends StatefulWidget {
  const _VoucherSection({required this.title, super.key, required this.autoFocus});

  final String title;
  final bool autoFocus;

  @override
  State<_VoucherSection> createState() => _VoucherSectionState();
}

class _VoucherSectionState extends State<_VoucherSection> {
  final PageController _page = PageController(viewportFraction: 0.62);
  final List<TextEditingController> _controllers = [TextEditingController()];
  final List<FocusNode> _focusNodes = [FocusNode()];
  int _currentIndex = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    //Autofocus solo al primer formfield
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if(widget.autoFocus){ _focusNodes[0].requestFocus();}
  });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _page.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false; // No es un evento de tecla presionada, no lo manejamos
    }
    final key = event.logicalKey;

    final idx = _focusNodes.indexWhere((n) => n.hasFocus);
    if (idx == -1) {
      return false; // Ningún campo de texto en esta sección tiene foco
    }

    // ← retroceder
    if (key == LogicalKeyboardKey.arrowLeft && idx > 0) {
      _goTo(idx - 1);
      return true;
    }
    // → avanzar
    if (key == LogicalKeyboardKey.arrowRight) {
      _advanceFrom(idx);
      return true;
    }
    return false;
  }

  bool hasFocus() {
    return _focusNodes.any((node) => node.hasFocus);
  }

  void focusCurrent() {
    if (_currentIndex < _focusNodes.length) {
      FocusScope.of(context).requestFocus(_focusNodes[_currentIndex]);
    }
  }

  void _ensureNextBlank() {
    if (_controllers.isEmpty || _controllers.last.text.trim().isNotEmpty) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  void _recomputeTotal() {
    double sum = 0;
    final lastIsEmpty = _controllers.isNotEmpty && _controllers.last.text.trim().isEmpty;
    final len = lastIsEmpty ? _controllers.length - 1 : _controllers.length;
    for (var i = 0; i < len; i++) {
      final txt = _controllers[i].text.replaceAll('MX\$', '').replaceAll(',', '').trim();
      if (txt.isEmpty) continue;
      final v = double.tryParse(txt.replaceAll(',', '.')) ?? 0;
      sum += v;
    }
    setState(() => _total = sum);
  }

  Future<void> _advanceFrom(int index) async {
    if (index >= _controllers.length - 1) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
      setState(() {});
    }
    final next = index + 1;
    await _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = next);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (next < _focusNodes.length) {
        if (!mounted)return;
        FocusScope.of(context).requestFocus(_focusNodes[next]);
      }
    });
  }

  Future<void> _goTo(int index) async {
    await _page.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (index < _focusNodes.length) {
        if (!mounted)return;
        FocusScope.of(context).requestFocus(_focusNodes[index]);
      }
    });
  }

  Widget _buildField(int index) {
    double page = _currentIndex.toDouble();
    if (_page.hasClients && _page.position.haveDimensions) {
      page = (_page.page ?? _currentIndex.toDouble());
    }
    final dist = (page - index).abs();
    final scale = (1 - dist * 0.14).clamp(0.72, 1.0);
    final opacity = (1 - dist * 0.6).clamp(0.38, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextFormField(
            focusNode: _focusNodes[index],
            controller: _controllers[index],
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [PesosInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Monto',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (_) => _recomputeTotal(),
            onFieldSubmitted: (_) {
              _recomputeTotal();
              _advanceFrom(index);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureNextBlank();
    final enteredCount = _controllers.where((c) => c.text.trim().isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 50,
          child: PageView.builder(
            controller: _page,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              Future.microtask(() {
                if (!context.mounted)return;
                if (i < _focusNodes.length) FocusScope.of(context).requestFocus(_focusNodes[i]);
              });
              _ensureNextBlank();
            },
            itemCount: _controllers.length,
            itemBuilder: (context, index) => _buildField(index),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Total: ${Formatos.pesos.format(_total)}   (Vouchers: $enteredCount)",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}