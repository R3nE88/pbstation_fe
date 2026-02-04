import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';

/// Widget de búsqueda optimizado con debounce, virtualización y manejo de teclas mejorado.
///
/// Características:
/// - Debounce configurable (default 300ms)
/// - Virtualización para listas grandes (5000+ elementos)
/// - Enter selecciona el elemento, Tab solo pasa al siguiente focus
/// - Escape cierra la lista sin seleccionar
/// - Tecla configurable para llamar al focus desde cualquier posición
class BusquedaField<T extends Object> extends StatefulWidget {
  const BusquedaField({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemUnselected,
    required this.onItemSelected,
    required this.displayStringForOption,
    this.secondaryDisplayStringForOption,
    required this.normalBorder,
    required this.icono,
    required this.defaultFirst,
    required this.hintText,
    this.teclaFocus,
    required this.error,
    this.showSecondaryFirst = true,
    this.onKeyHandler,
    this.debounceDuration = const Duration(milliseconds: 50),
    this.maxVisibleItems = 10,
  });

  /// Lista de items a buscar
  final List<T> items;

  /// Callback cuando se selecciona un item (puede ser null si se deselecciona)
  final Function(T?) onItemSelected;

  /// Callback cuando se pierde el focus sin selección
  final Function() onItemUnselected;

  /// Item actualmente seleccionado
  final T? selectedItem;

  /// Función para mostrar el texto principal del item
  final String Function(T) displayStringForOption;

  /// Función opcional para mostrar texto secundario (ej: código, teléfono)
  final String Function(T)? secondaryDisplayStringForOption;

  /// Si es true, usa borde completamente redondeado; si es false, solo izquierda
  final bool normalBorder;

  /// Ícono que aparece como prefijo en el campo
  final IconData icono;

  /// Si es true y el campo está vacío al perder focus, selecciona el primer item
  final bool defaultFirst;

  /// Texto placeholder del campo
  final String hintText;

  /// Tecla para llamar al focus desde cualquier posición (ej: F2)
  final LogicalKeyboardKey? teclaFocus;

  /// Si es true, muestra el borde en rojo (estado de error)
  final bool error;

  /// Si es true, muestra el texto secundario primero: "secundario - principal"
  final bool showSecondaryFirst;

  /// Callback opcional para manejar teclas desde el widget padre
  final bool Function(KeyEvent)? onKeyHandler;

  /// Duración del debounce para la búsqueda
  final Duration debounceDuration;

  /// Número máximo de items visibles en la lista desplegable
  final int maxVisibleItems;

  @override
  State<BusquedaField<T>> createState() => _BusquedaFieldState<T>();
}

class _BusquedaFieldState<T extends Object> extends State<BusquedaField<T>> {
  // Controllers
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // Estado
  List<T> _filteredOptions = [];
  int _highlightedIndex = 0;
  T? _selectedItem;
  bool _isDropdownOpen = false;

  // Debounce
  Timer? _debounceTimer;

  // Keyboard handler
  bool _keyboardHandlerRegistered = false;

  // Overlay
  OverlayEntry? _overlayEntry;

  // Constantes de estilo (mantienen la apariencia actual)
  static const BorderRadius _bordeIzquierdo = BorderRadius.only(
    topLeft: Radius.circular(30),
    bottomLeft: Radius.circular(30),
  );
  static const BorderRadius _bordeCompleto = BorderRadius.all(
    Radius.circular(30),
  );

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    _controller = TextEditingController(
      text:
          _selectedItem != null
              ? widget.displayStringForOption(_selectedItem!)
              : '',
    );

