/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/productos.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class BusquedaField2<T extends Object> extends StatefulWidget {
  final List<Productos> items;
  final Function(Productos?) onItemSelected;
  final String Function(Productos) displayStringForOption;
  final String Function(Productos)? secondaryDisplayStringForOption; // Hacerlo opcional
  final bool normalBorder;
  final IconData icono;
  final bool defaultFirst;
  final String hintText;
  final LogicalKeyboardKey? teclaFocus;

  const BusquedaField2({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.displayStringForOption,
    this.secondaryDisplayStringForOption, // Parámetro opcional
    required this.normalBorder,
    required this.icono,
    required this.defaultFirst, 
    required this.hintText, 
    this.teclaFocus,
  });

  @override
  State<BusquedaField2<T>> createState() => _BusquedaFieldState<T>();
}

class _BusquedaFieldState<T extends Object> extends State<BusquedaField2<T>> {
  late final bool Function(KeyEvent event) _keyHandler;
  late TextEditingController _controller;
  FocusNode? _focusNode; // Cambiar a nullable para usar solo el proporcionado por fieldViewBuilder
  List<Productos> _filteredOptions = [];
  int _highlightedIndex = 0;

  final BorderRadius borde = BorderRadius.only(
    topLeft: Radius.circular(30),
    bottomLeft: Radius.circular(30),
  );

  final BorderRadius bordeNormal = BorderRadius.all(
    Radius.circular(30),
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: VentaTabState.tabs[0].productoSelected != null ? widget.displayStringForOption(VentaTabState.tabs[0].productoSelected!) : '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _controller.text = VentaTabState.tabs[0].productoSelected != null ? widget.displayStringForOption(VentaTabState.tabs[0].productoSelected!) : '';
      });
    });
    
    if (widget.teclaFocus != null) {
      _keyHandler = (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == widget.teclaFocus) {
            print("${widget.teclaFocus} precionado");
            if (mounted && (_focusNode?.hasFocus ?? false) == false) {
              _focusNode?.requestFocus(); // Usar el FocusNode proporcionado
            }
          }
        }
        return false; // false para no consumir el evento
      };

      HardwareKeyboard.instance.addHandler(_keyHandler);
    }
  }

  @override
  void dispose() {
    if (widget.teclaFocus != null) {
      HardwareKeyboard.instance.removeHandler(_keyHandler);
    }
    super.dispose();
  }

  void _validateOrClear() {
    final match = widget.items.firstWhere(
      (item) => widget.displayStringForOption(item) == _controller.text,
      orElse: () => widget.items.isNotEmpty ? widget.items.first : throw Exception('No items available'),
    );

    VentaTabState.tabs[0].productoSelected = match;
    _controller.text = widget.displayStringForOption(match);
    widget.onItemSelected(match);
  }

  void _updateFilteredOptions(String value) {
    _filteredOptions = widget.items.where(
      (item) => widget.displayStringForOption(item).toLowerCase().contains(value.toLowerCase()) ||
                 (widget.secondaryDisplayStringForOption?.call(item) ?? '').toLowerCase().contains(value.toLowerCase()),
    ).toList();
    _highlightedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Productos>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return Iterable<Productos>.empty();
        }
        _updateFilteredOptions(textEditingValue.text);
        return _filteredOptions;
      },
      displayStringForOption: (Productos option) {
        final secondary = widget.secondaryDisplayStringForOption != null
            ? widget.secondaryDisplayStringForOption!(option).trim()
            : '';
        if (secondary.isEmpty) {
          return widget.displayStringForOption(option);
        }
        return "$secondary - ${widget.displayStringForOption(option)}";
      },
      onSelected: (Productos selected) {
        _controller.text = widget.displayStringForOption(selected);
        VentaTabState.tabs[0].productoSelected = selected;
        widget.onItemSelected(selected);
        FocusScope.of(context).nextFocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller = controller;
        _focusNode = focusNode; // Usar el FocusNode proporcionado
        return Focus(
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (_filteredOptions.isNotEmpty) {
                  setState(() {
                    _highlightedIndex = (_highlightedIndex + 1) % _filteredOptions.length;
                  });
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (_filteredOptions.isNotEmpty) {
                  setState(() {
                    _highlightedIndex = (_highlightedIndex - 1 + _filteredOptions.length) % _filteredOptions.length;
                  });
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                if (widget.items.isNotEmpty) {
                  if (_controller.text.isEmpty) {
                    if (widget.defaultFirst) {
                      setState(() {
                        final firstItem = widget.items.first;
                        _controller.text = widget.displayStringForOption(firstItem);
                        VentaTabState.tabs[0].productoSelected = firstItem;
                        widget.onItemSelected(firstItem);
                      });
                    }
                  } else if (_filteredOptions.isNotEmpty) {
                    final selected = _filteredOptions[_highlightedIndex];
                    _controller.text = widget.displayStringForOption(selected);
                    VentaTabState.tabs[0].productoSelected = selected;
                    widget.onItemSelected(selected);
                  } else {
                    setState(() {
                      _controller.clear();
                      _filteredOptions.clear();
                      VentaTabState.tabs[0].productoSelected = null;
                      widget.onItemSelected(null);
                    });
                  }
                }
                FocusScope.of(context).nextFocus();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              if (VentaTabState.tabs[0].productoSelected == null) {
                setState(() {
                  _controller.clear();
                  _filteredOptions.clear();
                  VentaTabState.tabs[0].productoSelected = null;
                  widget.onItemSelected(null);
                });
              }
            }
          },
          child: TextFormField(
            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
            maxLength: 50,
            autofocus: VentaTabState.tabs[0].productoSelected == null ? true : false,
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: widget.normalBorder ? bordeNormal : borde,
                borderSide: BorderSide(color: AppTheme.letraClara),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: widget.normalBorder ? bordeNormal : borde,
                borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
              ),
              isDense: true,
              prefixIcon: Icon(widget.icono, size: 25, color: AppTheme.letra70),
              hintText: widget.hintText,
            ),
            onChanged: (value) {
              _updateFilteredOptions(value);
              if (value.isEmpty) {
                VentaTabState.tabs[0].productoSelected = null;
                widget.onItemSelected(null);
              } else {
                final exists = widget.items.any((item) => widget.displayStringForOption(item) == value);
                if (!exists) {
                  VentaTabState.tabs[0].productoSelected = null;
                  widget.onItemSelected(null);
                }
              }
            },
            onEditingComplete: () {
              _validateOrClear();
              FocusScope.of(context).nextFocus();
            },
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Transform.translate(
          offset: Offset(30, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                width: 600,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final Productos option = options.elementAt(index);
                    final isHighlighted = index == _highlightedIndex;
                    final secondary = widget.secondaryDisplayStringForOption != null
                        ? widget.secondaryDisplayStringForOption!(option).trim()
                        : '';
                    final displayText = secondary.isEmpty
                        ? widget.displayStringForOption(option)
                        : "$secondary - ${widget.displayStringForOption(option)}";
    
                    return Container(
                      color: isHighlighted ? AppTheme.tablaColor1 : AppTheme.tablaColorFondo,
                      child: ListTile(
                        title: Text(
                          displayText,
                          style: AppTheme.subtituloPrimario,
                          textScaler: TextScaler.linear(0.9),
                        ),
                        onTap: () {
                          _controller.text = widget.displayStringForOption(option);
                          onSelected(option);
                          VentaTabState.tabs[0].productoSelected = option;
                          widget.onItemSelected(option);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}*/