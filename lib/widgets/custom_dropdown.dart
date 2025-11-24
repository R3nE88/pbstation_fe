import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CustomDropDown<T> extends StatelessWidget {
  const CustomDropDown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintText,
    this.isReadOnly = false,
    this.expanded = false,
    this.empty = false,
    this.height,
    this.maxLines = 2,
    this.useIsExpanded = true, // Nuevo parámetro para controlar isExpanded
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final bool isReadOnly;
  final bool expanded;
  final bool empty;
  final double? height;
  final int maxLines;
  final bool useIsExpanded; // Controla si usar isExpanded en el DropdownButton

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          width: expanded ? double.infinity : null,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.filledColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: empty
                  ? const Color.fromARGB(255, 228, 15, 0)
                  : AppTheme.letraClara,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: IgnorePointer(
              ignoring: isReadOnly,
              child: DropdownButton<T>(
                value: value,
                isExpanded: useIsExpanded && expanded, // Solo usar isExpanded si ambos son true
                hint: Text(hintText, style: AppTheme.labelStyle),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.letraClara,
                  size: 25,
                ),
                style: AppTheme.subtituloPrimario,
                dropdownColor: AppTheme.containerColor1,
                onChanged: isReadOnly ? (w) {} : onChanged,
                // Envuelve el texto del item seleccionado solo si useIsExpanded es true
                selectedItemBuilder: useIsExpanded
                    ? (BuildContext context) {
                        return items.map<Widget>((DropdownMenuItem<T> item) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.child is Text
                                  ? (item.child as Text).data ?? ''
                                  : '',
                              style: AppTheme.subtituloPrimario,
                              maxLines: maxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      }
                    : null,
                items: useIsExpanded
                    ? items.map((item) {
                        return DropdownMenuItem<T>(
                          value: item.value,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: item.child is Text
                                ? Text(
                                    (item.child as Text).data ?? '',
                                    style: AppTheme.subtituloPrimario,
                                    maxLines: maxLines,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : item.child,
                          ),
                        );
                      }).toList()
                    : items,
              ),
            ),
          ),
        ),
        empty
            ? Text('    Obligatorio', style: AppTheme.errorStyle)
            : const SizedBox(),
      ],
    );
  }
}