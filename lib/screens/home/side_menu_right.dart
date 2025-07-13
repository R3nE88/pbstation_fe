import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class SideMenuRight extends StatelessWidget {
  final double height;
  const SideMenuRight({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final modProv = context.watch<ModulosProvider>();
    final subModulos = modProv.subModulosActuales;
    final hasSub = subModulos.length > 1;  

    return HoverSideMenu(
      side: MenuSide.right,
      height: height,
      enabled: hasSub,
      collapsedWidth: hasSub ? 66 : 15,
      menuContentColapsed: hasSub
          ? Column(
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: subModulos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      IconData iconData = Modulos.modulosIconos[modProv.moduloSeleccionado]?[idx + 1] ?? Icons.folder;
                      final selected = modProv.subModuloSeleccionado == idx;

                      Color seleccionado = AppTheme.primario1;
                      Color colorBase = AppTheme.letra70;

                      if (Modulos.deshabilitar(entry.value)){
                        //seleccionado = Colors.white24;
                        colorBase = Colors.white24;
                        iconData = Icons.lock;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 22, left: 13),
                        child: GestureDetector(
                          onTap: () => modProv.seleccionarSubModulo(idx),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.letraClara : Colors.transparent,
                              border: Border.all(color: colorBase),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              iconData,
                              size: 23,
                              color: selected ? seleccionado : colorBase
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          )
          : null,
      menuContent: hasSub
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                ...subModulos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final iconData = Modulos.modulosIconos[modProv.moduloSeleccionado]?[idx + 1] ?? Icons.folder;
                  final selected = modProv.subModuloSeleccionado == idx;
                  return _navItem(
                    icon: iconData,
                    label: label,
                    selected: selected,
                    onTap: () {
                      if (Modulos.deshabilitar(label)){
                        return;
                      }
                      modProv.seleccionarSubModulo(idx);
                    } 
                  );
                }),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    bool inhabilitado = false;
    if (Modulos.deshabilitar(label)){
      inhabilitado = true;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: MouseRegion(
        cursor: !inhabilitado ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onTap,
          child: CustomNavigationButton(
            icon: icon,
            label: label[0].toUpperCase() + label.substring(1),
            selected: selected, 
            first: false,
            inhabilitado : inhabilitado,
          ),
        ),
      ),
    );
  }
}
