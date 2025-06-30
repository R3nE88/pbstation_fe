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
    this.empty = false
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final bool isReadOnly; // Nueva propiedad para habilitar/deshabilitar el widget
  final bool expanded;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          width: expanded ? double.infinity : null,
          decoration: BoxDecoration(
            color: AppTheme.filledColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: empty ? const Color.fromARGB(255, 228, 15, 0) : AppTheme.letraClara),
          ),
          child: DropdownButtonHideUnderline(
            child: IgnorePointer(
              ignoring: isReadOnly, // Ignorar interacción si es solo lectura
              child: DropdownButton<T>(
                value: value,
                hint: Text(hintText, style: AppTheme.labelStyle),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.letraClara, size: 25),
                style: AppTheme.subtituloPrimario,
                dropdownColor: AppTheme.containerColor1,
                onChanged: isReadOnly ? (w){} : onChanged, // Deshabilitar interacción si es solo lectura
                items: items,
              ),
            ),
          ),
        ),
        empty ? Text('    Obligatorio' , style: AppTheme.errorStyle) : const SizedBox()
      ],
    );
  }
}