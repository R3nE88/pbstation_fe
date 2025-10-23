import 'package:flutter/material.dart';
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
    final subModulos = modProv.subModulosVisibles; // Ya es List<SubModulo>
    final hasSub = subModulos.length > 1;

    return HoverSideMenu(
      height: height,
      enabled: hasSub,
      collapsedWidth: hasSub ? 66 : 15,
      
      // VERSIÓN COLAPSADA (solo íconos)
      menuContentColapsed: hasSub
          ? Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: subModulos.asMap().entries.map((entry) {
                        final subModulo = entry.value;
                        
                        // NUEVO: Verificar si está bloqueado
                        final bloqueado = modProv.estaBloqueado(subModulo);
                        
                        // NUEVO: Obtener índice real en subModulosActuales
                        final subModulosAccesibles = modProv.subModulosActuales;
                        final indiceAccesible = subModulosAccesibles.indexOf(subModulo);
                        final selected = indiceAccesible != -1 && 
                                        modProv.subModuloSeleccionado == indiceAccesible;

                        return Padding(
                          padding: const EdgeInsets.only(top: 22, left: 13),
                          child: GestureDetector(
                            onTap: bloqueado ? null : () => modProv.seleccionarSubModulo(indiceAccesible),  // ← CAMBIO
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.letraClara : Colors.transparent,
                                border: Border.all(
                                  color: bloqueado ? Colors.white24 : AppTheme.letra70  // ← NUEVO
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                bloqueado ? Icons.lock : subModulo.icono,  // ← CAMBIO
                                size: 23,
                                color: bloqueado 
                                    ? Colors.white24 
                                    : (selected ? AppTheme.primario1 : AppTheme.letra70),  // ← CAMBIO
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
      
      // VERSIÓN EXPANDIDA (con texto)
      menuContent: hasSub
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                ...subModulos.asMap().entries.map((entry) {
                  final subModulo = entry.value;
                  
                  // NUEVO
                  final bloqueado = modProv.estaBloqueado(subModulo);
                  final subModulosAccesibles = modProv.subModulosActuales;
                  final indiceAccesible = subModulosAccesibles.indexOf(subModulo);
                  final selected = indiceAccesible != -1 && 
                                  modProv.subModuloSeleccionado == indiceAccesible;
                  
                  return _navItem(
                    icon: bloqueado ? Icons.lock : subModulo.icono,  // ← CAMBIO
                    label: subModulo.nombre,
                    selected: selected,
                    onTap: () {
                      if (!bloqueado && indiceAccesible != -1) {  // ← CAMBIO
                        modProv.seleccionarSubModulo(indiceAccesible);
                      }
                    },
                    inhabilitado: bloqueado,  // ← CAMBIO
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
    required bool inhabilitado,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: MouseRegion(
        cursor: !inhabilitado 
            ? SystemMouseCursors.click 
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: inhabilitado ? null : onTap,
          child: CustomNavigationButton(
            icon: icon,
            label: label[0].toUpperCase() + label.substring(1),
            selected: selected,
            first: false,
            inhabilitado: inhabilitado,
          ),
        ),
      ),
    );
  }
}