    _focusNode.addListener(_onFocusChange);
    _registerKeyboardHandler();
  }

  @override
  void didUpdateWidget(BusquedaField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar tecla de focus si cambió
    if (oldWidget.teclaFocus != widget.teclaFocus) {
      _unregisterKeyboardHandler();
      _registerKeyboardHandler();
    }

    // Sincronizar con selectedItem del widget padre
    if (widget.selectedItem != oldWidget.selectedItem) {
      _syncWithParentSelection();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _unregisterKeyboardHandler();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ==================== Keyboard Handler ====================

  void _registerKeyboardHandler() {
    if (widget.teclaFocus != null && !_keyboardHandlerRegistered) {
      HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
      _keyboardHandlerRegistered = true;
    }
  }

  void _unregisterKeyboardHandler() {
    if (_keyboardHandlerRegistered) {
      HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
      _keyboardHandlerRegistered = false;
    }
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    // Primero dar oportunidad al callback externo
    if (widget.onKeyHandler != null) {
      if (widget.onKeyHandler!(event)) {
        return true; // El callback externo consumió el evento
      }
    }

    // Manejar tecla de focus (ej: F2)
    if (event is KeyDownEvent && event.logicalKey == widget.teclaFocus) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
      return true;
    }
    return false;
  }

  // ==================== Focus Management ====================

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _handleFocusLost();
    }
  }

  void _handleFocusLost() {
    _removeOverlay();

    final currentText = _controller.text.trim();

    // Verificar si el texto actual corresponde a un item válido
    T? matchingItem;
    if (currentText.isNotEmpty) {
      try {
        matchingItem = widget.items.firstWhere(
          (item) => widget.displayStringForOption(item) == currentText,
        );
      } catch (_) {
        // No se encontró coincidencia exacta
        matchingItem = null;
      }
    }

    if (matchingItem != null) {
      // El texto coincide con un item válido - seleccionarlo
      if (_selectedItem != matchingItem) {
        _selectItem(matchingItem);
      }
    } else {
      // El texto NO coincide con ningún item - limpiar todo
      _controller.clear();
      _filteredOptions.clear();
      _selectedItem = null;
      widget.onItemSelected(null);
      widget.onItemUnselected();
    }

    if (mounted) setState(() {});
  }

  void _syncWithParentSelection() {
    if (widget.selectedItem == null &&
        _selectedItem != null &&
        !widget.defaultFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedItem = null;
            _controller.clear();
          });
        }
      });
    } else if (widget.selectedItem != null && _selectedItem == null) {
      _selectedItem = widget.selectedItem;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = widget.displayStringForOption(_selectedItem!);
        }
      });
    }
  }

  // ==================== Search & Filter ====================

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      _removeOverlay();
      _selectedItem = null;
      widget.onItemSelected(null);
      setState(() {
        _filteredOptions.clear();
      });
      return;
    }

    _debounceTimer = Timer(widget.debounceDuration, () {
      _filterItems(value);
    });
  }

  void _filterItems(String query) {
    if (!mounted) return;

    final queryLower = query.toLowerCase();

    _filteredOptions =
        widget.items.where((item) {
          final primary = widget.displayStringForOption(item).toLowerCase();
          final secondary =
              widget.secondaryDisplayStringForOption
                  ?.call(item)
                  .toLowerCase() ??
              '';
          return primary.contains(queryLower) || secondary.contains(queryLower);
        }).toList();

    _highlightedIndex = 0;

    setState(() {});

    if (_filteredOptions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  // ==================== Selection ====================

  void _selectItem(T item) {
    _controller.text = widget.displayStringForOption(item);
    _selectedItem = item;
    widget.onItemSelected(item);
    _removeOverlay();

    if (mounted) setState(() {});
  }

  void _selectHighlightedAndMoveNext() {
    if (_filteredOptions.isNotEmpty &&
        _highlightedIndex < _filteredOptions.length) {
      _selectItem(_filteredOptions[_highlightedIndex]);
    }
    FocusScope.of(context).nextFocus();
  }

  // ==================== Keyboard Navigation ====================

  KeyEventResult _handleFieldKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (_filteredOptions.isNotEmpty) {
          setState(() {
            _highlightedIndex =
                (_highlightedIndex + 1) % _filteredOptions.length;
          });
          _updateOverlay();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (_filteredOptions.isNotEmpty) {
          setState(() {
            _highlightedIndex =
                (_highlightedIndex - 1 + _filteredOptions.length) %
                _filteredOptions.length;
          });
          _updateOverlay();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        // Enter SELECCIONA el elemento y pasa al siguiente focus
        if (_filteredOptions.isNotEmpty) {
          _selectHighlightedAndMoveNext();
          return KeyEventResult.handled;
        } else if (widget.defaultFirst &&
            widget.items.isNotEmpty &&
            _controller.text.isEmpty) {
          _selectItem(widget.items.first);
          FocusScope.of(context).nextFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;

      case LogicalKeyboardKey.tab:
        // Tab NO selecciona, solo pasa al siguiente focus
        _removeOverlay();
        return KeyEventResult.ignored; // Dejar que Flutter maneje el Tab

      case LogicalKeyboardKey.escape:
        // Escape cierra el dropdown sin seleccionar
        if (_isDropdownOpen) {
          _removeOverlay();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;

      default:
        return KeyEventResult.ignored;
    }
  }

  // ==================== Overlay (Dropdown) ====================

  void _showOverlay() {
    if (_overlayEntry != null) {
      _updateOverlay();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownOpen = true;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: 500,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(30, size.height + 4), // Pequeño gap
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primario1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.letraClara.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildOptionsList(),
              ),
            ),
          ),
    );
  }

  Widget _buildOptionsList() {
    final visibleCount =
        _filteredOptions.length > widget.maxVisibleItems
            ? widget.maxVisibleItems
            : _filteredOptions.length;

    return SizedBox(
      height: visibleCount * 44.0, // Altura fija por item
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemExtent: 44.0, // Mejora rendimiento con altura fija
        itemCount: _filteredOptions.length,
        itemBuilder: (context, index) => _buildOptionItem(index),
      ),
    );
  }

  Widget _buildOptionItem(int index) {
    final T option = _filteredOptions[index];
    final isHighlighted = index == _highlightedIndex;
    final isFirst = index == 0;
    final isLast = index == _filteredOptions.length - 1;

    final secondary =
        widget.secondaryDisplayStringForOption?.call(option).trim() ?? '';
    final primary = widget.displayStringForOption(option);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _selectItem(option);
          FocusScope.of(context).nextFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isHighlighted
                    ? AppTheme.secundario1.withOpacity(0.8)
                    : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(12) : Radius.zero,
              bottom: isLast ? const Radius.circular(12) : Radius.zero,
            ),
          ),
          child: Row(
            children: [
              if (secondary.isNotEmpty) ...[
                Text(
                  secondary,
                  style: TextStyle(
                    color: AppTheme.letraClara.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '—',
                    style: TextStyle(
                      color: AppTheme.letraClara.withOpacity(0.3),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  primary,
                  style: AppTheme.subtituloPrimario.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    // Sincronizar selección cuando el padre cambia a null
    if (widget.selectedItem == null &&
        _selectedItem != null &&
        !widget.defaultFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedItem = null;
            _controller.clear();
          });
        }
      });
    }

    if (widget.selectedItem != null && _selectedItem == null) {
      _selectedItem = widget.selectedItem;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.displayStringForOption(_selectedItem!);
      });
    }

    final borderRadius = widget.normalBorder ? _bordeCompleto : _bordeIzquierdo;
    final borderColor = widget.error ? Colors.red : AppTheme.letraClara;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _handleFieldKeyEvent,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          maxLength: 50,
          buildCounter:
              (
                _, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) => null,
          autofocus: _selectedItem == null,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: borderColor, width: 3),
            ),
            isDense: true,
            prefixIcon: Icon(widget.icono, size: 25, color: AppTheme.letra70),
            hintText: widget.hintText,
          ),
          onChanged: _onSearchChanged,
          onEditingComplete: () {
            if (_filteredOptions.isNotEmpty) {
              _selectHighlightedAndMoveNext();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
        ),
      ),
    );
  }
}
