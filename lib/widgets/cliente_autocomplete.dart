import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class ClienteAutocompleteField extends StatefulWidget {
  final List<Clientes> clientes;
  final Clientes? clienteInicial;
  final Function(Clientes?) onClienteSelected;

  const ClienteAutocompleteField({
    super.key,
    required this.clientes,
    this.clienteInicial,
    required this.onClienteSelected,
  });

  @override
  State<ClienteAutocompleteField> createState() => _ClienteAutocompleteFieldState();
} 

class _ClienteAutocompleteFieldState extends State<ClienteAutocompleteField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<Clientes> _filteredOptions = [];
  int _highlightedIndex = 0;
  Clientes? _clienteSelected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.clienteInicial?.nombre ?? '');
    _focusNode = FocusNode();
    _clienteSelected = widget.clienteInicial;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_clienteSelected==null) {
          _controller.clear();
          _clienteSelected = null;
          widget.onClienteSelected(null);
        } else {
          _controller.text = _clienteSelected!.nombre;
          widget.onClienteSelected(_clienteSelected);
        }

      }
    });
  }

  void _validateOrClear() {
    final match = widget.clientes.firstWhere(
      (c) => c.nombre == _controller.text,
      orElse: () => Clientes(nombre: ''),
    );

    if (match.id == '') {
      _controller.clear();
      _clienteSelected = null;
      widget.onClienteSelected(null);
    } else {
      _clienteSelected = match;
      widget.onClienteSelected(match);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateFilteredOptions(String value) {
    _filteredOptions = widget.clientes.where(
      (c) => c.nombre.toLowerCase().contains(value.toLowerCase()),
    ).toList();
    _highlightedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {

            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_filteredOptions.isNotEmpty) {
                setState(() {
                  _highlightedIndex = (_highlightedIndex + 1) % _filteredOptions.length;
                });
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_filteredOptions.isNotEmpty) {
                setState(() {
                  _highlightedIndex =
                      (_highlightedIndex - 1 + _filteredOptions.length) % _filteredOptions.length;
                });
              }
            } else if (event.logicalKey == LogicalKeyboardKey.tab) {
              if (widget.clientes.isNotEmpty){
                if (_controller.text.isEmpty) {
                  setState(() {
                    final firstCliente = widget.clientes.first;
                    _controller.text = firstCliente.nombre;
                    _clienteSelected = firstCliente;
                    widget.onClienteSelected(firstCliente);
                  });
                } if (_filteredOptions.isNotEmpty) {
                  final selected = _filteredOptions[_highlightedIndex];
                  _controller.text = selected.nombre;
                  _clienteSelected = selected;
                  widget.onClienteSelected(selected);
                }else {
                  setState(() {
                    _controller.clear();
                    _filteredOptions.clear();
                    _clienteSelected = null;
                    widget.onClienteSelected(null);
                  });
                }
              }     
            }
        }
      },
      child: Autocomplete<Clientes>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Clientes>.empty();
          }
          _updateFilteredOptions(textEditingValue.text);
          return _filteredOptions;
        },
        displayStringForOption: (Clientes cliente) => cliente.nombre,
        onSelected: (Clientes selected) {
          _controller.text = selected.nombre;
          _clienteSelected = selected;
          widget.onClienteSelected(selected);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          _controller = controller;
          return Focus(
            onKey: (FocusNode node, RawKeyEvent event) {
              if (event is RawKeyDownEvent) {
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
                } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                  // Ignorar la tecla Enter
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextFormField(
              autofocus: true,
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  borderSide: BorderSide(color: AppTheme.letraClara),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
                ),
                isDense: true,
                prefixIcon: Icon(Icons.perm_contact_cal_sharp, size: 25, color: AppTheme.letra70),
                hintText: 'Buscar cliente',
              ),
              onChanged: (value) {
                _updateFilteredOptions(value);
                if (value.isEmpty) {
                  _clienteSelected = null;
                  widget.onClienteSelected(null);
                } else {
                  final exists = widget.clientes.any((c) => c.nombre == value);
                  if (!exists) {
                    _clienteSelected = null;
                    widget.onClienteSelected(null);
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
                  width: 600, // Cambia el ancho aquí
                  //height: 200, // Cambia la altura aquí
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final Clientes option = options.elementAt(index);
                      final isHighlighted = index == _highlightedIndex;
                      return Container(
                        color: isHighlighted ? AppTheme.tablaColor1 : AppTheme.tablaColorFondo,
                        child: ListTile(
                          title: Text(option.nombre, style: AppTheme.subtituloPrimario, textScaler: TextScaler.linear(0.9)),
                          onTap: () {
                            _controller.text = option.nombre;
                            onSelected(option);
                            _clienteSelected = option;
                            widget.onClienteSelected(option);
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
    );
  }
}
