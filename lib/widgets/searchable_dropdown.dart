import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class SearchableDropdown extends StatefulWidget {
  final Map<String, String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String hint;
  final FocusNode? focusNode;
  final bool isReadOnly;
  final bool empty;
  final bool showMoreInfo;
  final bool searchMoreInfo;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint = 'Selecciona una opción',
    this.focusNode, 
    this.isReadOnly = false,
    this.empty = false, 
    this.showMoreInfo = false,
    this.searchMoreInfo = true,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<MapEntry<String, String>> _filteredItems = [];
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items.entries.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _selectedIndex = -1;
  }

  void _showOverlay() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _selectItem(String key, {bool moveToNext = false}) {
    widget.onChanged?.call(key);
    _removeOverlay();
    _searchController.clear();
    _filteredItems = widget.items.entries.toList();
    
    if (moveToNext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).nextFocus();
        }
      });
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0 || index >= _filteredItems.length) {
      return;
    }

    const itemHeight = 48.0; // Altura ajustada según el padding de tus items
    final offset = index * itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Calcular si el item está fuera del viewport visible
    if (offset < currentOffset) {
      // Item está arriba, scroll hacia arriba
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } else if (offset + itemHeight > currentOffset + viewportHeight) {
      // Item está abajo, scroll hacia abajo
      // Agregar un pequeño margen para asegurar que se vea completo
      final targetOffset = (offset - viewportHeight + itemHeight + 8.0).clamp(0.0, maxScroll);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_selectedIndex < _filteredItems.length - 1) {
        setState(() => _selectedIndex++);
        _overlayEntry?.markNeedsBuild();
        // Ejecutar scroll después del rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(_selectedIndex);
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_selectedIndex > 0) {
        setState(() => _selectedIndex--);
        _overlayEntry?.markNeedsBuild();
        // Ejecutar scroll después del rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(_selectedIndex);
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _filteredItems.length) {
        _selectItem(_filteredItems[_selectedIndex].key, moveToNext: true);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.tab) {
      _removeOverlay();
      _searchController.clear();
      _filteredItems = widget.items.entries.toList();
    }
  }

  void _filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredItems = widget.items.entries
          .where((item) =>
              item.key.toLowerCase().contains(lowerQuery) ||
              item.value.toLowerCase().contains(lowerQuery))
          .toList();
      _selectedIndex = _filteredItems.isNotEmpty ? 0 : -1;
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
          _searchController.clear();
          _filteredItems = widget.items.entries.toList();
        },
        child: Stack(
          children: [
            Positioned.fill(child: Container()),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: AppTheme.tablaColorHeaderSelected,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: KeyboardListener(
                              focusNode: _keyboardFocusNode,
                              onKeyEvent: _handleKeyEvent,
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'Buscar...',
                                  prefixIcon: const Icon(Icons.search, color: AppTheme.letraClara),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: _filterItems,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Flexible(
                            child: _filteredItems.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No se encontraron resultados'),
                                  )
                                : ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      shrinkWrap: true,
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        return _DropdownItem(
                                          item: _filteredItems[index],
                                          index: index,
                                          isSelected: index == _selectedIndex,
                                          onTap: () => _selectItem(_filteredItems[index].key),
                                          onHover: () {
                                            setState(() => _selectedIndex = index);
                                            _overlayEntry?.markNeedsBuild();
                                          }, 
                                          searchMoreInfo: widget.searchMoreInfo,
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.value != null ? widget.items[widget.value] : null;

    return IgnorePointer(
      ignoring: widget.isReadOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                if (_overlayEntry == null) {
                  _showOverlay();
                  _searchFocusNode.requestFocus();
                } else {
                  _removeOverlay();
                  _searchController.clear();
                  _filteredItems = widget.items.entries.toList();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: selectedItem != null ? 7 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.filledColor,
                  border: Border.all(color: widget.empty ? const Color.fromARGB(255, 228, 15, 0) : AppTheme.letraClara),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: selectedItem != null
                          ? _SelectedItemDisplay(
                              key: ValueKey(widget.value),
                              clave: widget.value!,
                              descripcion: selectedItem, 
                              showMoreInfo: widget.showMoreInfo,
                            )
                          : Text(
                              widget.hint,
                              style: AppTheme.labelStyle,
                            ),
                    ),
                    Icon(
                      _overlayEntry != null ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: AppTheme.letraClara,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.empty)
            Text('    Obligatorio', style: AppTheme.errorStyle)
        ],
      ),
    );
  }
}

// Widget separado para optimizar rebuilds
class _SelectedItemDisplay extends StatelessWidget {
  final String clave;
  final String descripcion;
  final bool showMoreInfo;

  const _SelectedItemDisplay({
    super.key,
    required this.clave,
    required this.descripcion, 
    required this.showMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMoreInfo)
          Text(
            clave,
            style: AppTheme.labelStyle,
            textScaler: const TextScaler.linear(0.72),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: showMoreInfo ? 0 : 6),
          child: Text(
            descripcion,
            style: AppTheme.subtituloPrimario,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.linear(showMoreInfo ? 1 : 1.1),
          ),
        ),
      ],
    );
  }
}

// Widget separado para items del dropdown
class _DropdownItem extends StatelessWidget {
  final MapEntry<String, String> item;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;
  final bool searchMoreInfo;

  const _DropdownItem({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onHover, 
    required this.searchMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    return InkWell(
      onTap: onTap,
      onHover: (hovering) {
        if (hovering) onHover();
      },
      child: Container(
        color: isSelected
            ? AppTheme.letraClara.withAlpha(AppTheme.isDarkTheme ? 25 : 75)
            : (isEven ? AppTheme.tablaColor1 : AppTheme.tablaColor2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchMoreInfo)
              Text(
                item.key,
                style: AppTheme.tituloClaro.copyWith(
                  color: AppTheme.colorContraste.withAlpha(175),
                  fontWeight: FontWeight.normal,
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: searchMoreInfo ? 0 : 5),
              child: Text(
                item.value,
                style: AppTheme.labelStyle.copyWith(
                  color: AppTheme.colorContraste,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}