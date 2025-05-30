
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class CustomDropDown<T> extends StatelessWidget {
  const CustomDropDown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintText,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.filledColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.letraClara),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hintText, style: AppTheme.subtituloPrimario),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.letraClara, size: 25),
          style: AppTheme.subtituloPrimario,
          dropdownColor: AppTheme.containerColor1,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}