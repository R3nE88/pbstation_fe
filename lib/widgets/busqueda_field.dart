import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class BusquedaField<T extends Object> extends StatefulWidget {
  const BusquedaField({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemUnselected,
    required this.onItemSelected,
    required this.displayStringForOption,
    this.secondaryDisplayStringForOption, // Parámetro opcional
    required this.normalBorder,
    required this.icono,
    required this.defaultFirst, 
    required this.hintText, 
    this.teclaFocus,
    required this.error, 
    this.showSecondaryFirst = true,
  });

  final List<T> items;
  final Function(T?) onItemSelected;
  final Function() onItemUnselected;
  final T? selectedItem;
  final String Function(T) displayStringForOption;
  final String Function(T)? secondaryDisplayStringForOption; // Hacerlo opcional
  final bool normalBorder;
  final IconData icono;
  final bool defaultFirst;
  final String hintText;
  final LogicalKeyboardKey? teclaFocus;
  final bool error;
  final bool showSecondaryFirst;

  @override
  State<BusquedaField<T>> createState() => _BusquedaFieldState<T>();
}

class _BusquedaFieldState<T extends Object> extends State<BusquedaField<T>> {
  late final bool Function(KeyEvent event) _keyHandler;
  late TextEditingController _controller;
  FocusNode? _focusNode; // Cambiar a nullable para usar solo el proporcionado por fieldViewBuilder
  List<T> _filteredOptions = [];
  int _highlightedIndex = 0;
  T? _selectedItem;

  BorderRadius borde = const BorderRadius.only(
    topLeft: Radius.circular(30),
    bottomLeft: Radius.circular(30),
  );

  BorderRadius bordeNormal = const BorderRadius.all(
    Radius.circular(30),
  );

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    _controller = TextEditingController(
      text: _selectedItem != null ? widget.displayStringForOption(_selectedItem!) : '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _controller.text = _selectedItem != null ? widget.displayStringForOption(_selectedItem!) : '';
      });
    });
    
    if (widget.teclaFocus != null) {
      _keyHandler = (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == widget.teclaFocus) {
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
      orElse: () => widget.items.isNotEmpty ? widget.items.first :  throw Exception('No items available'));
    //widget.onItemSelected()
    _selectedItem = match;
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
    // Eliminar cualquier llamada a setState() dentro del build
    if (widget.selectedItem == null && _selectedItem != null && !widget.defaultFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedItem = null;
            _controller.clear();
          });
        }
      });
    }


    if (widget.selectedItem != null && _selectedItem == null){
      _selectedItem = widget.selectedItem;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.displayStringForOption(_selectedItem!);
      });
    }


    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const DoNothingIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DoNothingIntent: CallbackAction<DoNothingIntent>(
            onInvoke: (intent) => null,
          ),
        },
        child: Autocomplete<T>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return Iterable<T>.empty();
            }
            _updateFilteredOptions(textEditingValue.text);
            return _filteredOptions;
          },
          displayStringForOption: (T option) {
            final secondary = widget.secondaryDisplayStringForOption != null
                ? widget.secondaryDisplayStringForOption!(option).trim()
                : '';
            if (secondary.isEmpty) {
              return widget.displayStringForOption(option);
            }
            return '$secondary - ${widget.displayStringForOption(option)}';
          },
          onSelected: (T selected) {
            _controller.text = widget.displayStringForOption(selected);
            _selectedItem = selected;
            widget.onItemSelected(selected);
            FocusScope.of(context).nextFocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _controller = controller;
            _focusNode = focusNode; // Usar el FocusNode proporcionado
            return Focus(
              canRequestFocus: false,
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
                            _selectedItem = firstItem;
                            widget.onItemSelected(firstItem);
                          });
                        }
                      } else if (_filteredOptions.isNotEmpty) {
                        final selected = _filteredOptions[_highlightedIndex];
                        _controller.text = widget.displayStringForOption(selected);
                        _selectedItem = selected;
                        widget.onItemSelected(selected);
                      } else {
                        setState(() {
                          _controller.clear();
                          _filteredOptions.clear();
                          _selectedItem = null;
                          widget.onItemSelected(null);
                        });
                      }
                    }
                    FocusScope.of(context).nextFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  if (_selectedItem == null) {
                    setState(() {
                      _controller.clear();
                      _filteredOptions.clear();
                      _selectedItem = null;
                      widget.onItemSelected(null);
                      widget.onItemUnselected();
                    });
                  }
                }
              },
              child: TextFormField(
                buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                maxLength: 50,
                autofocus: _selectedItem == null ? true : false,
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: widget.normalBorder ? bordeNormal : borde,
                    borderSide: BorderSide(color: !widget.error ? AppTheme.letraClara : Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: widget.normalBorder ? bordeNormal : borde,
                    borderSide: BorderSide(color: !widget.error ? AppTheme.letraClara : Colors.red, width: 3),
                  ),
                  isDense: true,
                  prefixIcon: Icon(widget.icono, size: 25, color: AppTheme.letra70),
                  hintText: widget.hintText,
                ),
                onChanged: (value) {
                  _updateFilteredOptions(value);
                  if (value.isEmpty) {
                    _selectedItem = null;
                    widget.onItemSelected(null);
                  } else {
                    final exists = widget.items.any((item) => widget.displayStringForOption(item) == value);
                    if (!exists) {
                      _selectedItem = null;
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
              offset: const Offset(30, 0),
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
                        final T option = options.elementAt(index);
                        final isHighlighted = index == _highlightedIndex;
                        final secondary = widget.secondaryDisplayStringForOption != null
                            ? widget.secondaryDisplayStringForOption!(option).trim()
                            : '';
                        final displayText = secondary.isEmpty
                            ? widget.displayStringForOption(option)
                            : widget.showSecondaryFirst? 
                            '$secondary - ${widget.displayStringForOption(option)}'
                            :
                            '${widget.displayStringForOption(option)} - $secondary';
        
                        return Container(
                          color: isHighlighted ? AppTheme.secundario1 : AppTheme.primario1,
                          child: ListTile(
                            title: Text(
                              displayText,
                              style: AppTheme.subtituloPrimario,
                              textScaler: const TextScaler.linear(0.9),
                            ),
                            onTap: () {
                              _controller.text = widget.displayStringForOption(option);
                              onSelected(option);
                              _selectedItem = option;
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
        ),
      ),
    );
  }
}